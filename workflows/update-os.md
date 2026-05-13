# Update ctrlX OS from Local .app Files

Use this workflow when upgrading a ctrlX CORE from OS 3.x to 4.x using `.app` files downloaded locally from Bosch Rexroth.

## Check First

- Device must be in **SERVICE** mode before installing any packages.
- Note the current mode so it can be restored after the update.
- Confirm device architecture: X3 = `arch01`, X7 = `arch02`. Never mix architecture files.
- Check installed snap versions via `GET /package-manager/api/v1/packages` to skip already-updated snaps.

## Rules

- Never install snaps built for a different architecture.
- Follow the mandatory system snap order — do not skip or reorder.
- Poll `GET /package-manager/api/v1/packages` for completion. Do not rely on task `state` — it returns `null` even when installation is complete.
- Run the remodel task only after all snaps are on the `core24` base.

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

See [recipes/app-update/os-update-from-local-files.md](../recipes/app-update/os-update-from-local-files.md) for the full playbook.
