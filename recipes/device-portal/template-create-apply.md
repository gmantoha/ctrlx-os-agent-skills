# Device Portal Template: Create, Inspect, Apply (public API only)

Verified 2026-09-09 on the QA environment, ctrlX OS 4.6.x, Setup/Solutions 4.6.2.
Read `reference/apps/device-portal/README.md` for the contract and the defect
list. Never use browser cookies; use the service client and subscription key.

## Environment

```bash
export DP_TOKEN_URL='https://<keycloak-host>/auth/realms/<realm>/protocol/openid-connect/token'
export DP_BASE='https://<device-portal-api-host>/iot-device-services/v1'
export DP_CLIENT_ID='<service-client-id>'
export DP_CLIENT_SECRET='<service-client-secret>'      # from a secret store, never from a tracked file
export DP_SUBSCRIPTION_KEY='<apim-subscription-key>'
export DP_ACCOUNT_ID='<account-id>'
export SOURCE_DEVICE_ID='<serial-number-of-golden-device>'
export TARGET_DEVICE_ID='<serial-number-of-target>'
```

Before step 1: fingerprint the target and create a recovery ZIP
(`recipes/device-portal/target-snapshot-and-recovery.md`).

## 1. Token

```bash
DP_TOKEN=$(curl -sS -X POST "$DP_TOKEN_URL" \
  -d grant_type=client_credentials \
  -d client_id="$DP_CLIENT_ID" -d client_secret="$DP_CLIENT_SECRET" \
  | python3 -c 'import sys,json; print(json.load(sys.stdin)["access_token"])')

dp() {  # dp METHOD PATH [curl args]
  curl -sS -X "$1" "$DP_BASE$2" \
    -H "Authorization: Bearer $DP_TOKEN" \
    -H "Ocp-Apim-Subscription-Key: $DP_SUBSCRIPTION_KEY" \
    -H "Accept: application/json" "${@:3}"
}
```

Reuse the token until `expires_in` (typically 5 min); request a new one only
then.

## 2. Check both devices

```bash
dp GET "/devices/$SOURCE_DEVICE_ID" | python3 -m json.tool   # status must be ONLINE
dp GET "/devices/$TARGET_DEVICE_ID" | python3 -m json.tool
```

Compare `typeCode` and `operatingSystemVersion`. Do not apply across hardware
types or OS generations.

## 3. Source setupinfo

```bash
dp GET "/devices/$SOURCE_DEVICE_ID/setup/setupinfo" > source-setupinfo.json
```

This is the copy the agent last reported. If the gateway answers 400 or 404, or
the device was offline recently, read it from the CORE instead
(`GET https://<core>/setup/api/v1/setupinfo` with a local Identity Manager
token). Treat the file as sensitive: it lists certificates, users, network
settings, and the serial number.

## 4. Build the selection (setupinfo dialect)

```python
# build_selection.py  <source-setupinfo.json> <kind> [app ...]  -> stdout
# kind: appdata   -> listed apps + whole active app data
#       apps      -> listed apps only, app data explicitly excluded
#       settings  -> only the listed top-level settings keys, no apps, no app data
import json, sys

base = json.load(open(sys.argv[1]))
kind, items = sys.argv[2], sys.argv[3:]

sel = {
    "$forceReboot": False, "$name": "", "$schema": "./setup.v1.schema.json", "$version": "",
    "apps": {},
    "systemInfo": base["systemInfo"],
    "typePlate": base["typePlate"],
}
apps = base["packageManagement"]["installedApps"]
if kind in ("appdata", "apps"):
    sel["packageManagement"] = {
        "allowUnknownApps": base["packageManagement"].get("allowUnknownApps", True),
        "installedApps": {n: (e if n in items else {"$content": "none"}) for n, e in apps.items()},
    }
    sel["configurations"] = {"active": {}} if kind == "appdata" else {"active": {"$content": "none"}}
elif kind == "settings":
    sel["packageManagement"] = {
        "allowUnknownApps": base["packageManagement"].get("allowUnknownApps", True),
        "installedApps": {n: {"$content": "none"} for n in apps},
    }
    sel["configurations"] = {"active": {"$content": "none"}}
    for key in items:              # e.g. connectivity dateTime
        sel[key] = base[key]
json.dump(sel, sys.stdout, indent=2)
```

```bash
python3 build_selection.py source-setupinfo.json appdata rexroth-plc ctrlx-node-red > selection.json
```

Rules:

- The selection is the full setupinfo with every unwanted app set to
  `{"$content": "none"}`. Never write `"$content": "items"` or `"files"`.
- `"configurations": {"active": {}}` selects the **complete** active app data
  (PLC, Node-RED, firewall, Data Layer, scheduler, and so on). There is no
  per-app selection.
- Leave `certificateManagement` out. Device identity certificates must not
  travel between devices.
- Settings-only templates carry only their settings keys. Do not mix them with
  `configurations.active`.

## 5. Create the template

```bash
python3 - <<'EOF' > create-body.json
import json
sel = json.load(open("selection.json"))
import os
print(json.dumps({
  "type": "DEVICE_TASK",
  "accountId": os.environ["DP_ACCOUNT_ID"],
  "action": "CREATE_DEVICE_TEMPLATE",
  "parameters": {
    "deviceId": os.environ["SOURCE_DEVICE_ID"],
    "name": "variant-A-appdata", "version": 1,
    "description": "PLC + Node-RED app data, golden device variant A",
    "setupInfo": json.dumps(sel, separators=(",", ":"))
  }}))
EOF
dp POST /tasks -H 'Content-Type: application/json' --data-binary @create-body.json > create-task.json
TASK_ID=$(python3 -c 'import json; print(json.load(open("create-task.json"))["id"])')
```

