# Update ctrlX OS from Local .app Files

Use this workflow when upgrading a ctrlX CORE or Rexroth IPC (e.g. OS 3.x → 4.x, 4.4 → 4.6.x) using `.app` files downloaded locally from Bosch Rexroth.

If a USB image restore is the goal instead, see [recipes/app-update/image-restore-usb-stick.md](../recipes/app-update/image-restore-usb-stick.md) (IPCs only boot the stick when flashing is started from the web UI).

## Check First

- Device must be in **SERVICE** mode before installing any packages.
- Note the current mode so it can be restored after the update.
- Confirm device architecture from the installed gadget snap: X3 = `arch01`, X5/X7/**Rexroth IPC** = `arch02` (IPC uses the files labelled "X7"). Never mix architecture files.
- Optional apps to remove: uninstall them **before** the system update (fewer dependencies, less to update).
- Check installed snap versions via `GET /package-manager/api/v1/packages` to skip already-updated snaps.

## Rules

- Never install snaps built for a different architecture.
- Follow the mandatory system snap order — do not skip or reorder.
- Poll `GET /package-manager/api/v1/packages` for completion. Do not rely on task `state` — it returns `null` even when installation is complete.
- Run the remodel task only after all snaps are on the `core24` base, and only if `core22` is still installed.
- Reuse **one** auth token for the whole run; per-request logins hit `Too many sessions` (HTTP 400, 0C7A0202).
- Before each step wait until `GET /package-manager/api/v1/tasks` has no `pending`/`running` task.
- The upload `Location` header is relative (`/tasks/<id>`) — prefix `/package-manager/api/v1`.
- Expect reboots after `core24`, hardware support and kernel; the device state may flip back to OPERATING after `snapd`.

## Standard Flow

1. Read the current device mode. Switch to SERVICE if not already in SERVICE mode.
2. For each `.app` file: read the TAR header to extract snap name and version without unpacking.
3. Install system snaps in this order:
   - `snapd`
   - `core24`
   - `rexroth-deviceadmin`
   - `rexroth-automationcore`
   - `rexroth-arch0X-hw`
   - `rexroth-arch0X-kernel`
   - `rexroth-setup`
   - `rexroth-solutions`
   - `rexroth-version-guard`
4. Install remaining (non-system) snaps in any order.
5. After all snaps are confirmed on `core24`: POST `{"action":"remodel"}` to `/package-manager/api/v1/tasks` to remove the old `core22` snap.
6. Restore the original device mode.

See [recipes/app-update/os-update-from-local-files.md](../recipes/app-update/os-update-from-local-files.md) for the full playbook and [recipes/app-update/update_os_from_apps.py](../recipes/app-update/update_os_from_apps.py) for a verified Linux implementation (`--dry-run` prints the plan).
