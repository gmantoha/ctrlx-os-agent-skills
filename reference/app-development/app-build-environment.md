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

The current SDK sample scripts clean first and build one target architecture:

```bash
snapcraft clean
snapcraft pack --build-for=<amd64-or-arm64> --verbosity=verbose
```

Choose the architecture from the target device. A virtual CORE is commonly
`amd64`; physical CORE hardware is commonly `arm64`. Verify the target, snap
base, and `platforms` declaration against the selected ctrlX OS release and
closest official SDK sample. Use `--destructive-mode` only as a deliberate
fallback outside the normal ABE build flow.

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
