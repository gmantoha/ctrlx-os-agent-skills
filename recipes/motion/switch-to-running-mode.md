# Switch Motion App Between Configuration and Running Mode

## Standard Method (UI equivalent — works on ctrlX OS 4.6)

The Motion app UI uses `scheduler/admin/state` to switch modes:

### → Running Mode (OPERATING)
```
PUT https://<ip>/automation/api/v2/nodes/scheduler/admin/state
Body: {"type":"object","value":{"state":"OPERATING"}}
```

### → Configuration Mode (SETUP)
```
PUT https://<ip>/automation/api/v2/nodes/scheduler/admin/state
Body: {"type":"object","value":{"state":"SETUP"}}
```

### Read current state
```
GET https://<ip>/automation/api/v2/nodes/scheduler/admin/state
Expected: {"type":"object","value":{"state":"OPERATING"}}  or "SETUP"
```

**Verified:** 2026-06-03, ctrlX OS 4.6, discovered by intercepting motion app JS bundle (`main-ICUPBCBQ.js` → `urlAdminState = "scheduler/admin/state"`).  
**Observable effect:** `GVL_CORE.ctrlX_CORE_Status.State[3].e` (motion.core) changes OPERATING ↔ SETUP.

## Notes
- `motion/cmd/opstate` POST IS the correct Data Layer command (nodeClass=Program, operation=create)
- Error `0xf010000c` = unrecognized opstate value; `0xf0100001` = valid value but transition blocked
- `scheduler/admin/state` and `motion/state/opstate` are **independent**. `PUT OPERATING` can return `200` while Motion stays in `Configuration` indefinitely — the `200` is not proof that Motion is running. Always read `motion/state/opstate` as well.
- **`motion/state/boot-state`** → `{text, actStep, maxSteps}` (18 steps) shows exactly where Motion boot stopped. Step 5 = `"Wait for Scheduler callables (wait for RUN state)"` (scheduler still in SETUP), step 10 = `"Check for motion basic license"`, `18/18` = `"Booting finished"`. Read this before drawing any conclusion about a failed switch.
- `POST motion/cmd/opstate {"type":"string","value":"Running"}` while Motion is in `Configuration` → `500`, `0xf0100001`. Command `"Booting"` instead — note it returns `200` even when the boot afterwards fails.
- **A `DRIVEAXS` axis without a physical drive works on a virtual ctrlX CORE**: create → power ON → move, with `ignore-axisprofile = false` and without saving. Verified 2026-08-11, ctrlX OS 4.6 virtual.
- The save command requires `phase:"SAVE"` in the body


