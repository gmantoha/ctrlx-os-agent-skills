# Device Portal Templates and Serial Commissioning

Use this workflow when a commissioning tool, a demo, or a customer answer
involves creating or applying ctrlX CORE templates through the Device Portal
public API ("Mass Rollout Templates"), or when a modular or serial commissioning
of many ctrlX CORE devices has to be designed.

Read `reference/apps/device-portal/README.md` first. It holds the API contract,
the Setup selection model, and the dated defect list. Do not call any cloud or
device endpoint before you know which dialect and which envelope the current
service accepts.

Concrete playbooks:

- `recipes/device-portal/template-create-apply.md` — create, inspect, apply, poll
- `recipes/device-portal/target-snapshot-and-recovery.md` — fingerprint the
  target, recovery ZIP, restore the operating state after an apply
- `recipes/device-portal/plc-bootproject-setup-zip.md` — PLC boot project as a
  direct Setup ZIP module (the modular alternative to templates)
- `cases/reusable/device-portal-template-granularity/CASE.md` — sanitized
  evidence for the "app data is all-or-nothing" finding

## What is verified (state 2026-09-09, QA environment)

Tested with API credentials only on a ctrlX CORE X3 with ctrlX OS 4.6.x
(Ubuntu Core 24, Setup/Solutions/PLC 4.6.2, Device Portal Agent 3.6.x).

Works:

- `CREATE_DEVICE_TEMPLATE` from an online device with the full setupinfo
  dialect, including active app data (`configurations.active`).
- `APPLY_DEVICE_TEMPLATE` with `restoreOptions: "MERGE"`. Apps missing on the
  target are installed by the Setup app itself, including the SETUP → SERVICE
  mode switch, without warnings.
- Settings-only templates (for example network interface DNS, date/time) stack
  additively in any order. They leave every active-data file hash and the PLC
  cycle counter untouched. Reapplying such a layer is idempotent.
- `GET /templates?accountId=…` (template list) and
  `GET /devices/{id}/setup/setupinfo` (cloud copy of the device setupinfo)
  work on QA. Earlier findings that they return 404/400 are outdated.

Does not work or is limited:

- **App data is all-or-nothing.** Any apply whose payload contains
  `configurations.active` loads the complete active configuration on the
  target: Node-RED flows are deleted, marker files in `node-RED/`, `datalayer/`
  and `firewall/` are removed, every app directory contained in the archive
  replaces the target directory, and the PLC cycle counter resets. This also
  holds for a "PLC-only" template created on a device that never had Node-RED
  installed. The support recipe "full template A, then PLC-only template B with
  MERGE only overwrites PLC data" was tested on 2026-09-09 and is **not true**.
- The stored template loses `configurations.active.$path`. A plain apply then
  reports `DONE` but the Setup app logs `Writing configurations (skipped, no
  changes)` and no app data is restored. The reference must be injected at
  apply time.
- Every `{"$content": "none"}` app entry produces schema warnings on the
  device (about 45 per apply). The restore still succeeds.
- An apply that installs an app leaves the device in SERVICE state. It does not
  switch back to OPERATING.
- Uninstalling an app (tested with Node-RED) does not remove its directory from
  the active configuration. Later templates still pack it.
- The WebUI "Save as template" dialog cannot include app data at all. Its "PLC"
  checkbox transports the PLC app package, never the boot project.
- The `$content` selector dialect of the Setup app is executed by the device
  but the cloud task never leaves `RUNNING`. There is no public cancel.

## Decision matrix

| Requirement | Approach |
|---|---|
| One machine variant as a unit: apps plus all app data (PLC, Node-RED, firewall, Data Layer, scheduler) | Device Portal template with `configurations.active`, `$path` injected on apply, MERGE. Golden device per variant. |
| Device settings modules: network, hostname, date/time, users, SSH, proxy, hosts, storage, licenses, app-management settings | One settings-only template per module, MERGE, any order. Send only the selected settings keys on apply. |
| Install or update apps without touching app data | Template with the app entries and `configurations.active: {"$content":"none"}`; apply without a `configurations.active` key. Expected from the observed skip behavior, not separately verified. |
| "Only the PLC boot project, nothing else touched" | Not achievable with templates. Use a direct CORE Setup ZIP with `mode=merge` (see the PLC recipe) and verify undeclared apps afterwards. |
| Additive stacking of several app-data modules | Not supported by the platform. Combine the modules on the golden device and ship one app-data template. |

Firewall rules, Node-RED flows, PLC boot project, Data Layer and scheduler
settings are **app data** (`configurations/active/<app>/`). They are not
selectable per app. Everything listed as "settings" above is a Setup category
with `items` content and is selectable per key.

## Safety gate

Before any real-device mutation:

1. Identify source and target device IDs and confirm the target is disposable,
   a test device, or explicitly approved for the operation.
2. Fingerprint the target and create a Setup recovery ZIP
   (`recipes/device-portal/target-snapshot-and-recovery.md`). Download it.
3. Use `MERGE` for additive deployment. Use `OVERRIDE` only when replacing the
   whole configuration is intended.
4. Verify the result on the device, not only from the cloud task. `DONE` is
   returned even when app data was skipped.
5. For production tooling, fail closed on a missing or ambiguous verification,
   on `FAILED`, and on a timeout. A shell exit code of a helper script is not a
   verification.

Creating a template reads and uploads device data (including app data and
certificate metadata) to the cloud. Applying a template is a persistent device
change and requires confirmation under the general ctrlX safety policy.

