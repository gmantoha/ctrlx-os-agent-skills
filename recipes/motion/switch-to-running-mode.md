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
- **`motion/axs/{name}/cfg/ignore-axisprofile` does not exist** (`DL_INVALID_ADDRESS`). The existing node is `motion/axs/{name}/cfg/axisprofile` (type: `string`, default: `""`); there is no boolean ignore flag. On a virtual controller without configured drives, switching to Running after axis creation is not possible — Motion falls back from Booting to Configuration (verified 2026-06-12, ctrlX OS 4.6 virtual).
- The save command requires `phase:"SAVE"` in the body


