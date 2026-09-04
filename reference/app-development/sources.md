# App Development Sources

Use this page before making ctrlX app packaging, SDK, Data Layer, or package-manifest assumptions.

## Source Priority

1. Live official online sources.
2. This repository's reference notes and recipes.
3. Offline fallback notes from previous local skills or downloaded SDK copies.
4. Direct verification in an app build environment, virtual ctrlX OS, or real device, respecting the device-change policy.

## Official Online Sources

- SDK documentation: https://boschrexroth.github.io/ctrlx-automation-sdk/4.6.0/
- SDK GitHub repository: https://github.com/boschrexroth/ctrlx-automation-sdk
- SDK releases and downloadable Debian packages: https://github.com/boschrexroth/ctrlx-automation-sdk/releases
- SDK setup overview: https://boschrexroth.github.io/ctrlx-automation-sdk/4.6.0/setup_overview.html
- Package Assets: https://boschrexroth.github.io/ctrlx-automation-sdk/4.6.0/package-assets.html
- App Developer Guideline: https://boschrexroth.github.io/ctrlx-automation-sdk/4.6.0/appdevguide.html
- Persisting App Data: https://boschrexroth.github.io/ctrlx-automation-sdk/4.6.0/persistdata.html
- Persisting Device Settings: https://boschrexroth.github.io/ctrlx-automation-sdk/4.6.0/persist-device-settings.html
- License Management: https://boschrexroth.github.io/ctrlx-automation-sdk/4.6.0/licensing.html
- Data Layer documentation: https://boschrexroth.github.io/ctrlx-automation-sdk/4.6.0/datalayer.html
- Current Python webserver sample: https://github.com/boschrexroth/ctrlx-automation-sdk/tree/main/samples-python/webserver
- Python webserver `snapcraft.yaml`: https://github.com/boschrexroth/ctrlx-automation-sdk/blob/main/samples-python/webserver/snap/snapcraft.yaml
- Python webserver AMD64 build script: https://github.com/boschrexroth/ctrlx-automation-sdk/blob/main/samples-python/webserver/build-snap-amd64.sh
- Python webserver ARM64 build script: https://github.com/boschrexroth/ctrlx-automation-sdk/blob/main/samples-python/webserver/build-snap-arm64.sh
- Snapcraft YAML reference: https://snapcraft.io/docs/snapcraft-yaml-reference

Verification baseline for this page:

- ctrlX Automation SDK commit
  [`65228210674f5f70cd0c9ec990180d05fa3fa196`](https://github.com/boschrexroth/ctrlx-automation-sdk/tree/65228210674f5f70cd0c9ec990180d05fa3fa196).
- Official ABE builder:
  [`scripts/environment/builder/README.md`](https://github.com/boschrexroth/ctrlx-automation-sdk/blob/65228210674f5f70cd0c9ec990180d05fa3fa196/scripts/environment/builder/README.md).
- Official standalone QEMU fallback:
  [`doc/setup_qemu_ubuntu.md`](https://github.com/boschrexroth/ctrlx-automation-sdk/blob/65228210674f5f70cd0c9ec990180d05fa3fa196/doc/setup_qemu_ubuntu.md).
- Current architecture helpers:
  [`scripts/build-snap-amd64.sh`](https://github.com/boschrexroth/ctrlx-automation-sdk/blob/65228210674f5f70cd0c9ec990180d05fa3fa196/scripts/build-snap-amd64.sh)
  and
  [`scripts/build-snap-arm64.sh`](https://github.com/boschrexroth/ctrlx-automation-sdk/blob/65228210674f5f70cd0c9ec990180d05fa3fa196/scripts/build-snap-arm64.sh).
- Official ctrlX OS 4.x/Ubuntu Core 24 statement:
  [`ctrlx-automation-sdk-ros2` README](https://github.com/boschrexroth/ctrlx-automation-sdk-ros2/blob/94e6b34eaf03fd01c21541904c0bf40df022b38d/README.md).

The current 4.6 builder uses Ubuntu Server 24.04 and current samples use
`core24`. Older tagged SDK samples use earlier bases. Some files on SDK `main`
retain older setup wording, so prefer the versioned documentation, matching
builder, and closest sample as a set.

## Local Fallback Scope

Use local fallback notes for agent efficiency and troubleshooting, not as authority over the official SDK docs.

Good fallback uses:

- Remembering common `snapcraft.yaml` sections for ctrlX apps.
- Recognizing build dependency failures such as missing `libzmq3-dev`, `libsystemd-dev`, `pkg-config`, or cross compilers.
- Checking package-assets layout, reverse proxy socket paths, and content interfaces.
- Explaining common runtime checks such as `snap connections`, `snap logs`, and Logbook filtering.

Avoid fallback-only assumptions for:

- Current schema versions and field semantics.
- SDK API method names and package versions.
- Licensing API details.
- App validation, signing, store, or OEM requirements.
- Behavior that depends on a specific ctrlX OS version.

## Public Implementation Reference

The following third-party repository is useful as an implementation study, not
as product authority:

- Silas Kuschke bachelor-thesis repository, audited revision
  [`24ebf1290231005bf77eca3e6dda470a6157e2ed`](https://github.com/vitalisAutomation/kuschke-silas-bachelor-thesis/tree/24ebf1290231005bf77eca3e6dda470a6157e2ed)
  (2026-08-26), MIT licensed.
- Windows VM entry point:
  [`sdk-vm-automation/install_sdk.bat`](https://github.com/vitalisAutomation/kuschke-silas-bachelor-thesis/blob/24ebf1290231005bf77eca3e6dda470a6157e2ed/sdk-vm-automation/install_sdk.bat).
- Architecture wrappers:
  [`build-snap-amd64.sh`](https://github.com/vitalisAutomation/kuschke-silas-bachelor-thesis/blob/24ebf1290231005bf77eca3e6dda470a6157e2ed/build-snap-amd64.sh)
  and
  [`build-snap-arm64.sh`](https://github.com/vitalisAutomation/kuschke-silas-bachelor-thesis/blob/24ebf1290231005bf77eca3e6dda470a6157e2ed/build-snap-arm64.sh).
- Upstream license:
  [`LICENSE`](https://github.com/vitalisAutomation/kuschke-silas-bachelor-thesis/blob/24ebf1290231005bf77eca3e6dda470a6157e2ed/LICENSE).

Before reusing a third-party setup, verify it against the current official SDK:

1. Pin the Ubuntu image checksum, SDK revision, Snapcraft version, and tool
   downloads.
2. Confirm target ctrlX OS release, snap base, architecture, and `platforms`.
3. Review proxy handling, TLS verification, credentials, SSH host-key policy,
   privilege escalation, and generated files.
4. Compare the build command and toolchain with the closest official sample.
5. Keep VM images, generated ISOs, snaps, keys, certificates, logs, proxy files,
   and machine-specific paths out of the skill and source control.
