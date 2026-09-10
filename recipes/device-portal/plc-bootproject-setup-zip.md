# PLC Boot Project as a Direct Setup ZIP Module (mode=merge)

The modular alternative when the requirement is "deploy the PLC boot project
and touch nothing else". Device Portal templates cannot do this because app
data is transported only as the complete active configuration
(`reference/apps/device-portal/README.md`). Lab-validated on ctrlX OS 4.6.x,
PLC 4.6.2, `linux-gcc-aarch64`, 2026-07/08. Not certified by the platform
owner; treat as a tested workaround.

## Package layout

```text
ctrlx-setup.json
configurations/active/configuration.json
configurations/active/plc/run/linux-gcc-aarch64/misc/plc_system.cfg
configurations/active/plc/run/linux-gcc-aarch64/data/Application.app
configurations/active/plc/run/linux-gcc-aarch64/data/Application.crc
```

`ctrlx-setup.json` (no `packageManagement`, no settings groups):

```json
{
  "$schema": "./setup.v1.schema.json",
  "$forceReboot": false,
  "$name": "plc-bootproject-<variant>",
  "$version": "1",
  "configurations": {
    "active": { "$path": "configurations/active" }
  }
}
```

`configurations/active/configuration.json` limited to the PLC app:

```json
{
  "$schema": "<schema URL as written by the Solutions app on the golden device>",
  "description": "PLC bootproject only",
  "device": "ctrlX-OS",
  "user": "rexroth-setup",
  "apps": [
    {
      "name": "rexroth-plc",
      "version": "4.6.2",
      "appDirectories": [
        { "name": "plc", "copyOnLoad": true, "writeProtected": true },
        { "name": "plc/run/linux-gcc-aarch64/data", "copyOnLoad": true, "writeProtected": false }
      ]
    }
  ]
}
```

Take the schema URL, app version, and directory entries from a real backup of
the golden device (`recipes/device-portal/target-snapshot-and-recovery.md`)
rather than typing them.

## Where the artifacts come from

- Create a Setup backup with `activeAppData` on the golden device while the
  boot project is loaded and running. A backup taken without an active boot
  application contains no `Application.app` and no `Application.crc`.
- `Application.app` is the compiled boot application; `Application.crc` is its
  checksum and must match. Both are required.
- `plc_system.cfg` tells the runtime where the application is. Keep the full
  version from the golden device. A two-section minimum (`[cmpapp]` with
  `Application.1=Application` plus the `[cmp_cx_util]` section) restored
  successfully, but functional equivalence of all runtime settings (retain,
  task groups, sockets, logging, security) was not proven.
- `LastLoaded*.json`, `*.Struct.json`, `.ObjectDatabase.csv*`, and the empty
  `PlcLogic/`, `_cnc/`, `visu/` directories are not required for the restore.
  They serve PLC Engineering synchronization and project display; include them
  when engineering access to the deployed device matters.

## Build the ZIP

Use a tool that writes plain file entries (`7z a`, or `zip -r -D`). Some
Python `zipfile` variants that emit directory entries made the Setup app fail
with `Zip: write to directory`.

```bash
cd package-root && 7z a ../plc-bootproject-<variant>.zip ctrlx-setup.json configurations
```

## Apply

```bash
core POST /setup/api/v1/apply -H 'Accept: */*' -D headers.txt \
  -F 'setup=@plc-bootproject-<variant>.zip;type=application/zip' -F 'mode=merge'
# Location: /tasks/apply_xxxxxx  -> poll /setup/api/v1/tasks/apply_xxxxxx until state done, progress 100
```

Then verify: `Application.app` / `Application.crc` present with new
timestamps, PLC application properties readable, cycle counter increasing,
package list unchanged, Node-RED flows unchanged.

## Safety rules

- Never include `packageManagement` unless installing or removing apps is
  intended. A `ctrlx-setup.json` with a reduced `installedApps` list made the
  restore try to uninstall the apps that were missing from the list, including
  PLC and Node-RED.
- Never use `mode=restore` (or the portal's `OVERRIDE`) for a module.
- The Solutions "load active configuration" step rebuilds the configuration
  store from the loaded `configuration.json`. With a PLC-only
  `configuration.json`, Node-RED flow files stayed byte-identical, but stored
  data of apps not declared in it disappeared from the store
  (`framework/affinity/*`, `security-scanner/Schedules.json`, PLC engineering
  metadata). Verify every unrelated app after the first apply on each platform
  version, and declare additional apps in `configuration.json` if their data
  must be preserved.
- Verify installed apps before and after every apply.
- The PLC data directory is write-protected for WebDAV; the Setup restore is
  the supported write path.

## Transport

The ZIP has to reach the CORE Setup API directly (LAN, VPN, or a remote-access
channel). Shipping it through the Device Portal template store is not possible
without the `$path` and all-or-nothing limitations described in the reference.
Pushing it over the Device Portal remote-access channel is a design option that
was not tested.
