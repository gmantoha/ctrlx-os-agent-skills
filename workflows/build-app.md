# Build App

Use this workflow for creating, packaging, deploying, and debugging ctrlX apps.

## Source Policy

Use live official sources as the primary source of truth for app-building work:

- `reference/app-development/sources.md`
- SDK docs: https://boschrexroth.github.io/ctrlx-automation-sdk/4.6.0/
- SDK GitHub repository: https://github.com/boschrexroth/ctrlx-automation-sdk

Use this repository's app-development notes as secondary guidance and offline fallback only. If local notes conflict with live SDK docs, follow the live SDK docs and mention the discrepancy.

## Focus Areas

- ctrlX Automation SDK usage.
- `snapcraft.yaml` and snap packaging.
- Data Layer integration.
- Package manifests and app metadata.
- Deployment to virtual or real ctrlX targets.
- Service and log verification after deployment.

## Reference Notes

- `reference/app-development/sources.md`
- `reference/app-development/snap-packaging.md`
- `reference/app-development/app-build-environment.md`
- `reference/app-development/package-assets.md`
- `reference/app-development/datalayer-apps.md`
- `reference/app-development/troubleshooting.md`

## Standard Flow

1. Identify language, runtime, architecture, and required ctrlX integration points.
2. Check the live SDK docs and closest official SDK sample.
3. Select the build environment: prefer the matching ctrlX WORKS ABE; use the
   official SDK standalone QEMU launcher when WORKS is unavailable; consider
   the audited third-party implementation only when its tradeoffs are
   acceptable.
4. Check local app-development notes for concise fallback and troubleshooting guidance.
5. Check SDK and build dependency assumptions.
6. Make the smallest build/package change that satisfies the goal.
7. Build with the closest official sample's architecture script pattern.
8. Deploy to a virtual target when possible before a real device.
9. Verify service state, logs, UI/API entrypoints, interface connections, and Data Layer nodes if applicable.

## Environment Decision

- **ctrlX WORKS ABE:** default for supported, release-aligned app builds.
- **Official standalone QEMU ABE:** version-matched SDK fallback when ctrlX
  WORKS is unavailable.
- **Silas Windows/QEMU/Cloud-Init VM:** optional third-party implementation
  example for a self-contained Windows host workflow. Read
  `recipes/app-build/windows-qemu-sdk-vm.md` before use.
- **Native or destructive build:** exception that must be justified and checked
  against the official sample.

Never treat a build host called "Core 22" or "Core 24" as proof that a snap
targets `core22` or `core24`. Confirm the snap base and target ctrlX OS release
independently.

## Build Preflight

Before building, verify these items together rather than treating packaging,
architecture, and ctrlX integration as separate tasks:

- The target ctrlX OS release, snap base, and target architecture agree with
  the closest current SDK sample.
- The `platforms` declaration and `--build-for` target agree. Build one required
  architecture at a time and run `snapcraft clean` before changing targets.
- Every required top-level plug or slot is attached to the intended
  `apps.<name>` entry, and no unused interface is declared.
- For current `core24` samples, use the Craft variables shown by that sample.
  The current Python webserver sample uses `CRAFT_PROJECT_NAME`, while the
  Package Assets guide still contains `SNAPCRAFT_PROJECT_NAME`; do not mix the
  two forms in one project.
- The package manifest `id`, packaged directory, proxy URL, socket binding, and
  launcher socket path resolve consistently.

After the build, inspect snap metadata and contents, validate the package
manifest JSON, and verify interfaces and the expected route on a matching
virtual target before requesting a real-device installation.

## Useful Recipes

- `recipes/app-build/profile-driven-hmi.md`
- `recipes/app-build/ctrlx-snap-build-install-loop.md`
- `recipes/app-build/windows-qemu-sdk-vm.md`
- `recipes/app-build/minimal-web-app.md`
- `recipes/app-build/datalayer-provider.md`
