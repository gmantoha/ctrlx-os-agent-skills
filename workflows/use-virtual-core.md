# Use Virtual Core

Use this workflow when a task can be verified against a local virtual ctrlX CORE before touching a real device.

## Select the Host Platform

- **Windows:** read [Windows QEMU startup](../recipes/virtual-core/windows-qemu-start.md)
  first. Use native process/port checks and the documented PowerShell/QEMU procedure.
  The Bash launcher's `-enable-kvm` / `-cpu host` options and Bash PID handling are not
  a Windows lifecycle implementation.
- **Linux with KVM:** use the Bash lifecycle scripts below after checking the image
  directory/version. Do not assume the default `4.6.0` matches the locally available image.

## Standard Flow

1. Read `reference/AGENTS.md` and `labs/ctrlx-os-virtual/AGENTS.md`.
2. **Check status first.** On Linux, run `labs/ctrlx-os-virtual/run/status-virtual-core.sh`; on Windows, inspect native QEMU processes, command lines and listening ports as described in the recipe. Tell the user whether a virtual instance is already running before launching or stopping anything.
3. Confirm that the task is suitable for a virtual target and does not depend on hardware-backed features.
4. Launch the VM only if it is not already running: use `labs/ctrlx-os-virtual/run/run-virtual-core.sh` on Linux or the Windows recipe. Reuse an existing inspected overlay instead of silently creating a new empty lab.
5. Wait for readiness before REST, Web UI, SSH, Data Layer, or OPC-UA checks. The Bash `wait-virtual-core.sh` checks HTTPS reachability only; for browser access also verify Web UI HTTP 200 and unauthenticated identity HTTP 401, not a temporary HTTP 503 startup page.
6. Perform the requested action through the relevant workflow.
7. Monitor with the platform-appropriate status checks and logs under `labs/ctrlx-os-virtual/assets/runtime/`.
8. **Stop temporary test VMs when done.** On Windows, request a graceful shutdown with QMP `system_powerdown` and verify process exit; on Linux, use the lab stop script. If the user explicitly requests continued operation (including starting it for ongoing browser access), leave it running and report the URL and running status at the end.

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
