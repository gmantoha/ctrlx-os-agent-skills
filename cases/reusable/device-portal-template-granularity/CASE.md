# Case: Device Portal templates cannot deploy app data per app

Sanitized. Account, device, template, and task IDs, hostnames, and credentials
are removed on purpose.

## Problem statement

An OEM wants serial commissioning: a commissioning tool resolves the machine
variant from a QR code and applies several configuration modules additively
(`MERGE`) to a pre-licensed ctrlX CORE through the Device Portal public API:
PLC boot project, Node-RED flows, network, firewall, further settings. The
first module, "PLC boot project only, nothing else touched", had to be proven.

## Platform

- Device Portal QA environment, public API with service client credentials and
  APIM subscription key (no browser session).
- ctrlX CORE X3, ctrlX OS 4.6.x on Ubuntu Core 24, Setup/Solutions/PLC 4.6.2,
  Node-RED 4.6.6, Device Portal Agent 3.6.x.
- Tests on 2026-08-05, 2026-09-07, and 2026-09-09.

## Evidence

1. **WebUI "Save as template" with only "PLC" selected** (device agent journal,
   `Making a custom backup with the following content`): the selection contains
   `packageManagement.installedApps` with `rexroth-plc` and `rexroth-deviceagent`,
   all other apps as `{"$content":"none"}`, and no `configurations` key. The
   18 MB archive held the two app packages and no `Application.app`.
2. **Public API create with `configurations.active: {}`**: task `DONE`, device
   protocol `Saving configurations - active configuration`, archive contains
   `configurations/active/plc/run/<arch>/data/Application.app` and `.crc`.
   `GET /templates/{id}` stored `"configurations": {"active": {}}` while every
   app entry received its `$path`.
3. **Apply without `$path`**: task `DONE`, device protocol
   `Writing configurations (skipped, no changes)`, deleted boot files not
   restored. **Apply with `{"active": {"$path": "configurations/active"}}`**:
   `Writing configurations - loading active configuration`, both files
   restored, PLC loaded them.
4. **Narrowing attempt** `{"active": {"$content":"none", "plc": {"$content":"files"}}}`
   was ignored; the backup packed the complete active configuration
   (datalayer, firewall, framework, node-RED, plc, remote-logging, scheduler,
   script, security-scanner, synchronization, trace, vpn-manager).
5. **Stacking test 2026-09-07** with distinct marker values in `node-RED/` on
   source and target: applying the PLC app-data layer replaced the target
   marker with the source value and reset the PLC cycle counter, in both
   application orders. Settings layers (interface DNS, timezone) stacked in any
   order without changing any of the 57 active-data hashes.
6. **Support recipe test 2026-09-09**: template A (all apps + app data) from
   the full device, template B (PLC app + app data) from the same device after
   uninstalling Node-RED and removing its leftover directory. Apply A, then B
   with `MERGE`: a flow deployed between the applies was deleted
   (`flows.json`, `flows_cred.json` gone, `GET /node-red/flows` returned `[]`),
   markers in `node-RED/`, `datalayer/`, `firewall/` removed, PLC counter
   reset, Solutions journal shows Query/Prepare/Load for every registered app.
   All four portal tasks reported `DONE`.
7. Recovery with the Setup ZIP taken before the tests (`mode=merge`) brought
   54 of 56 files back byte-identical; the rest differed only in generated
   IDs.

## Analysis

`configurations.active` is the Setup category `activeAppData`, one unit with
`files` content. The Solutions app loads an active configuration as a whole:
each app directory in the archive replaces the target directory and the store
is rebuilt from the loaded `configuration.json`. A template created on a
"PLC-only" device still carries that device's `datalayer/`, `firewall/`,
`scheduler/`, and other directories, so applying it overwrites those on the
target and removes what is missing. The cloud task result cannot distinguish
this from a PLC-only merge. Templates are also not additive by design of the
cloud store: the `$path` for app data is dropped, so a plain apply is a no-op.

## Root cause

Platform granularity (active configuration is atomic) combined with a Device
Portal defect (lost `configurations.active.$path`). Not a usage error.

## Fix or workaround

- Ship one **app-data template per machine variant** built on a golden device
  that already combines PLC, Node-RED, firewall, and Data Layer data. Inject the
  `$path` on every apply. Add separate settings-only templates for network,
  time, users, and similar categories; those stack.
- For a genuine PLC-only module use a direct CORE Setup ZIP with
  `mode=merge` (`recipes/device-portal/plc-bootproject-setup-zip.md`) and
  verify undeclared apps afterwards.
- After an apply that installs apps, switch the device back to OPERATING.

## Reusable lessons

- Verify on the device: setup task protocol, file hashes, PLC cycle counter,
  Node-RED flow list. `DONE` plus an unchanged package list is not acceptance.
- Use distinct marker data on source and target; identical data hides a
  destructive whole-tree restore.
- Take a recovery ZIP before every experiment; it restored the baseline
  reliably.
- Uninstalling an app leaves its data in the active configuration.
- Reuse one Identity Manager token per session on the CORE.
