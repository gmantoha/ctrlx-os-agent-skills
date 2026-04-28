# Storage Mount Via Data Layer

Use this workflow for on-device storage mount and unmount operations exposed via Data Layer.

Known nodes:

- `system/resources/tasks/storage/mountDevice`
- `system/resources/tasks/storage/unmount`
- `system/resources/storage`

Notes:

- these nodes are version-dependent
- virtual targets may not expose the same storage behavior as real devices
- the payload uses `DataExchange` in CamelCase

See `recipes/plc/usb-mount-via-datalayer.md` for the PLC-facing version of this pattern.
