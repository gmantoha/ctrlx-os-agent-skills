# ctrlX App Build Environments

The official ctrlX App Build Environment (ABE) is a Linux VM managed by ctrlX
WORKS for building ctrlX snaps with the official SDK and Snapcraft tools.

## Choose the environment

Prefer the ctrlX WORKS ABE when it is available and matches the target SDK and
ctrlX OS release. It is the supported baseline used by the official SDK
documentation and samples.

The official SDK also documents standalone QEMU launchers for hosts without
ctrlX WORKS. Use those version-matched scripts before third-party automation.
The current official ABE itself is an Ubuntu Server QEMU VM provisioned with
Cloud-Init, so QEMU and Cloud-Init alone do not distinguish an official ABE.

Use a separately maintained VM only when the official options are unsuitable
or a reproducible, self-contained Windows setup is a project requirement. The
[Silas Windows/QEMU recipe](../../recipes/app-build/windows-qemu-sdk-vm.md)
documents one public implementation example. It provisions an Ubuntu Minimal
cloud image and installs the public SDK; its automation, sizing, networking,
and security choices are not a Bosch compatibility statement or baseline.

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

Do not infer snap compatibility from the VM's Ubuntu release alone. `core22`
and `core24` are snap bases, while Ubuntu 22.04 and 24.04 are possible build
hosts. Verify the target ctrlX OS release, snap base, SDK revision, and sample
together.

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

For a custom VM, also record the base cloud-image release and checksum, the SDK
commit or release, provisioning-script revision, Snapcraft version, and target
architecture. A setup that downloads `main` or latest installers is convenient
but not reproducible until those inputs are pinned.
