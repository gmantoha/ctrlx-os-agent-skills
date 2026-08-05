# Work With PLC

Use this workflow for ctrlX PLC Engineering tasks, Structured Text examples, and PLC-facing integration patterns.

## Rules

- Prefer Data Layer integration when the PLC interacts with local ctrlX services.
- Make clear whether alternatives are officially supported, merely possible, or not recommended.
- Distinguish between PLC runtime behavior, Engineering configuration, and external REST/API access.
- CODESYSScript.exe is **not present** in standard ctrlX WORKS 4.6.x — use the Engineering REST API (port 9002) for all automation.

## Standard Flow

1. Identify PLC runtime, target device, and integration goal.
2. Determine whether Data Layer, REST, WebDAV, fieldbus, or app-specific APIs are appropriate.
3. Read the relevant reference and recipe below.
4. Provide minimal ST examples or Engineering steps where useful.
5. Verify on a virtual or real target when available and safe.

## Task Routing

| Task | Read first |
|------|-----------|
| Build, download, start PLC app | `recipes/plc/deploy-and-start.md` |
| Create or update POUs / GVLs via REST | `recipes/plc/create-pou-gvl.md` |
| Motion ST code with AxisInterface | `recipes/plc/axis-interface-motion.md` |
| Engineering REST API reference (all job types, ports, nodeUrl format) | `reference/apps/plc/engineering-api-v2.md` |
| Scripting / automation capabilities | `recipes/plc/engineering-scripting.md` |
| PLC ↔ USB via Data Layer | `recipes/plc/usb-mount-via-datalayer.md` |

## Prerequisites (always check)

1. **Project open** — `GET /projects/current` must return the project; otherwise run `ProjectJob { action: Open }` first.
2. **Device configured** — run `CommunicationSettingsJob` with correct `ipAddress`, `httpsPort: 8443`, `plcPort: 8740`.
3. **User logged in** — run `DeviceUserLoginJob` before `ApplicationLoginJob` (see `deploy-and-start.md`).
4. **Motion app in Running mode** — required before any AxisInterface call (see `recipes/motion/motion-opstate-switch.md`).

## Key Facts (ctrlX WORKS 4.6.x, verified 2026-06-15)

- Engineering REST API base: `http://localhost:9002/plc/engineering/api/v2`
- PLC Gateway port: **8740** (not 11740)
- `BuildJob` action: `"GenerateCode"` (not `"GenerateCodeJob"`)
- `ApplicationLoginJob` nodeUrl: no leading slash — `"devices/Device/Plc Logic/Application"`
- `DeviceUserLoginJob`/`CommunicationSettingsJob` nodeUrl: with leading slash — `"/devices/Device"`
- Swagger spec vs. tested behavior may differ — tested values in `engineering-api-v2.md` take precedence
