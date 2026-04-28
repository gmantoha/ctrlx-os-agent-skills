# ctrlX OS Virtual Lab

This folder contains guidance and helper scripts for running a local virtual ctrlX OS environment.

The virtual image itself is intentionally not tracked. Copy VM image files into `assets/` before launching the lab.

## Getting Started

1. Copy the environment template:

```bash
cp labs/ctrlx-os-virtual/run/env.example labs/ctrlx-os-virtual/run/.env
```

2. Put VM image files into the ignored asset folder inside this skill:

```bash
mkdir -p labs/ctrlx-os-virtual/assets/4.6.0
```

The `assets/` directory is ignored by git. Keep all VM images, mutable disks, PID files, and QEMU logs there.

3. Launch the virtual ctrlX CORE:

```bash
labs/ctrlx-os-virtual/run/run-virtual-core.sh
```

4. Wait until HTTPS is reachable:

```bash
labs/ctrlx-os-virtual/run/wait-virtual-core.sh
```

5. Check status or monitor logs:

```bash
labs/ctrlx-os-virtual/run/status-virtual-core.sh
labs/ctrlx-os-virtual/run/monitor-virtual-core.sh
```

6. Stop the virtual ctrlX CORE:

```bash
labs/ctrlx-os-virtual/run/stop-virtual-core.sh
```

## Default Endpoints

- Web UI: `https://127.0.0.1:8443`
- SSH: `127.0.0.1:8022`
- Data Layer: `127.0.0.1:8740`
- OPC-UA: `127.0.0.1:4840`

Default Web UI credentials for this lab are `boschrexroth` / `boschrexroth`.

## Image Layout

Each VM folder under `assets/` must contain at least:

- `kernel.img`
- `initrd.img`
- `virtual-control.base.qcow2`

Optional image files such as `bn1yhwxp.user.qcow2` may also be stored there if needed by a local QEMU setup, but the default launcher uses the base image layout documented above.

## Agent Usage

Agents should use this lab to verify workflows against a virtual target before touching a real ctrlX CORE when practical. Use `workflows/use-virtual-core.md` for lifecycle handling, then switch to the relevant REST, Web UI, SSH, Data Layer, app, or debug workflow for the task itself.

Behavior verified on this VM must be described as virtual verification. Hardware-backed features can differ from a real ctrlX CORE.
