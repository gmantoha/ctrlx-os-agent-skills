# Windows QEMU SDK VM

Use this recipe only when a matching ctrlX WORKS App Build Environment and the
official SDK standalone QEMU launchers are unsuitable, or a project explicitly
needs to evaluate this self-contained Windows/QEMU implementation. The source
is a public student implementation, not Bosch Rexroth product documentation or
a supported ABE replacement.

## Audited upstream

- Repository:
  https://github.com/vitalisAutomation/kuschke-silas-bachelor-thesis
- Revision:
  [`24ebf1290231005bf77eca3e6dda470a6157e2ed`](https://github.com/vitalisAutomation/kuschke-silas-bachelor-thesis/tree/24ebf1290231005bf77eca3e6dda470a6157e2ed),
  authored and committed 2026-08-26T11:55:33+02:00
- Entry point:
  [`sdk-vm-automation/install_sdk.bat`](https://github.com/vitalisAutomation/kuschke-silas-bachelor-thesis/blob/24ebf1290231005bf77eca3e6dda470a6157e2ed/sdk-vm-automation/install_sdk.bat)
- License: MIT; link to the upstream files rather than vendoring the
  implementation.

## What the example automates

The batch file runs from an otherwise empty Windows project directory and:

1. Checks for a project-local QEMU, VS Code, and selected extensions. Missing
   installations can trigger a UAC elevation request.
2. Downloads an AMD64 Ubuntu Minimal 22.04 (Jammy) or 24.04 (Noble) cloud
   image, depending on the menu selection.
3. Generates NoCloud files under `instances/cidata` and a `seed.iso`. Cloud-Init
   creates the VM user, configures networking and an optional proxy, installs
   build dependencies, and invokes scripts from the public ctrlX Automation SDK.
4. Starts QEMU with Windows Hypervisor Platform acceleration and forwards host
   TCP port `11022` to guest SSH port 22.
5. Creates the Windows SSH alias `ctrlx-sdk-vm`, waits for Cloud-Init, opens
   `/home/boschrexroth` through VS Code Remote-SSH, and installs remote
   extensions.

The audited script hard-codes a 60 GB virtual disk, 16 GB RAM, and 12 virtual
CPUs. Treat these as implementation defaults, not ctrlX requirements. Confirm
that Windows Hypervisor Platform is available and size the VM for the host.

## Terminology and release caveat

The script labels its choices "Core 22" and "Core 24", but its download URLs are
for classic Ubuntu Minimal cloud images, not Ubuntu Core images. Separately,
`core22` and `core24` are snap bases. Do not infer the target snap base from the
build-host label.

The menu maps ctrlX OS 1.x to a Core 22 fallback, 2.x/3.x to Core 22, and 4.x
to Core 24. This records the implementation's selector; it is not a
compatibility guarantee. Verify the target ctrlX OS release, snap base, SDK
release, and closest official sample before provisioning or building.

Official versioned evidence confirms the progression from older SDK samples
using `core20` or `core22` to the current 4.6 ABE on Ubuntu Server 24.04 with
`core24` samples; official ctrlX OS 4.x material explicitly identifies Ubuntu
Core 24. Do not turn that history into an unqualified 1.x/2.x/3.x mapping.

## Reproducibility and security review

Do not run the audited batch file unchanged in a trusted environment. At the
recorded revision it:

- downloads mutable or unpinned installers, cloud images, and the SDK `main`
  branch without a complete checksum/pinning policy;
- uses `curl -k`, `wget --no-check-certificate`, and disables Git TLS
  verification during provisioning;
- creates a known VM password, enables SSH password authentication,
  configures passwordless sudo, and disables SSH host-key checking;
- writes generated keys, Cloud-Init data, VM images, logs, and optional
  `proxy.env` data below or beside the project directory;
- assumes admin rights for missing host dependencies and project-local QEMU;
- reports the custom company-proxy path as untested in its 2026-08-20 README
  status note.

Before use, fork or wrap the implementation so downloads and the SDK are
pinned and verified, TLS and SSH host verification stay enabled, password
login is disabled, secrets are supplied outside source control, and generated
artifacts are ignored. Review every generated Cloud-Init file before boot.

Never copy VM images, `seed.iso`, private/public keys, proxy data, generated
snaps, certificates, logs, or developer-specific paths into this skill.

## Build and verify

After first boot, record the actual environment:

```bash
cloud-init status --wait
lsb_release -ds
snapcraft --version
git -C ~/ctrlx-automation-sdk rev-parse HEAD
```

The upstream root build wrappers are CMake-project-specific. They remove prior
build output, use an out-of-tree `build` directory, enable `BUILD_SNAP`, and
select either `GCC x86_64-linux-gnu` or `GCC aarch64-linux-gnu` before
`make install`. Preserve the general rule--clean between target architectures
and select the toolchain explicitly--but use the closest current official SDK
sample's command and `snapcraft.yaml` for the app being built.

Before accepting the environment, build one official sample for the target
architecture and inspect its snap metadata. Record the cloud-image checksum,
provisioning revision, SDK commit, Snapcraft version, snap base, build
architecture, and target architecture with the artifact.
