# Use Virtual Core

Use this workflow when a task can be verified against a local virtual ctrlX CORE before touching a real device.

## Standard Flow

1. Read `reference/AGENTS.md` and `labs/ctrlx-os-virtual/AGENTS.md`.
2. Confirm that the task is suitable for a virtual target and does not depend on hardware-backed features.
3. Use `labs/ctrlx-os-virtual/run/run-virtual-core.sh` to launch the VM.
4. Use `labs/ctrlx-os-virtual/run/wait-virtual-core.sh` before REST, Web UI, SSH, Data Layer, or OPC-UA checks.
5. Perform the requested action through the relevant workflow.
6. Use `labs/ctrlx-os-virtual/run/status-virtual-core.sh` and logs under `labs/ctrlx-os-virtual/assets/runtime/` for monitoring.
7. Stop the VM with `labs/ctrlx-os-virtual/run/stop-virtual-core.sh` when the task is complete.

## Safety

- Treat this lab as virtual unless the user points to a real ctrlX device.
- Do not copy VM images into tracked paths.
- Keep VM images, PID files, logs, and runtime state under `labs/ctrlx-os-virtual/assets/`.
- Real-device persistent changes still require explicit confirmation.

## Default Local Endpoints

- Web UI: `https://127.0.0.1:8443`
- SSH: `127.0.0.1:8022`
- Data Layer: `127.0.0.1:8740`
- OPC-UA: `127.0.0.1:4840`

## Verification Notes

Virtual ctrlX systems may not expose real hardware-backed nodes, storage providers, fieldbus devices, or USB behavior. If a workflow depends on such features, say that virtual verification is only partial and identify what still needs real-device validation.
