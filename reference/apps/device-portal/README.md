# Device Portal: Mass Rollout Templates via the Public API

The Device Portal public API can create and apply ctrlX CORE templates for
external commissioning software. This reference is intentionally generic:
credentials, account IDs, device IDs, template IDs, gateway hostnames, IP
addresses, and raw setup exports belong in a private project workspace, never
in this skill.

State of knowledge: 2026-09-09, verified against the QA environment with a
ctrlX CORE X3 on ctrlX OS 4.6.x (Ubuntu Core 24, Setup/Solutions/PLC 4.6.2,
Device Portal Agent 3.6.x). Production availability of individual fixes must be
confirmed separately. Official sources are the Docupedia exports "IoT Services
Public API Features - How To" (v18, 2026-07) and "Mass rollout templates API"
(v34, 2026-08).

## Prerequisites

- The **Device Portal Agent** app (`rexroth-deviceagent`) is installed on every
  device. Manual installation: Service mode, allow installation from unknown
  source, install from file. The device shows `ONLINE` in the portal about five
  minutes after installation.
- The **device ID** is the serial number. It is shown on the device under
  Settings → System Information and in the portal device list.
- **Premium API access**: a Keycloak service client (client ID and secret) and
  an APIM subscription key issued by the Device Portal team. The account ID is
  the portal account the devices are associated to.

## Authentication

```text
POST {DP_TOKEN_URL}
Content-Type: application/x-www-form-urlencoded
grant_type=client_credentials&client_id=<id>&client_secret=<secret>

every API call:
Authorization: Bearer <access_token>
Ocp-Apim-Subscription-Key: <subscription-key>
Accept: application/json
```

Cache the token until shortly before `expires_in`. Do not automate the browser
portal and do not reuse its session cookie. The WebUI uses a same-origin BFF
under `/api/v2/*` (cookie-authenticated, no bearer token in the browser, no
Swagger). It rejects the service-account token and is not a public contract.

## Public API endpoints

Base: `https://<device-portal-api-host>/iot-device-services/v1`

| Method and path | Status (QA) | Notes |
|---|---|---|
| `GET /devices/{deviceId}` | verified 2026-08, 2026-09 | `status` is `ONLINE`, `OFFLINE`, or `NOT_REGISTERED`; also `lastCommunication`, `typeCode`, `operatingSystemVersion`. |
| `GET /devices/{deviceId}/setup/setupinfo` | verified 2026-09-07 | Returns the setupinfo the agent last reported (published about every 50 s while online). Not live state when the device is offline. Returned HTTP 400 with an empty body in 2026-08; keep the CORE fallback. |
| `POST /tasks` | verified | `CREATE_DEVICE_TEMPLATE` and `APPLY_DEVICE_TEMPLATE`, see envelope below. |
| `GET /tasks/{taskId}` | verified | Poll until `DONE` or `FAILED`. |
| `PATCH /tasks/{taskId}` | exists | Semantics not confirmed. Do not rely on it to cancel a stuck task. |
| `GET /templates?accountId={id}&pageSize=&pageNumber=` | verified 2026-09-07 | Without `accountId` the gateway answers HTTP 400. Returned 404 in 2026-08. |
| `GET /templates/{templateId}` | verified | `configurations` is a JSON string. |
| `PATCH /templates/{templateId}` | design doc only | Update name, description, configurations. Not exercised. |
| `POST /templates/{templateId}/saveAsUserTemplate` | design doc only | Copy a `READY_TO_USE` template into the account. Not exercised. |
| `DELETE /templates/{templateId}` | design doc only | Not exercised. |

Task states: `PENDING` (device has not received the message), `RUNNING`
(executing on the device), `SCHEDULED`, `DONE`, `FAILED`. A create task that
reaches `DONE` carries `result.templateId`; in all observed cases it equals the
task ID. Typical durations: create 30 s to 2 min, apply 1 to 4 min, longer when
apps are installed.

## Task envelope

```json
{
  "type": "DEVICE_TASK",
  "accountId": "<account-id>",
  "action": "CREATE_DEVICE_TEMPLATE",
  "parameters": {
    "deviceId": "<source-device-id>",
    "name": "<template-name>",
    "version": 1,
    "description": "<description>",
    "setupInfo": "<JSON string: selection in setupinfo dialect>"
  }
}
```

```json
{
  "type": "DEVICE_TASK",
  "accountId": "<account-id>",
  "action": "APPLY_DEVICE_TEMPLATE",
  "parameters": {
    "deviceId": "<target-device-id>",
    "templateId": "<template-id>",
    "restoreOptions": "MERGE",
    "configurations": "<JSON string: reviewed template configurations>"
  }
}
```

Optional `"schedule": {"start": "<ISO-8601>"}` inside `parameters` schedules
the task. `restoreOptions` is `MERGE` or `OVERRIDE`.

Contract notes:

- `type` is the accepted key. `taskType` (used by earlier clients) is rejected
  since 2026-09 with HTTP 400. The documented envelope includes `accountId`;
  requests without it were also accepted.
- `configurations` on apply is required in practice (HTTP 400
  `The Configurations field is required.`) although the How-To calls it optional.