## Authentication: API credentials only

Do not use browser session cookies for an automated workflow. The WebUI talks to
a cookie-authenticated backend-for-frontend under `/api/v2/*`; that surface does
not accept the service-account bearer token and is not part of the public API.

1. Request a short-lived Keycloak access token with `grant_type=client_credentials`.
2. Send `Authorization: Bearer <token>` and `Ocp-Apim-Subscription-Key: <key>` on
   every Device Portal call.
3. Cache and reuse the token until shortly before `expires_in`.
4. Never log client secrets, subscription keys, passwords, or full bearer tokens.
5. For the local CORE, request one Identity Manager token and reuse it, then
   call `DELETE /identity-manager/api/v2/auth/token` when finished. The Identity
   Manager enforces `maxSessionsPerUser` (100) with an 8 h session timeout and
   no inactivity timeout. One token per REST call exhausts the limit and every
   login then fails with `{"status":400,"dynamicDescription":"Too many sessions"}`
   for up to 8 hours. Only restarting `rexroth-deviceadmin.web` cleared it.
6. Keep credentials out of tracked files, task payload logs, screenshots,
   browser storage, and support attachments.

Use placeholders in examples:

```text
DP_TOKEN_URL=https://<keycloak-host>/auth/realms/<realm>/protocol/openid-connect/token
DP_BASE=https://<device-portal-api-host>/iot-device-services/v1
DP_CLIENT_ID=<service-client-id>
DP_CLIENT_SECRET=<service-client-secret>
DP_SUBSCRIPTION_KEY=<apim-subscription-key>
DP_ACCOUNT_ID=<account-id>
```

## Standard flow

1. Confirm prerequisites: Device Portal Agent app installed on source and
   target, both devices `ONLINE` in the account, premium API credentials
   available, same hardware type code and OS generation on source and target.
2. Prepare the golden (source) device completely: apps, licenses, PLC boot
   project loaded and running, Node-RED flows deployed, firewall and other app
   data as intended. Verify `Application.app` and `Application.crc` exist under
   `configurations/active/plc/run/<arch>/data/`. A backup of a device without an
   active PLC boot application contains neither file.
3. Fingerprint the target and create the recovery ZIP.
4. Read the source setupinfo (cloud endpoint, fallback CORE endpoint) and build
   the template selection in the setupinfo dialect. Decide per template whether
   it is an app-data template, a settings-only template, or an app-install
   template. Never mix a settings module with `configurations.active`.
5. Submit `CREATE_DEVICE_TEMPLATE`, poll to `DONE`, retrieve the template, and
   inspect `configurations`: which apps carry `$path`, and whether
   `configurations.active` is `{}`.
6. Build the apply payload from the stored configurations. Inject
   `configurations.active.$path` only for an app-data template. Submit
   `APPLY_DEVICE_TEMPLATE` with `MERGE`, poll to `DONE` or `FAILED`.
7. On the CORE, read the last Setup apply task protocol and check for
   `Writing configurations - loading active configuration`, warnings, and
   errors. Restore OPERATING state if the apply installed apps.
8. Compare the target fingerprint before and after. Check the intended change
   and every preservation invariant (unrelated app data hashes, package list,
   PLC project and cycling, DNS, timezone).
9. Run machine-specific fine tuning only after the template verification has
   passed and keep those scripts separate from the template module.
10. Report template ID, task IDs, final states, the Setup protocol lines, and
    the fingerprint comparison. Remove IDs and credentials before sharing.

## Payload rules that were learned the hard way

- Envelope: `{"type": "DEVICE_TASK", "accountId": "...", "action": ..., "parameters": {...}}`.
  The older `taskType` key is rejected since September 2026 with
  `The action must be APPLY_DEVICE_TEMPLATE or CREATE_DEVICE_TEMPLATE and type must be DEVICE_TASK`.
  The documented envelope includes `accountId`; requests without it were also
  accepted.
- `parameters.setupInfo` and `parameters.configurations` are JSON **strings**.
  Serialize the object once, then let the HTTP client serialize the outer body.
  Do not copy escaped snippets from the PDFs; several are truncated or malformed.
- `restoreOptions` is plural. The prose in the design document uses the
  singular; the singular is wrong in a payload.
- `parameters.configurations` is mandatory on apply in practice (HTTP 400
  `The Configurations field is required.`), even though the How-To marks it
  optional.
- `version` is documented as a number; the string `"1"` was also accepted.
- `schedule.start` (ISO timestamp) schedules the task; omit it to run now.
- Exclude apps on create with `{"$content": "none"}`. Include app data with
  `"configurations": {"active": {}}`. Never use `"$content": "items"` or
  `"$content": "files"` in a portal payload.
- A restore from another device always logs two `certificateManagement` errors
  about `device.crt` and `device.hsm` deletion. The design document treats the
  restore as successful in that case. Do not copy device identity material
  between devices on purpose; leave `certificateManagement` out of templates.

## Evidence to retain

For each production test, retain sanitized records of:

- source/target compatibility metadata (`deviceTypeCode`, `compatibleOs`, app
  versions) and timestamps;
- template ID, create/apply task IDs, and final states;
- hash or size checks for `Application.app` and `Application.crc`;
- pre/post app list, active-configuration file hashes, and
  `configuration.json` app list;
- CORE Setup task protocol and portal responses;
- the exact selection and apply payloads (with IDs replaced).

Remove tokens, passwords, private keys, account and device IDs, customer
names, internal IPs, and raw setup exports before adding evidence to this
skill or a shared case.
