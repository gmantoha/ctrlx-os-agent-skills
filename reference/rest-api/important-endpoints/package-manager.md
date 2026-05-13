# Package Manager API

Base path: `/package-manager/api/v1/`

## Endpoints

**`GET /packages`**
Returns all installed snaps. Each entry includes `name`, `release.version`, `base`, and `updateBehavior`. Use this to check current versions and poll for installation completion.

**`POST /packages`**
Upload a `.app` file. Request must be `multipart/form-data` with:
- `file` — binary snap content
- `update=true` — string, required if the snap is already installed

Returns 202 + `Location` header on success. Returns 400 if `update=true` is omitted and the snap is already installed.

**Prerequisite:** Device must be in `SERVICE` state. Returns `HTTP 409 – system must be in state 'SERVICE'` otherwise. Switch state first via `PUT /automation/api/v2/nodes/scheduler%2Fadmin%2Fstate`.

**Always use `curl.exe -k`** for uploads — works for any file size and handles self-signed certs on both PS 5.1 and PS 7+. `Invoke-RestMethod` fails on large files and its SSL bypass only works on PS 5.1.

**`GET /tasks/{id}`**
Returns task status. The `state` field returns `null` even when installation is at 100% and complete. Do not use `state` for completion detection — poll `GET /packages` and compare `release.version` instead.

**`DELETE /auth/token`** (`/identity-manager/api/v2/auth/token`)
Closes the current session. **Always call this before requesting a new token.** The device enforces a session limit; repeated logins without logout cause `HTTP 400 – Too many sessions` (mainDiagnosisCode `080E0200`). Also call at script exit to release the final session.

**`POST /tasks`**
Body `{"action":"remodel"}` removes the obsolete `core22` snap after a base migration to `core24`. Fails if any snap still has `base: core22`.

## Update Behavior by Package

| Package | `updateBehavior` | Effect |
|---|---|---|
| `snapd`, `core24`, `rexroth-setup`, `rexroth-solutions`, `rexroth-version-guard` | `none` | No forced reboot |
| `rexroth-deviceadmin` | `logout` | Causes reboot |
| `rexroth-arch0X-hw` (gadget) | `requiredReboot` | Reboot required |
| `rexroth-arch0X-kernel` | `forcedReboot` | Forced reboot |

Note: during core22→core24 migration, `rexroth-deviceadmin` and `rexroth-automationcore` may reboot the device regardless of the listed behavior.