- Task responses contain `id`, `type`, `action`, `state`, `parameters.deviceId`,
  optionally `result`, `eta`, `updatedAt`.

Template object (from `GET /templates/{id}`): `id`, `type` (`CUSTOM` or
`READY_TO_USE`), `name`, `description`, `version`, `deviceTypeCode`,
`compatibleOs` (for example `Ubuntu Core 24`), `configurations` (string),
`createdAt`, `createdBy`, `updatedAt`, `updatedBy`.

## The setupinfo dialect

The portal expects the object returned by the device's
`GET /setup/api/v1/setupinfo` (the same shape as `ctrlx-setup.json`), edited
as follows:

- Exclude an app: replace its entry under `packageManagement.installedApps`
  with `{"$content": "none"}`. Keep the entries of wanted apps verbatim.
- Include active app data: add `"configurations": {"active": {}}`. An object
  without `$content` means "include, with files".
- Exclude app data explicitly (settings-only templates):
  `"configurations": {"active": {"$content": "none"}}`.
- Exclude a settings group: remove its top-level key (`connectivity`,
  `dateTime`, `identityManagement`, `certificateManagement`, `hosts`, `proxy`,
  `ssh`, `storage`, `licenseManagement`, `system`). There is no factory reset;
  values absent from the template keep their current device values.
- Keep `systemInfo` and `typePlate` from the source. The portal uses them for
  `deviceTypeCode` and `compatibleOs`.
- Keep `$forceReboot`, `$name`, `$schema`, `$version`, `apps`, and
  `packageManagement.allowUnknownApps`.

Do **not** send the Setup app's native selector dialect (`"$content": "items"`
or `"files"` inside `installedApps` or `configurations`). The device executes
it correctly and uploads the archive, but the cloud task stays `RUNNING`
forever and cannot be cancelled through the public API. The likely cause is a
deserialization failure of `installedApps` on the cloud side.

## Setup selection model on the device

`GET /setup/api/v1/categories` on the CORE lists what a template can contain.
`modifyingContent` is the `$content` value when a category is selected in a
native Setup request; `nonModifyingContent` when it is not.

| Category | setup JSON path | selected → | not selected → |
|---|---|---|---|
| `systemApps` | `packageManagement.installedApps.*` (base, gadget, kernel, snapd, automationcore, deviceadmin, setup, solutions, version-guard) | files | items |
| `customApps` | `packageManagement.installedApps.*` | files | items |
| `appSpecificSettings` | `apps.*` | items | none |
| `activeAppData` | `configurations.active` | files | none |
| `archivedAppData` | `configurations.archive.*` | files | none |
| `certsAndKeys` | `certificateManagement.applications.*.{certificates,keys,certificateRevocationLists,pkcs12Containers}` | files | none |
| `pkis`, `subscriptions` | `certificateManagement.pkis`, `.subscriptions` | items | none |
| `usersAndPermissions` | `identityManagement.{groups,users,namedPasswordPolicies,ldapConfiguration,radiusConfiguration,remoteAuthConfig,identityProviders,roles}` | items | none |
| `network` | `connectivity.{bridge,can,dan,ethernet,vlan,wifi}.*` | items | none |
| `networkInterfaceSettings`, `networkDiscovery`, `networkDhcpServerConfiguration`, `networkDhcpServerReservations` | `connectivity.settings`, `.discoveryServices`, `.dhcpServer.configuration`, `.dhcpServer.reservations` | items | none |
| `hostname`, `hosts`, `proxy`, `ssh` | `system.hostname`, `hosts`, `proxy`, `ssh` | items | none |
| `appManagementSettings` | `packageManagement.*` (settings, not apps) | items | none |
| `licenseManagement`, `dateAndTime`, `cpu`, `storage`, `theming` | `licenseManagement`, `dateTime`, `system.cpu`, `storage`, `system.theming` | items | none |

`files` means settings plus the referenced resource files in the archive;
`items` means JSON settings only. `configurations.active` is one category. There
is no path below it, so app data cannot be selected per app. An attempt to narrow
it (`"active": {"$content":"none", "plc": {"$content":"files"}}`) was ignored and
the complete active configuration was packed. `configurations.archive.<name>` is
selectable per archived configuration.

## CORE Setup API (device side)

From the OpenAPI snapshot `rexroth-setup/setup/setup.v1.7.0` in this repository:

```text
GET    /setup/api/v1/setupinfo            partial setup/backup information (the object the agent publishes)
GET    /setup/api/v1/categories           category → path mapping above
GET    /setup/api/v1/createoptions
POST   /setup/api/v1/create               body = native selection; response Location: /tasks/create_<id>
GET    /setup/api/v1/tasks[/{taskId}]     task state, progress, protocol[]
GET    /setup/api/v1/setups               list of setup/backup files on the device
GET    /setup/api/v1/setups/{fileName}    download (Accept: */*)
PUT    /setup/api/v1/setups/{fileName}    upload
DELETE /setup/api/v1/setups/{fileName}
POST   /setup/api/v1/apply                multipart: setup=<zip>, mode=merge|restore; Location: /tasks/apply_<id>
GET    /setup/api/v1/history[/{id}]
```

