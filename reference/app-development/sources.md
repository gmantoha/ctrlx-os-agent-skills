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
- Snapcraft YAML reference: https://snapcraft.io/docs/snapcraft-yaml-reference

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
