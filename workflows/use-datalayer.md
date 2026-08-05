# Use Data Layer

Use this workflow for in-device interactions with ctrlX services, including PLC-to-service communication and on-device app integration.

## Focus Areas

- Node paths.
- Operation type: read, write, create, delete, browse, or call.
- Schema expectations.
- Differences between real and virtual targets.
- Whether REST is a better choice for external clients.

## Standard Flow

1. Identify the producer, consumer, and whether both are on the device.
2. Find the relevant Data Layer node path and operation.
3. Confirm payload and schema expectations.
4. Prefer read-only inspection before writes or calls with side effects.
5. For real-device writes or calls that change state, ask before execution.
6. Verify the resulting node state or service behavior.

## Path Lookup → Verify → Write Pattern

```
# 1. Browse to find exact path
ctrlx-datalayer_browse("motion/axs")
→ ["motion/axs/MyAxis", ...]

# 2. Read metadata to get type and schema
ctrlx-datalayer_metadata("motion/axs/MyAxis/state/values/actual/vel")
→ {"type":"double", "unit":"mm/s", ...}

# 3. Write with correct type
ctrlx-datalayer_write("motion/axs/MyAxis/cfg/...", '{"type":"double","value":100.0}')
```

> Never guess paths from docs alone — paths vary between ctrlX OS versions. Always browse first.

## Useful Recipes

- `recipes/datalayer/storage-mount.md`
- `recipes/plc/usb-mount-via-datalayer.md`
