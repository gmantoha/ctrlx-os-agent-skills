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

## Useful Recipes

- `recipes/datalayer/storage-mount.md`
- `recipes/plc/usb-mount-via-datalayer.md`
