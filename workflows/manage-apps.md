# Manage Apps

Use this workflow for installing, updating, removing, inspecting, and troubleshooting ctrlX apps and app services.

## Check First

- Target device type and mode.
- Installed app version and snap name.
- Relevant services and logs.
- Whether the app package is available locally or must be obtained elsewhere.

## Rules

- Do not assume app packages are available in this repository.
- App lifecycle changes on real devices require confirmation before execution.
- Verify service state and logs after changes.

## Standard Flow

1. Inspect installed snaps and service state.
2. Confirm operation mode requirements.
3. Propose exact install, update, remove, restart, or rollback action.
4. Apply only after confirmation for real devices.
5. Verify app version, service status, logs, and UI/API availability.
