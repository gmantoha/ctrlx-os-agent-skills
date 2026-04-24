# USB Mount Via Data Layer

Use this workflow when a PLC program on ctrlX OS needs to mount or unmount USB media.

## Recommendation

Prefer ctrlX Data Layer, not HTTP from ST code.

Verified nodes from the migrated reusable case:

- `system/resources/tasks/storage/mountDevice`
- `system/resources/tasks/storage/unmount`
- `system/resources/storage`

## Why

- no TLS handling in PLC code
- no bearer token management in PLC code
- lower overhead than routing a REST call out and back into the same device
- aligned with ctrlX on-device integration patterns

## Version Note

The storage task nodes require ctrlX OS 4.4 or newer.

## Fallbacks

- for older systems, prefer Node-RED as the HTTP mediator
- for operator-only access, a restricted Web UI path can be a pragmatic workaround

## Source

See `cases/reusable/plc-rest-req/` for the original investigation, references, and probe output.
