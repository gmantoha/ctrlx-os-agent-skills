# Use WebDAV

Use this workflow when inspecting or transferring app data through the Solutions app WebDAV endpoint.

## Rules

- Check write protection before assuming a directory is modifiable.
- Treat uploads, edits, deletes, and overwrites on real devices as persistent changes requiring confirmation.
- Prefer WebDAV for app data access only when the app exposes suitable directories there.

## Standard Flow

1. Identify the target app and desired file operation.
2. Confirm WebDAV endpoint, credentials, and path.
3. Inspect directory contents and permissions first.
4. Propose any write operation before executing on real devices.
5. Verify transferred files and app behavior after changes.
