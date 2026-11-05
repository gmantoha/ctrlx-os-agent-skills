# Real Vs Virtual

Real and virtual ctrlX systems differ.

Typical differences:

- hardware-backed features may be absent in virtual systems
- ports and SSH mapping may differ
- storage, USB, and some field interfaces may not exist virtually

Always verify whether a workflow depends on real hardware.

CPU architecture: the COREvirtual is amd64 like X5/X7/IPC; the X3 is arm64.
See `reference/platform/hardware-architectures.md` before choosing `--build-for`.
