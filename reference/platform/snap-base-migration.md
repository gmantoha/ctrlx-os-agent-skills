# Snap Base Migration: core22 to core24

## How It Works

When `core24` is installed as the new base snap, both `core22` and `core24` remain installed simultaneously. The old `core22` is not removed automatically.

To remove `core22`, run a remodel task after all snaps have migrated:

```
POST /package-manager/api/v1/tasks
{"action":"remodel"}
```

## Remodel Preconditions

Remodel fails if any installed snap still has `base: core22`. This includes both system snaps and third-party apps. Check with `GET /package-manager/api/v1/packages` and look for any entry with `base: core22` or for `core22` in the package list.

## Reboots During Migration

During the core22→core24 migration, `rexroth-deviceadmin` and `rexroth-automationcore` will reboot the device even if their `updateBehavior` field suggests otherwise. Account for connection loss after installing these snaps.

## Checking for Old Core

```
GET /package-manager/api/v1/packages
```

Look for a package named `core22` in the response. If present, the remodel has not yet run or cannot run.
