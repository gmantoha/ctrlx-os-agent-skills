# Device Portal Templates and Serial Commissioning

Use this workflow when an external commissioning tool must create or apply a
ctrlX CORE template through the Device Portal public API. It covers both a
complete-device template and modular deployment decisions.

## Scope and stability

Separate the two API surfaces:

- **Device Portal cloud API:** Keycloak client credentials plus the APIM
  subscription key. Typical resources are `/devices/{id}`, `/tasks`, and
  `/templates/{id}`.
- **ctrlX CORE local API:** local Identity Manager token plus Setup API and
  other device REST APIs. The CORE is the source of `setupInfo` when the cloud
  setup-info endpoint is unavailable.

Use the current public OpenAPI/documentation first. If an endpoint is not in
the released API description, label it as observed/unsupported and do not
present it as a production guarantee.

## Safety gate

Before any real-device mutation:

1. Identify source and target device IDs and confirm the target is disposable,
   test, or explicitly approved for the operation.
2. Record a target snapshot: device status, installed apps, active solution,
   PLC project identity, and any application data whose preservation matters.
3. Use `MERGE` for additive deployment. Do not use `OVERRIDE` for modular
   commissioning unless replacement of the whole configuration is intended.
4. Verify the result at the device, not only from the cloud task response.
5. For production, make the commissioning tool fail closed on missing or
   ambiguous verification. A cloud `DONE` state alone is insufficient.

Creating a template reads and uploads device data but is still a cloud-side
operation. Applying a template is a persistent device change and requires
confirmation under the general ctrlX safety policy.

## Authentication: API credentials only

Do not use browser session cookies for an automated commissioning workflow.

1. Request a short-lived Keycloak access token using `grant_type=client_credentials`.
2. Send the bearer token and APIM subscription key on every Device Portal call.
3. Cache and reuse the token until shortly before expiry.
4. Never log client secrets, subscription keys, passwords, or full bearer tokens.
5. For the local CORE, request one local token and reuse it. The Identity Manager
   has a finite per-user session limit; requesting one token per REST call can
   exhaust the limit for hours.
6. Do not store credentials in tracked files, task payload logs, screenshots,
   browser local storage shared with other users, or support attachments.

Use placeholders in examples:

```text
DP_TOKEN_URL=https://<keycloak-host>/auth/realms/<realm>/protocol/openid-connect/token
DP_BASE=https://<device-portal-api-host>/iot-device-services/v1
DP_CLIENT_ID=<service-client-id>
DP_CLIENT_SECRET=<service-client-secret>
DP_SUBSCRIPTION_KEY=<apim-subscription-key>
DP_ACCOUNT_ID=<account-id>
```

## Recommended complete-device flow

This is the reliable demonstration path when the customer accepts an
all-or-nothing restore:

1. Prepare the source CORE completely: required apps, licenses, PLC boot
   project, Node-RED data, firewall/network settings, and any other intended
   active configuration.
2. Verify that the PLC boot artifacts are active. A typical real backup must
   contain `Application.app` and the matching `Application.crc` under the PLC
   active configuration. Do not infer this from the PLC app package alone.
3. Read `GET /setup/api/v1/setupinfo` from the source CORE and preserve the
   complete object. Do not replace complete app objects with `$content:none`.
4. Submit `CREATE_DEVICE_TEMPLATE` through `POST /tasks` with that setupInfo
   stringified in `parameters.setupInfo`.
5. Poll `GET /tasks/{taskId}` until `DONE` or `FAILED`, with an application
   timeout. Treat an unbounded `RUNNING` task as failure and stop automation.
6. Retrieve `GET /templates/{templateId}` and inspect the stored
   `configurations` string before applying it.
7. If the portal has dropped the resource reference for active app data, add
   the verified reference to the apply payload:

```json
{
  "configurations": {
    "active": { "$path": "configurations/active" }
  }
}
```

   Only do this when the archive layout and platform version have been tested.
8. Submit `APPLY_DEVICE_TEMPLATE` with `restoreOptions: "MERGE"` and the
   complete, reviewed `configurations` string. Poll the task to completion.
9. Verify on the target: installed app set/versions, active solution, PLC
   `Application.app` and `.crc`, PLC project identity/cycle activity, Node-RED
   data, firewall/network state, and any intended system settings.
10. Run machine-specific fine tuning only after the template verification has
    passed. Keep the fine-tuning scripts separate from the immutable template
    module.

The full-device approach is appropriate for a prepared target of the same
hardware/OS/app compatibility class. It is not a safe substitute for
per-component deployment on a device containing unrelated live configuration.

## Public task shapes

Create:

```json
{
  "taskType": "DEVICE_TASK",
  "accountId": "<account-id>",
  "action": "CREATE_DEVICE_TEMPLATE",
  "parameters": {
    "deviceId": "<source-device-id>",
    "name": "<template-name>",
    "version": "1",
    "description": "<description>",
    "setupInfo": "<stringified ctrlX setupInfo>"
  }
}
```