Task `state` values on the device are lowercase (`done`, `failed`).

## Archive and `$path` model

The device builds a ZIP with `ctrlx-setup.json` at the root and referenced
resources next to it. Only resources referenced by a `$path` are used during a
restore.

```text
ctrlx-setup.json
packageManagement/installedApps/<app>-<version>.app          $path in installedApps.<app>
configurations/active/configuration.json                     $path "configurations/active"
configurations/active/plc/run/<arch>/data/Application.app
configurations/active/plc/run/<arch>/data/Application.crc
configurations/active/plc/run/<arch>/misc/plc_system.cfg
configurations/active/node-RED/flows.json ...
configurations/active/{datalayer,firewall,scheduler,...}/
```

Observed on the stored template (`GET /templates/{id}` → `configurations`):
every included app entry gains `"$path": "packageManagement/installedApps/<app>-<version>.app"`,
but `configurations.active` is stored as `{}` although the device wrote
`{"$path": "configurations/active"}` into the archive and the archive contains
the files. This is the defect that makes app-data templates a silent no-op on
apply. Workaround: send
`"configurations": {"active": {"$path": "configurations/active"}}` in the apply
payload. The archived variant `{"active": {"$path": "configurations/archive/<name>"}}`
also loads.

## Apply semantics

- `MERGE`: settings and apps in the payload are applied; properties absent from
  the payload are left as they are. Apps missing on the target are installed
  (device switches SETUP → SERVICE by itself and stays in SERVICE afterwards).
- `OVERRIDE`: to not install an app or setting, remove it from the
  configurations sent; with `MERGE` a removed entry is simply ignored.
- App data in the payload is loaded as a whole active configuration by the
  Solutions app: every app directory in the archive replaces the target
  directory and the configuration store is rebuilt from the loaded
  `configuration.json`. Directories not in the archive are not preserved
  either. Files that an app agent regenerates (Node-RED `.config.nodes.json`,
  `package.json`) reappear with new timestamps; flows do not.
- Applying a template that was created on another device logs two
  `certificateManagement` errors (`action 'delete' not allowed for device.hsm`
  / `device.crt`). The design document treats the restore as successful.

Setup protocol lines to check on the device after an apply
(`GET /setup/api/v1/tasks`, newest `apply_*` task, `protocol[]`):

- `Writing configurations - loading active configuration` — app data loaded.
- `Writing configurations (skipped, no changes)` — app data not applied
  (typically the missing `$path`).
- `Switching to SETUP state` / `Switching to SERVICE state` / `Updating apps -
  installing "<app>" succeeded` — apps installed; restore OPERATING afterwards.
- `Writing connectivity` — appears even for app-only templates because the
  WebUI-style selection carries `connectivity.dhcpServer`,
  `identityManagement.identityProviders`, and `storage.networkShares`.
- `WARNING Json schema issue: packageManagement.installedApps.<app>: Additional
  property $content is not allowed` — one block per excluded app, harmless.
- `Device restore finished` — end marker; `state` is `done`.

## Known defects and status

| # | Finding | Status (QA) |
|---|---|---|
| A | `GET /devices/{id}/setup/setupinfo` HTTP 400, empty body | Fixed by 2026-09-07 (HTTP 200). Keep the CORE fallback. |
| B | Selector dialect (`$content: items/files`) leaves the cloud task in `RUNNING` forever; no timeout, no cancel | Open. Never send it. |
| C | Stored template loses `configurations.active.$path`; apply silently skips app data | Open as of 2026-09-09. Inject `$path` on every apply. |
| D | `configurations` mandatory on apply although documented optional | Open. Always send it. |
| E | No template list endpoint | Fixed by 2026-09-07 (`GET /templates?accountId=`). |
| F | About 45 schema warnings per apply from `$content: none` entries | Open. Filter them when reading protocols. |
| G | Envelope key changed from `taskType` to `type` | `type` since 2026-09; matches the official How-To. |
| H | Device stays in SERVICE after an apply that installed apps | Platform behavior. Commissioning software must switch back. |
| I | App data selectable only as a whole | Platform limit (`activeAppData` category has no sub-path). |
| J | WebUI cannot include `activeAppData` / `archivedAppData` | Open. API-only feature. |

## PLC-specific verification

For a real PLC boot project, verify both artifacts in the active configuration:

```text
configurations/active/plc/run/linux-gcc-aarch64/data/Application.app
configurations/active/plc/run/linux-gcc-aarch64/data/Application.crc
```

The architecture path depends on the target. Also verify `plc_system.cfg`. On
the running device read the PLC application properties and the task cycle
counter twice over the Data Layer REST facade:

```text
GET /automation/api/v2/nodes/plc/app/Application/admin/properties
GET /automation/api/v2/nodes/plc/app/Application/admin/task/MainTask/cycle-count
```

A cycle counter that resets to a low value after an apply proves that the PLC
was reloaded; an increasing counter proves it runs.

See [`workflows/device-portal-templates.md`](../../../workflows/device-portal-templates.md)
for the decision flow and safety gate, and `recipes/device-portal/` for the
concrete request sequences.