`setupInfo` is a JSON string inside the JSON body. Serialize once; do not paste
pre-escaped snippets.

## 6. Poll

```bash
poll() {  # poll TASK_ID [timeout-seconds]
  local t0=$SECONDS state
  while :; do
    state=$(dp GET "/tasks/$1" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("state"))')
    echo "[$((SECONDS-t0))s] $state"
    case "$state" in DONE|FAILED) return 0;; esac
    [ $((SECONDS-t0)) -ge "${2:-900}" ] && { echo "TIMEOUT"; return 1; }
    sleep 10
  done
}
poll "$TASK_ID" 900
TEMPLATE_ID=$(dp GET "/tasks/$TASK_ID" | python3 -c 'import sys,json; print(json.load(sys.stdin)["result"]["templateId"])')
```

Create tasks finished in 30 s to 2 min. A task that stays `RUNNING` beyond the
timeout must be treated as failed; there is no public cancel. Store
`TEMPLATE_ID` and `TASK_ID` in the commissioning software's own records.

## 7. Inspect the stored template

```bash
dp GET "/templates/$TEMPLATE_ID" > template.json
python3 - <<'EOF'
import json
t = json.load(open("template.json"))
cfg = json.loads(t.pop("configurations"))
json.dump(cfg, open("template-configurations.json", "w"), indent=2)
print({k: t[k] for k in ("id", "name", "version", "deviceTypeCode", "compatibleOs")})
apps = cfg.get("packageManagement", {}).get("installedApps", {})
print("apps with $path:", {k: v["$path"] for k, v in apps.items() if isinstance(v, dict) and "$path" in v})
print("configurations:", cfg.get("configurations"))
EOF
```

Expected for an app-data template: every wanted app has
`"$path": "packageManagement/installedApps/<app>-<version>.app"`, and
`configurations` prints as `{"active": {}}`. The empty object is the known
defect: the archive contains `configurations/active/**`, the reference was
dropped.

## 8. Apply

```bash
python3 - <<'EOF' > apply-body.json
import json, os
cfg = json.load(open("template-configurations.json"))
KIND = os.environ.get("TEMPLATE_KIND", "appdata")      # appdata | apps | settings
if KIND == "appdata":
    cfg["configurations"] = {"active": {"$path": "configurations/active"}}   # re-insert the lost reference
elif KIND == "apps":
    cfg.pop("configurations", None)
elif KIND == "settings":
    keep = os.environ["SETTINGS_KEYS"].split()          # e.g. "connectivity dateTime"
    cfg = {k: cfg[k] for k in keep}
print(json.dumps({
  "type": "DEVICE_TASK",
  "accountId": os.environ["DP_ACCOUNT_ID"],
  "action": "APPLY_DEVICE_TEMPLATE",
  "parameters": {
    "deviceId": os.environ["TARGET_DEVICE_ID"],
    "templateId": os.environ["TEMPLATE_ID"],
    "restoreOptions": "MERGE",
    "configurations": json.dumps(cfg, separators=(",", ":"))
  }}))
EOF
export TEMPLATE_ID
dp POST /tasks -H 'Content-Type: application/json' --data-binary @apply-body.json > apply-task.json
APPLY_ID=$(python3 -c 'import json; print(json.load(open("apply-task.json"))["id"])')
poll "$APPLY_ID" 1800
```

- `configurations` is mandatory. Without it: HTTP 400
  `The Configurations field is required.`
- Inject `configurations.active.$path` only for a template that is meant to
  carry app data. Injecting it into a settings-only apply loads the whole
  active configuration of that template.
- A settings-only apply sends just the selected settings keys.
- `MERGE` installs apps that are missing on the target (the device switches to
  SETUP and then SERVICE on its own).

## 9. Verify on the device, then restore the operating state

```bash
CORE='https://<core>'; CORE_TOKEN='<local identity manager token, reuse one>'
curl -sk "$CORE/setup/api/v1/tasks" -H "Authorization: Bearer $CORE_TOKEN" | python3 - <<'EOF'
import sys, json
tasks = [t for t in json.load(sys.stdin) if str(t.get("id", "")).startswith("apply_")]
t = tasks[-1]
print(t["id"], t["state"], t.get("progress"))
for e in t.get("protocol", []):
    if e["severity"] in ("INFO", "ERROR") or (e["severity"] == "WARNING" and "Json schema issue" not in e["message"]):
        print(f'{e["severity"]:7} {e["time"][11:19]} {e["message"]}')
EOF
```

Look for `Writing configurations - loading active configuration` (app data
applied) versus `Writing configurations (skipped, no changes)` (nothing
applied). Expect `Writing connectivity` and the two `certificateManagement`
delete errors on cross-device restores.

If the protocol contains `Switching to SERVICE state`, switch back:

```bash
curl -sk -X PUT "$CORE/automation/api/v2/nodes/scheduler%2Fadmin%2Fstate" \
  -H "Authorization: Bearer $CORE_TOKEN" -H 'Content-Type: application/json' \
  -d '{"type":"object","value":{"state":"OPERATING"}}'
```

Then take the post-apply fingerprint and compare it with the pre-apply one.
Finish with `DELETE /identity-manager/api/v2/auth/token` on the CORE.

## Failure handling for commissioning software

- `FAILED`, timeout, or an unexpected protocol line: stop the sequence, keep
  the device out of production, and restore the recovery ZIP.
- Do not advance on the exit code of a helper script. Evaluate the task state
  and the device protocol.
- Persist template IDs per machine variant. The list endpoint requires
  `accountId` and paging; the name is not unique.
