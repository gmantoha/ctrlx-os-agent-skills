# Use Virtual Core

Use this workflow when a task can be verified against a local virtual ctrlX CORE before touching a real device.

## Standard Flow

1. Read `reference/AGENTS.md` and `labs/ctrlx-os-virtual/AGENTS.md`.
2. **Check status first.** Run `labs/ctrlx-os-virtual/run/status-virtual-core.sh` and tell the user whether a virtual instance is already running before doing anything else.
3. Confirm that the task is suitable for a virtual target and does not depend on hardware-backed features.
4. Use `labs/ctrlx-os-virtual/run/run-virtual-core.sh` to launch the VM if it is not already running.
5. Use `labs/ctrlx-os-virtual/run/wait-virtual-core.sh` before REST, Web UI, SSH, Data Layer, or OPC-UA checks.
6. Perform the requested action through the relevant workflow.
7. Use `labs/ctrlx-os-virtual/run/status-virtual-core.sh` and logs under `labs/ctrlx-os-virtual/assets/runtime/` for monitoring.
8. **Stop the VM when done.** Run `labs/ctrlx-os-virtual/run/stop-virtual-core.sh` after the task is complete. If the user wants to keep it running, confirm explicitly and report the running status at the end of the session.

## Safety

- Always check and report virtual instance status at the start and end of any task that involves the virtual lab.
- Stop the virtual instance after testing unless the user explicitly asks to keep it running.
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
