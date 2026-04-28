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
- `reference/app-development/package-assets.md`
- `reference/app-development/datalayer-apps.md`
- `reference/app-development/troubleshooting.md`

## Standard Flow

1. Identify language, runtime, architecture, and required ctrlX integration points.
2. Check the live SDK docs and closest official SDK sample.
3. Check local app-development notes for concise fallback and troubleshooting guidance.
4. Check SDK and build dependency assumptions.
5. Make the smallest build/package change that satisfies the goal.
6. Build locally or in the ctrlX App Build Environment.
7. Deploy to a virtual target when possible before a real device.
8. Verify service state, logs, UI/API entrypoints, interface connections, and Data Layer nodes if applicable.

## Useful Recipes

- `recipes/app-build/minimal-web-app.md`
- `recipes/app-build/datalayer-provider.md`
