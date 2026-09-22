# Uninstall and verify a ctrlX app

Use this recipe when removing an installed snap from a real ctrlX CORE. It
complements `workflows/manage-apps.md` and does not replace the required
confirmation before changing a real device.

## Before removal

- Identify the exact package `name`/`id` and version with
  `GET /package-manager/api/v1/packages`.
- Distinguish packages by their snap identity, not only by a display title.
  Two apps can both be presented as a visualizer while having different snap
  names and versions.
- Record the current scheduler state and any route or service that must remain
  available.
- Obtain explicit confirmation before switching mode or uninstalling.

## Start the uninstall

App management normally requires SERVICE mode. Confirm that the machine is in
a safe state, switch to SERVICE, and start exactly one uninstall through the
CORE Web UI or the documented Package Manager API. Record the returned task ID.

Do not submit a second uninstall request when the first task is still running.
Uninstall is asynchronous and can spend several minutes at an intermediate
progress value while Device Admin:

1. stops the snap service;
2. removes the snap;
3. removes package-assets and license-manager registrations; and
4. updates the application catalog.

The task can remain at values such as 33% or 50% during these stages. A
percentage alone is not completion evidence. Poll
`GET /package-manager/api/v1/tasks` periodically and wait for the task
`state` to become `done` with a successful result.

## Verify and restore mode

Use all of the following as completion evidence:

- the uninstall task is `done` and reports success;
- `GET /package-manager/api/v1/packages` no longer returns the removed snap;
- the intended replacement or unrelated apps are still installed and enabled;
- the logbook shows the removed app service stopping and package-assets cleanup;
- no new error indicates that Device Admin or snapd is still processing the
  removal.

Only after the task is complete, restore the scheduler's original state,
normally OPERATING. Wait for the transition to finish and verify the
replacement app's route and APIs. Do not leave the device in SERVICE merely
because the uninstall task was slow.

If progress and log activity stop for an extended period, inspect the task and
Device Admin/snapd logbook entries before taking another action. Never force a
second removal, restart, or reboot as a substitute for diagnosing the active
task.
