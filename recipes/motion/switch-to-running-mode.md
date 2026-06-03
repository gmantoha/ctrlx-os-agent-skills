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

---

## Problem (Workaround for axis profile errors)
`POST motion/cmd/opstate` with `"Running"` fails with error `0xf0100001` when a real DRIVEAXS axis has an axis profile assigned but no physical drive is connected.

## Working Solution

### Step 1 — Set ignore-axisprofile on each axis
```
PUT https://<ip>/automation/api/v2/nodes/motion/axs/<axisname>/cfg/functions/ignore-axisprofile
Body: {"type":"bool8","value":true}
```

### Step 2 — Save the axis configuration
```
POST https://<ip>/automation/api/v2/nodes/motion/axs/<axisname>/cfg/save
Body: {"type":"object","value":{"configurationPath":"","id":"save-axis","phase":"SAVE"}}
Expected response: {"type":"string","value":"Saving finished."}
```

### Step 3 — Reboot the device
```
POST https://<ip>/system/api/v1/tasks
Body: {"action":"reboot"}
Expected response: {"id":"...","state":"pending","action":"reboot","parameters":{"components":{}}}
```

After reboot (~2 minutes), the motion app boots directly into **Running** mode with the saved config applied.

### Verify
```
GET https://<ip>/automation/api/v2/nodes/motion/state/opstate
Expected: {"type":"string","value":"Running"}
```

## Why direct mode switch fails (0xf0100001)
- Axis is `DRIVEAXS` with an `axisProfileName` assigned (e.g. `"Profile_1"`)
- No EtherCAT drive is connected → profile cannot be resolved
- Setting `ignore-axisprofile=true` in memory during Configuration mode is **not sufficient**
- The config must be **persisted** (via cfg/save) and then loaded on a **fresh boot**

## Why other approaches fail
- `POST motion/cmd/opstate {"value":"Running"}` alone → `0xf0100001` if drive not connected
- Setting `motion/cfg/function.ignoreAxisProfiles=true` globally without saving → no effect
- Package manager has no restart endpoint for individual snaps
- SSH was not accessible (port refused)

## Notes
- `motion/cmd/opstate` POST IS the correct Data Layer command (nodeClass=Program, operation=create)
- Error `0xf010000c` = unrecognized opstate value; `0xf0100001` = valid value but transition blocked
- The save command requires `phase:"SAVE"` in the body


