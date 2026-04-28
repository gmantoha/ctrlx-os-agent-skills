# Work With PLC

Use this workflow for ctrlX PLC Engineering tasks, Structured Text examples, and PLC-facing integration patterns.

## Rules

- Prefer Data Layer integration when the PLC interacts with local ctrlX services.
- Make clear whether alternatives are officially supported, merely possible, or not recommended.
- Distinguish between PLC runtime behavior, Engineering configuration, and external REST/API access.

## Standard Flow

1. Identify PLC runtime, target device, and integration goal.
2. Determine whether Data Layer, REST, WebDAV, fieldbus, or app-specific APIs are appropriate.
3. Read PLC and target-service references.
4. Provide minimal ST examples or Engineering steps where useful.
5. Verify on a virtual or real target when available and safe.

## Useful Recipes

- `recipes/plc/usb-mount-via-datalayer.md`
