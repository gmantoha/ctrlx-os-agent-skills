# PLC target architecture

## Rule

Select the PLC Engineering device architecture from the target CORE, not from
the network address alone:

| Target | PLC Engineering device |
| --- | --- |
| Physical ctrlX CORE | `ctrlX OS ARM64` |
| ctrlX WORKS virtual CORE on the x86 host | `ctrlX OS x64` / `amd64` |

## Verification

Before building or downloading, inspect the Engineering device metadata:

```text
GET http://localhost:9002/plc/engineering/api/v2/devices/Device
```

The `deviceInfo.name`, `deviceInfo.deviceType`, and `deviceInfo.description`
must match the target architecture. A project built for `amd64 (x64)` cannot be
downloaded to an ARM64 CORE; Engineering reports a hardware-platform mismatch
during `ApplicationLoginJob`.

After selecting the correct device, build again before downloading. A successful
build alone does not prove that the application started; verify the application
diagnosis and that the published PLC snapshot changes over time.

## Observed failure

On a real ARM64 CORE, a project still configured for x64 failed at download with
the platform mismatch. After selecting ARM64 and downloading, the target still
reported `cdsEventDenyStart` and invalid PLC license metrics; the task scheduler
advanced but the user-program snapshot remained at its initialization values.
