# Target Fingerprint, Recovery ZIP, and Operating-State Restore

Use this before and after every template apply or Setup ZIP apply on a real
ctrlX CORE. A cloud task state of `DONE` proves nothing about the device.
Verified 2026-09-07 and 2026-09-09 on ctrlX OS 4.6.x (Setup/Solutions 4.6.2).

## One CORE token for the whole session

```bash
CORE='https://<core-ip-or-host>'
CORE_TOKEN=$(curl -sk -X POST "$CORE/identity-manager/api/v2/auth/token?force-local-auth=true" \
  -H 'Content-Type: application/json' \
  -d '{"name":"<user>","password":"<password>"}' \
  | python3 -c 'import sys,json; print(json.load(sys.stdin)["access_token"])')
core() { curl -sk -X "$1" "$CORE$2" -H "Authorization: Bearer $CORE_TOKEN" -H 'Accept: application/json' "${@:3}"; }
# at the end of the session:
# core DELETE /identity-manager/api/v2/auth/token
```

The Identity Manager allows 100 sessions per user with an 8 h lifetime and no
idle timeout. A token per call locks the user out for hours
(`"Too many sessions"`).

## Fingerprint (read-only)

```bash
OUT=snap-${1:-baseline}; mkdir -p "$OUT"        # run as a script: ./fingerprint.sh <label>
core GET /package-manager/api/v1/packages \
  | python3 -c 'import sys,json; print("\n".join(sorted(p["name"]+" "+p["release"]["version"] for p in json.load(sys.stdin))))' > "$OUT/packages.txt"
core GET /setup/api/v1/setupinfo > "$OUT/setupinfo.json"
core GET /solutions/api/v1/solutions/DefaultSolution/configurations > "$OUT/solutions-configs.json"
core GET /automation/api/v2/nodes/plc/app/Application/admin/properties > "$OUT/plc-properties.json"
c1=$(core GET /automation/api/v2/nodes/plc/app/Application/admin/task/MainTask/cycle-count | python3 -c 'import sys,json; print(json.load(sys.stdin)["value"])'); sleep 2
c2=$(core GET /automation/api/v2/nodes/plc/app/Application/admin/task/MainTask/cycle-count | python3 -c 'import sys,json; print(json.load(sys.stdin)["value"])')
echo "cycle1=$c1 cycle2=$c2" > "$OUT/plc-cycles.txt"          # c2 > c1 means the PLC runs
core GET /automation/api/v2/nodes/scheduler%2Fadmin%2Fstate > "$OUT/scheduler-state.json"   # OPERATING / SERVICE / SETUP
core GET /system/api/v1/time/settings > "$OUT/time.json"
core GET /network-manager/api/v1/interfaces > "$OUT/net.json"
core GET /node-red/flows -o "$OUT/node-red-flows.json" -w '%{http_code}' > "$OUT/node-red-http.txt"
date -Is > "$OUT/timestamp.txt"
```

With SSH access (optional, most precise):

```bash
ACT=/var/snap/rexroth-solutions/common/solutions/activeConfiguration
sudo find -L $ACT -type f -exec sha256sum {} + | sed "s#$ACT/##" | sort -k2 > active-sha256.txt
sudo cat $ACT/configuration.json | python3 -c 'import sys,json; print([a["name"] for a in json.load(sys.stdin)["apps"]])'
snap list
```

Compare two fingerprints by set difference of `active-sha256.txt` (changed,
added, removed), `packages.txt`, the app list of `configuration.json`, the PLC
project name, cycle counters, timezone, and DNS servers.

### Marker files (disposable devices only)

To prove whether an apply touches unrelated app data, write a marker with a
device-specific value into writable app directories before the apply, for
example `node-RED/marker.txt`, `datalayer/marker.txt`, `firewall/marker.txt`
(SSH). The PLC directory is write-protected (WebDAV returns 403). Identical
source and target data hide a destructive whole-tree restore; use distinct
values on source and target. Remove the markers afterwards.

## Recovery ZIP (settings plus active app data, no packages, no certificates)

```bash
core POST /setup/api/v1/create -H 'Content-Type: application/json' -D headers.txt -d '{
  "$content": "files", "$format": "zip",
  "packageManagement": {"installedApps": {"$content": "none"}},
  "certificateManagement": {"$content": "none"}
}'
LOC=$(grep -i '^Location:' headers.txt | tr -d '\r' | awk '{print $2}')        # /tasks/create_xxxxxx
until core GET "/setup/api/v1$LOC" | grep -q '"state": *"\(done\|failed\)"'; do sleep 5; done
FILE=$(core GET "/setup/api/v1$LOC" | python3 -c 'import sys,json; print(json.load(sys.stdin)["fileName"])')
core GET "/setup/api/v1/setups/$FILE" -H 'Accept: */*' -o recovery.zip
python3 -c 'import zipfile,sys; z=zipfile.ZipFile("recovery.zip"); n=z.namelist(); print(len(n), "entries"); print([x for x in n if x.endswith(("Application.app","Application.crc"))]); print([x for x in n if "/node-RED/" in x][:5])'
```

The archive holds `ctrlx-setup.json` with
`"configurations": {"active": {"$path": "configurations/active"}}` and the
files. Keep it outside git; it contains users, network settings, and app data.
It is an active-data/settings backup, not an OS image: removed or upgraded
packages are not reverted by it.

## Restore

```bash
core POST /setup/api/v1/apply -H 'Accept: */*' -D headers.txt \
  -F 'setup=@recovery.zip;type=application/zip' -F 'mode=merge'
LOC=$(grep -i '^Location:' headers.txt | tr -d '\r' | awk '{print $2}')        # /tasks/apply_xxxxxx
until core GET "/setup/api/v1$LOC" | grep -q '"state": *"\(done\|failed\)"'; do sleep 5; done
core GET "/setup/api/v1$LOC" | python3 -c 'import sys,json; t=json.load(sys.stdin); print(t["state"], t.get("progress")); [print(e["severity"], e["message"]) for e in t["protocol"] if e["severity"] in ("INFO","WARNING","ERROR") and "Json schema" not in e["message"]]'
```

Observed after recovery: 54 of 56 active-data files byte-identical to the
baseline; `scheduler/autoconfig.json` differed only in generated callable IDs;
`plc_system.cfg` had already changed during backup creation and matched the
archive. Packages, settings, PLC project, and Node-RED state matched the
baseline. Do not describe a recovery as an exact byte-for-byte restoration of
the pre-backup live state.

## Operating state after an apply

A template apply that installs apps switches the device SETUP → SERVICE and
leaves it there while the PLC keeps cycling. Check and restore:

```bash
core GET /automation/api/v2/nodes/scheduler%2Fadmin%2Fstate          # {"value":{"state":"SERVICE"}}
core PUT /automation/api/v2/nodes/scheduler%2Fadmin%2Fstate -H 'Content-Type: application/json' \
  -d '{"type":"object","value":{"state":"OPERATING"}}'
```

Poll the node until it reports the requested state (a few seconds). Package
operations (`POST /package-manager/api/v1/tasks`, for example
`{"action":"uninstall","parameters":{"id":"snap_<app>"}}`) require SERVICE
state first; switch back afterwards.

## Cleanup

- Delete downloaded setups on the device when no longer needed:
  `DELETE /setup/api/v1/setups/<fileName>`.
- Uninstalling an app does not remove its directory from
  `configurations/active`. Remove it by hand if a later backup must not carry
  it; `configuration.json` is regenerated without the app.
- Log out: `DELETE /identity-manager/api/v2/auth/token`.
