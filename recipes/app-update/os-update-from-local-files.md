# OS Update from Local .app Files

Upgrading ctrlX CORE from OS 3.x to 4.x using `.app` files downloaded from Bosch Rexroth.

## .app File Format

A `.app` file is a TAR archive. Each snap is located at:

```
public/snaps/{arch}/release/{snap-name}-{version}.snap
```

Read TAR headers (512 bytes per entry) to extract the snap filename without unpacking the archive. Parse the filename: split by `-`; the version starts at the first segment that begins with a digit.

## Upload API

- Endpoint: `POST /package-manager/api/v1/packages`
- Content type: `multipart/form-data`
- Fields: `file` (binary snap data) + `update=true` (string)
- Returns HTTP 202 with a `Location` header pointing to the task.
- **Use `curl.exe` on Windows for files >10 MB.** PowerShell `Invoke-WebRequest` and `Invoke-RestMethod` reset the connection on large uploads.

## Skip Check

Before uploading, compare the version parsed from the TAR header against the version returned by `GET /package-manager/api/v1/packages`. Skip the upload if `release.version` already matches the target version.

## Completion Detection

- Poll `GET /package-manager/api/v1/packages` every 5 seconds.
- A snap is complete when its `release.version` matches the target version.
- Do not use task `state` for completion — it returns `null` or `pending` even at 100% progress.

## Reboot Handling

If the connection drops during installation (device rebooting):

1. Poll `POST /identity-manager/api/v1/auth/token` (or equivalent token endpoint) until the device responds.
2. Resume version polling on `GET /packages` after reconnect.

## Remodel

After all snaps are confirmed on `core24`:

```
POST /package-manager/api/v1/tasks
{"action":"remodel"}
```

This removes the old `core22` snap. The request will fail if any installed snap still has `base: core22`.

## Device Mode

- Switch to SERVICE before installing: `PUT /automation/api/v2/nodes/scheduler%2Fadmin%2Fstate` with `{"type":"object","value":{"state":"SERVICE"}}`.
- Restore the original mode after all steps complete.

## Implementation

`Update-ctrlXCore.ps1` implements this full flow including TAR parsing, skip checks, upload via `curl.exe`, polling, reboot recovery, remodel, and mode restore.