Apply:

```json
{
  "taskType": "DEVICE_TASK",
  "accountId": "<account-id>",
  "action": "APPLY_DEVICE_TEMPLATE",
  "parameters": {
    "deviceId": "<target-device-id>",
    "templateId": "<template-id>",
    "restoreOptions": "MERGE",
    "configurations": "<stringified reviewed template configurations>"
  }
}
```

Treat the exact field name (`taskType` versus examples that say `type`) as an
environment-specific compatibility point. Confirm it against the live API
contract before deployment.

## Critical validation checks

Before applying a template, inspect:

- `packageManagement.installedApps`: every intended app has a compatible
  version and a valid `$path` to an archive resource.
- `configurations.active`: a non-empty or `$path`-referenced active
  configuration is required to transport app data.
- `certificateManagement`: do not copy device identity material between
  devices unless that is an explicit, supported requirement. Device Portal
  registration certificates and private keys normally belong to the target.
- `deviceTypeCode`, OS, architecture, app versions, and licensing compatibility.
- `configurations` payload size and encoding. Send JSON as UTF-8 or ASCII-safe
  escaped JSON with the exact `application/json` media type accepted by the
  gateway.

After applying, inspect the CORE Setup task protocol. These messages are useful:

- `Writing configurations - loading active configuration`: app data was loaded.
- `Writing configurations (skipped, no changes)`: app data was not applied.
- `Updating apps finished`: package processing completed, not necessarily that
  the PLC program was loaded.
- schema warnings: investigate them; do not treat task `DONE` as proof of clean
  restore.

## Known failure modes and workarounds

### Cloud setupInfo endpoint returns 400

If `GET /devices/{deviceId}/setup/setupinfo` returns HTTP 400 with an empty body,
verify the device is online and then read the source object directly from the
CORE with `/setup/api/v1/setupinfo`. Record this as a portal defect, not as
successfully retrieved cloud data.

### `$content` selector tasks remain RUNNING

The CORE Setup API supports `$content` selection markers, but a Device Portal
template task may accept a selector-style payload, process it on the device,
and remain `RUNNING` indefinitely. Do not use the compact selector dialect for
production automation until the cloud service validates it and returns a
bounded result. Prefer a full setupInfo object with unwanted components removed
only when that exact dialect is confirmed by the portal contract.

### Stored template loses active-data `$path`

The uploaded archive can contain `configurations/active/**` while the stored
template JSON says only `"active": {}`. The apply operation then reports success
but skips app data. Verify the archive or CORE protocol and inject the known
`configurations/active` `$path` at apply time only after testing the target
platform. Report this as a portal defect because the cloud should preserve the
resource reference.

### `configurations` is required on apply

Some service versions reject an apply request without `parameters.configurations`
even when documentation describes it as optional. Retrieve and pass the stored
configuration explicitly, then verify the live schema/documentation before
depending on this workaround.

### Active app data is all-or-nothing

`configurations.active` generally represents the complete active solution tree.
Narrowing it to a child such as `configurations.active.plc` may be ignored and
can cause Node-RED, firewall, Data Layer, scheduler, and other data to be
transported as well. If the requirement is genuinely "PLC only", use a direct
CORE Setup ZIP with `mode=merge` or another supported per-app mechanism instead
of claiming that a whole active configuration is modular.

An archived configuration containing only PLC data can be a useful experiment,
but loading it may rebuild the solution store and drop metadata or data for
undeclared apps. Treat it as a lab workaround, not a production-safe pattern,
unless the platform owner confirms its semantics.

## Production architecture decision

Choose explicitly:

**Complete-device module:** Device Portal template with full active configuration.
Use for a known-compatible, prepared target when subsequent scripts will perform
the machine-specific tuning. Verify the complete result before tuning.

**True modular deployment:** build and validate small CORE Setup ZIPs and apply
them directly to the target via the CORE Setup API with `mode=merge`, using the
Device Portal only for reachability if needed. This gives better control over
PLC-only changes and avoids cloud template resource-reference defects.

Do not mix these models silently. A template that contains full active app data
is not an additive per-app module merely because the API task uses `MERGE`.

## Evidence to retain

For each production test, retain sanitized records of:

- source/target compatibility metadata and timestamps;
- template ID, create/apply task IDs, and final states;
- hash/size or presence checks for critical artifacts such as
  `Application.app` and `Application.crc`;
- pre/post app list and active-configuration manifest;
- CORE Setup task protocol and portal responses;
- the exact configuration version and assumptions used.

Remove tokens, passwords, private keys, customer identifiers, internal IPs, and
raw setup exports before adding evidence to this skill or a shared case.
