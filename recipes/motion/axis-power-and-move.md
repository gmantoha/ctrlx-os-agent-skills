# Axis Power On and Absolute Move

Verified on ctrlX OS 4.6, Motion App, Axis_1 (rotary, modulo 360°) — 2026-06-03.

## Prerequisites & Mode Check (always do this first)

| Goal | Required mode |
|------|--------------|
| Change axis limits, type, parameters | **Configuration** |
| Power on, move, jog | **Running** |

**Always check before acting:**

```http
GET /automation/api/v2/nodes/motion/state/opstate
```

If not in the needed mode, switch via `motion-opstate-switch.md`.

- Axis PLCopen state `OUTDATED` = still in Configuration mode (can't power on)
- Axis PLCopen state `DISABLED` = Running mode, not yet powered
- Axis PLCopen state `STANDSTILL` = powered and ready to move

---

## 1. Power On Axis

```http
POST /automation/api/v2/nodes/motion/axs/{axisName}/cmd/power
Content-Type: application/json

{"type":"bool8","value":true}
```

Expected response: `{"type":"uint64","value":<cmdId>,"responseType":"create"}`

After ~1–2 s, axis PLCopen state changes: `DISABLED` → `STANDSTILL`

**Power Off:** same endpoint, `"value":false`

---

## 2. Move to Absolute Position

```http
POST /automation/api/v2/nodes/motion/axs/{axisName}/cmd/pos-abs
Content-Type: application/json

{
  "type": "object",
  "value": {
    "axsPos": 90.0,
    "buffered": false,
    "lim": {
      "vel": 100.0,
      "acc": 1.0,
      "dec": 1.0,
      "jrkAcc": 0.0,
      "jrkDec": 0.0
    }
  }
}
```

- `axsPos` — target position in degrees (or units configured on axis)
- `vel` — velocity in rpm (rotary) or mm/s (linear)
- During motion: PLCopen state = `DISCRETE_MOTION`
- On arrival: PLCopen state = `STANDSTILL`

---

## 3. Poll Axis State

```http
GET /automation/api/v2/nodes/motion/axs/{axisName}/state/opstate/plcopen
GET /automation/api/v2/nodes/motion/axs/{axisName}/state/values/actual
```

`actual.value.actualPos` — current position in degrees

---

## Why `{"drive":{"enable":true}}` Fails

The Data Layer node `cmd/power` expects a scalar `bool8`, not an object. Passing `{"drive":{"enable":true}}` returns `DL_TYPE_MISMATCH: unknown field: drive`.
