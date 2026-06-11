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
- If axes have `ignore-axisprofile=true` saved, the standard `scheduler/admin/state` OPERATING switch works directly — no reboot needed
- The save command requires `phase:"SAVE"` in the body


