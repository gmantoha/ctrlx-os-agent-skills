# Manage Apps

Use this workflow for installing, updating, removing, inspecting, and troubleshooting ctrlX apps and app services.

## Check First

- Target device type and mode.
- Installed app version and snap name.
- Relevant services and logs.
- Whether the app package is available locally or must be obtained elsewhere.

## Local App Packages

App packages for version 4.6.0 are available locally under:

```
labs/app-packages/DC_App_Paket_4.6.0/          ← user apps
labs/app-packages/DC_App_Paket_4.6.0/SYSTEM_APPS/   ← system apps
```

Note: `.app` files are git-ignored. Check whether the folder is populated before assuming packages are present.

Release notes for all 4.6.0 apps are in `reference/docs/release-notes/4.6.0/EN/` and can be read to determine what changed in a given version.

## Rules

- Check `labs/app-packages/` before assuming a package must be downloaded.
- App lifecycle changes on real devices require confirmation before execution.
- Verify service state and logs after changes.

## Standard Flow

1. Inspect installed snaps and service state.
2. Confirm operation mode requirements.
3. Propose exact install, update, remove, restart, or rollback action.
4. Apply only after confirmation for real devices.
5. Verify app version, service status, logs, and UI/API availability.
