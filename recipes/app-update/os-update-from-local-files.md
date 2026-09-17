# OS Update from Local .app Files

Upgrading ctrlX CORE / Rexroth IPC system apps from locally downloaded `.app` files
(e.g. 3.x → 4.x, or 4.4 → 4.6.5).

> Verified 2026-09-17 on a Rexroth IPC (arch02, amd64): ctrlX OS 4.4 → 4.6.5 via REST,
> incl. removal of optional apps. Linux implementation: [`update_os_from_apps.py`](update_os_from_apps.py).

## .app File Format

A `.app` file is a TAR archive. Each snap is located at:

```
public/snaps/{arch}/release/{snap-name}-{version}.snap   (+ .assert)
```

- `{arch}` is the CPU architecture (`amd64`, `arm64`), **not** the hardware family.
  Most system apps contain both; the device picks the right one.
- Hardware-specific apps contain only one arch: `Hardware Support X7-*.app` →
  `rexroth-arch02-hw`, `Linux Kernel X7-*.app` → `rexroth-arch02-kernel` (amd64 only).
- Read TAR headers to extract snap name and version without unpacking. Parse the filename:
  split by `-`; the version starts at the first segment that begins with a digit
  (`rexroth-arch02-kernel-6.12.40-ctrlx-59.2` → version `6.12.40-ctrlx-59.2`).

## Which hardware files? (X3 / X5 / X7 / IPC)

- Compare with the installed gadget/kernel: `GET /package-manager/api/v1/packages` →
  `rexroth-arch0X-hw` (`appType: gadget`) and `rexroth-arch0X-kernel` (`appType: kernel`).
- The snap name inside the `.app` must match the installed one. Never mix architectures.
- **Rexroth IPC (PRx) uses arch02** → the files labelled "X7" (`Hardware Support X7`,
  `Linux Kernel X7`) are correct for it. Bosch ships them in a folder like
  `X5_X7_IPC_System_Apps_<ver>`.

## Upload API

- Endpoint: `POST /package-manager/api/v1/packages`
- Content type: `multipart/form-data`
- Fields: `file` (the `.app` file as downloaded; do not extract the inner `.snap`) + `update=true`
- Returns HTTP 202 with a `Location` header — **relative**: `/tasks/<id>`
  (prefix with `/package-manager/api/v1`). `POST /tasks` (uninstall) returns the full path instead.
- **Use `curl` / `curl.exe` for files >10 MB.** PowerShell `Invoke-WebRequest` / `Invoke-RestMethod`
  reset the connection on large uploads. Python `urllib` is fine for JSON calls, use curl for the upload.

## Uninstall optional apps

```
POST /package-manager/api/v1/tasks
{"action":"uninstall","parameters":{"id":"snap_<name>"}}
```

- Returns 201 + full `Location`. Done when the snap is gone from `GET /packages`.
- Dependencies: remove `ctrlx-display` before `ubuntu-frame` and `mesa-2404`.
- Observed durations: 10 s – 2 min per app.
- Required system apps have `"required": true` in `GET /packages` — never remove those.

## Order

Install system apps one at a time in this order (release notes 4.6.5, §"Updating the apps on ctrlX CORE":
snapd → core24 → Device Admin are mandatory first; the rest was verified in this order):

| # | Snap | Observed on IPC (4.4 → 4.6.5) |
|---|---|---|
| 1 | `snapd` | ~2 min, no reboot, **device state flipped back to OPERATING** |
| 2 | `core24` | ~3 min, **reboot** (~2 min offline) |
| 3 | `rexroth-deviceadmin` | ~1 min, web/API gone ~50 s |
| 4 | `rexroth-automationcore` | ~40 s |
| 5 | `rexroth-arch0X-hw` | ~4 min, **reboot** |
| 6 | `rexroth-arch0X-kernel` | ~4 min, **reboot** |
| 7 | `rexroth-setup` | ~30 s |
| 8 | `rexroth-solutions` | ~30 s |
| 9 | `rexroth-version-guard` | ~10 s |

Total ≈ 15 min for the system apps after uploads (direct Gigabit link). Non-system apps afterwards, any order.

## Rules (learned on a real device)

1. **Reuse one token for the whole run.** Re-login only on HTTP 401.
   Logging in for every poll exhausts the per-user session limit:
   `HTTP 400 {"mainDiagnosisCode":"080E0200","detailedDiagnosisCode":"0C7A0202","dynamicDescription":"Too many sessions"}`.
   Recovery: close sessions in the web UI (needs an existing login) or reboot the device.
   Do **not** treat this 400 as "device offline".
2. **Wait for an idle task queue before every step**: `GET /package-manager/api/v1/tasks` must have no
   `pending`/`running` entry. Otherwise a restarted script re-uploads a snap that is still installing.
3. **Completion = `release.version` equals the target.** Task `state` can be `null`/stale; still abort on `failed`.
4. **Connection loss = reboot.** Keep polling (allow ≥ 40 min), drop the token after >60 s offline, log in again.
5. **Re-check the device state after snapd/reboots.** It may be back in OPERATING; switch to SERVICE again
   if real-time apps (PLC, Motion, EtherCAT, PROFINET) are installed. Without real-time apps, OPERATING is allowed
   per release notes.
6. **Remodel only if `core22` is still installed.** If only `core24` is present, skip it.
7. Network config (static IPs) survives the update.

## Remodel

After all snaps are confirmed on `core24` and `core22` is still installed:

```
POST /package-manager/api/v1/tasks
{"action":"remodel"}
```

Fails if any installed snap still has `base: core22`.

## Device Mode

- Read: `GET /automation/api/v2/nodes/scheduler/admin/state`
- Switch: `PUT /automation/api/v2/nodes/scheduler/admin/state` with `{"type":"object","value":{"state":"SERVICE"}}`
- Restore the original mode after all steps complete.

## Implementations

- Linux/macOS: [`update_os_from_apps.py`](update_os_from_apps.py) — TAR parsing, order, uninstall, idle-wait,
  single token, reboot recovery. Start with `--dry-run` to print the plan.
- Windows: `Update-ctrlXCore.ps1` (TAR parsing, skip checks, upload via `curl.exe`, polling, reboot recovery,
  remodel, mode restore).
