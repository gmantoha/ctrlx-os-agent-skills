# Virtual Lab Guidance

Use this folder when verifying workflows against a local virtual ctrlX target.

Rules:

- do not expect the VM image to be present in git
- keep runtime artifacts under `assets/`
- document expected ports and access URLs in local environment files
- distinguish clearly between behavior verified on virtual and real devices

Allowed documented defaults:

- Web UI: `boschrexroth` / `boschrexroth`
- SSH: document only if the lab setup intentionally uses a public default
