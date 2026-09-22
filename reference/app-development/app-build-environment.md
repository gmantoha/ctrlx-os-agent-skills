# ctrlX App Build Environment

The ctrlX App Build Environment (ABE) is a Linux VM managed by ctrlX WORKS for
building ctrlX snaps with the official SDK and Snapcraft tools.

## Role separation

- Edit application code in one canonical Windows source folder.
- Build and inspect snaps in the Linux ABE.
- Store completed `.snap` files in a separate Windows artifacts folder.
- Deploy to a virtual CORE before a real device when possible.

The ABE is not the runtime CORE and does not need to remain powered on between
build sessions. Do not maintain a second hand-edited source tree in the VM.

## SSH forwarding

The common ctrlX WORKS setup forwards Windows `127.0.0.1:10022` to VM SSH port
22. SSH and SCP commands using that endpoint must run on Windows. A connection
to `127.0.0.1:10022` from inside the VM targets the VM itself, not the Windows
host. Confirm the configured port in ctrlX WORKS if it differs.

## Build baseline

Use the SDK setup scripts and official docs for the selected SDK/OS version.
Before Snapcraft commands in a fresh shell:

```bash
source /etc/environment
```

For a typical `core24` app, the iterative build commands are:

```bash
snapcraft pack --build-for=amd64 --destructive-mode --verbosity=verbose
snapcraft pack --build-for=arm64 --destructive-mode --verbosity=verbose
```

Choose the architecture from the target device. A virtual CORE is commonly
`amd64`; physical CORE hardware is commonly `arm64`.

## File transfer

From Windows, use the forwarded SSH endpoint to copy source into the ABE and
completed packages back out. Keep the commands project-specific and avoid
copying credentials, certificates, build caches, or unrelated home-directory
files. A build is reproducible only when the source revision and build
environment are known.

## Verification

Before deployment, inspect:

- snap name, version, architecture, base, and confinement;
- launcher and staged application files;
- package-assets manifest and schema;
- package-run/socket path for web apps;
- required plugs and slots.

On the target, verify the installed version, service state, interface
connections, Logbook or snap logs, and the expected UI/API route.

## Windows and alternate SDK VM notes

Do not conclude that packaging is impossible because `snapcraft` is not
installed on the Windows host. First check for a ctrlX WORKS-managed ABE. Keep
the Windows source, Linux build tree, and artifact directory separate, and
start the ABE launcher from its configured instance directory when the batch
file relies on `%CD%` for image or seed files.

The usual host forwarding is `127.0.0.1:10022 -> <ABE>:22`, while the local
virtual CORE commonly uses `127.0.0.1:8022` for SSH and `127.0.0.1:8740` for
Data Layer. These are different VMs and must never be confused. A successful
`Test-NetConnection` only proves that a port is open; wait for an SSH banner
and run `snapcraft --version` before synchronizing a build.

If the repository's Linux lab scripts fail on Windows because `bash.exe` has no
installed WSL distribution, inspect the ctrlX WORKS/QEMU process and forwarded
CORE ports instead of treating the shell error as proof that the virtual CORE
is down. Report that this is partial status evidence and keep the documented
virtual-core safety flow for actual lab operations.

As a secondary, public implementation reference, the
`https://github.com/vitalisAutomation/kuschke-silas-bachelor-thesis`
repository contains:

- `sdk-vm-automation`, a Windows batch-driven SDK VM provisioner;
- `crosscompiling/build-snap-amd64.sh` and `build-snap-arm64.sh`, which select
  the CMake GCC build kit for each target architecture;
- example snap projects and a deployment automation area.

This material is useful for understanding one working SDK-VM approach, but it
is not a replacement for the live official SDK docs or the configured ABE.
Treat downloaded QEMU binaries, VM images, SSH keys, proxy settings, and
installation scripts as local infrastructure, not as application source or
skill content.
