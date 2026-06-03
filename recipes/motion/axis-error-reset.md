# Axis Error Reset

Verified on ctrlX OS 4.6, Motion App, Axis_1 — 2026-06-03.

## PLCopen Error State

When a motion error occurs (e.g. velocity limit exceeded, drive fault), the axis enters:

```
PLCopen state: ERRORSTOP
```

The axis is stopped and locked. No moves are possible until reset.

---

## Reset the Error

```http
POST /automation/api/v2/nodes/motion/axs/{axisName}/cmd/reset
Content-Type: application/json

null
```

Body is `null` — no payload required.

Expected: axis transitions `ERRORSTOP → STANDSTILL` within ~1–2 s.

**PowerShell:**
```powershell
Invoke-RestMethod -Uri "https://192.168.1.1/automation/api/v2/nodes/motion/axs/Axis_1/cmd/reset" `
  -Method POST -Headers $h
```

---

## Read Error Details (before reset)

```http
GET /automation/api/v2/nodes/motion/axs/{axisName}/state/diag-info
```

Response contains:
- `mainDiagCode` — primary error code (0 = no error)
- `detailedDiagCode` — detailed sub-code
- `source` — component that raised the error
- `firstMainDiagCode` / `firstSource` — root cause (if cascaded)

When no error: all codes = 0, source = `"NOT_INIT||0"`

---

## Also useful

```http
GET /automation/api/v2/nodes/motion/axs/{axisName}/state/err-level
```

Returns current error severity level.

---

## Observed State Sequences (live captures)

**Position limit exceeded:**
```
STANDSTILL  60°   ← commanded 90° with posMax = 45°
ERRORSTOP   60°   ← limit hit immediately (never moved)
DISABLED    60°   ← after cmd/reset (axis loses power, re-enable needed)
```

**Velocity limit exceeded (from user UI):**
```
STANDSTILL        ← normal
ERRORSTOP         ← velocity limit hit during motion
STANDSTILL        ← after cmd/reset (~4 s)
```

> Note: after `cmd/reset` the axis may return to `DISABLED` instead of `STANDSTILL` — power ON again if needed.

## Known Error Codes

| mainDiagCode | detailedDiagCode | Meaning |
|---|---|---|
| `0x090F2006` | `0x0C560107` | Position software limit exceeded |

## Why errors occur (common causes)

| Cause | Symptom |
|---|---|
| Position limit exceeded | `ERRORSTOP` immediately on move command |
| Velocity limit exceeded | `ERRORSTOP` during motion |
| Drive not ready | `ERRORSTOP` on power-on attempt |
| E-Stop active | `ERRORSTOP`, `err-level` = critical |
