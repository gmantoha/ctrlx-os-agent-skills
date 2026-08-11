# Axis Create, Configure, Delete

Verified on ctrlX OS 4.6, Motion App — 2026-06-03.
Must be in **Configuration** mode for all operations.

---

## Create Axis

```http
POST /automation/api/v2/nodes/motion/axs
Content-Type: application/json

{"type":"string","value":"Axis_4"}
```

Response: `{"type":"string","value":"Axis_4","responseType":"create"}`

---

## Configure Properties (type, modulo)

```http
PUT /automation/api/v2/nodes/motion/axs/{axisName}/cfg/properties
Content-Type: application/json

{
  "type": "object",
  "value": {
    "axsType": "LINEAR",
    "modulo": false,
    "moduloValue": 360.0,
    "axsCategory": {"axsCategory": "DRIVEAXS"},
    "activated": true
  }
}
```

- `axsType`: `"LINEAR"` or `"ROTATIONAL"` (⚠️ not `"ROTARY"` — rejected on ctrlX OS 4.6)
- `modulo`: `true` for modulo axes (e.g. rotary 0–360°)
- `axsCategory`: `"DRIVEAXS"` (real drive) or `"VIRTUAL"` (no hardware)

---

## Configure Limits

```http
PUT /automation/api/v2/nodes/motion/axs/{axisName}/cfg/lim
Content-Type: application/json

{
  "type": "object",
  "value": {
    "posMin": -1000.0,
    "posMax": 1000.0,
    "velPos": 6000.0,
    "velNeg": 6000.0,
    "acc": 2.0,
    "dec": 2.0,
    "jrkAcc": 0.0,
    "jrkDec": 0.0,
    "trqPos": 10.0,
    "trqNeg": 10.0
  }
}
```

Units depend on axis type: `mm`/`mm/min` for LINEAR, `deg`/`rpm` for ROTARY.

---

## Delete Axis

```http
DELETE /automation/api/v2/nodes/motion/axs/{axisName}
```

Response: `""` (empty string = success)

---

## Full PowerShell Example

```powershell
$h = @{ Authorization = "Bearer $token"; "Content-Type" = "application/json" }
$base = "https://192.168.1.1/automation/api/v2/nodes"

# Create
Invoke-RestMethod "$base/motion/axs" -Method POST -Headers $h -Body '{"type":"string","value":"Axis_4"}'

# Set type
$props = '{"type":"object","value":{"axsType":"LINEAR","modulo":false,"moduloValue":360.0,"axsCategory":{"axsCategory":"DRIVEAXS"},"activated":true}}'
Invoke-RestMethod "$base/motion/axs/Axis_4/cfg/properties" -Method PUT -Headers $h -Body $props

# Set limits
$lim = '{"type":"object","value":{"posMin":-1000.0,"posMax":1000.0,"velPos":6000.0,"velNeg":6000.0,"acc":2.0,"dec":2.0,"jrkAcc":0.0,"jrkDec":0.0,"trqPos":10.0,"trqNeg":10.0}}'
Invoke-RestMethod "$base/motion/axs/Axis_4/cfg/lim" -Method PUT -Headers $h -Body $lim

# Delete
Invoke-RestMethod "$base/motion/axs/Axis_4" -Method DELETE -Headers $h
```

---

## Notes

- `POST motion/axs/{name}` with a body → `DL_INVALID_ADDRESS` (wrong pattern)
- To list axes: `GET motion/axs?type=browse` → `arstring` of axis names. Plain `GET motion/axs` (no `?type=browse`) → `404 DL_INVALID_ADDRESS` (re-confirmed 2026-08-11).
- `axsCategory: "VIRTUAL"` → `DL_TYPE_MISMATCH` (unknown enum value). Use `DRIVEAXS` for all axes.
- Velocity unit for LINEAR axes: **mm/min** (not mm/s). 1000 mm in 10 s = 100 mm/s = **6000 mm/min**.
- **`ignore-axisprofile` is at `motion/axs/{name}/cfg/functions/ignore-axisprofile`** (`bool8`), **not** at `cfg/ignore-axisprofile`. Probing the short path returns `DL_INVALID_ADDRESS`, which between 2026-06-12 and 2026-08-11 was three times mistaken for "the node does not exist". Related: `cfg/functions/open-loop` (`bool8`). `cfg/axisprofile` is a separate `string` node — writing a bool there gives `DL_TYPE_MISMATCH`. Verified 2026-08-11, ctrlX OS 4.6 virtual.
- **A `DRIVEAXS` axis without a physical drive does not need this flag** on a virtual CORE — create → power ON → move works with `ignore-axisprofile = false`, unsaved (verified 2026-08-11). An earlier note (2026-06-11) documented that a drive-less axis with an assigned `axisProfileName` fails with `0xf0100001` unless the flag is persisted via `cfg/save` and reloaded on a fresh boot; that mechanism was **not reproduced** on 2026-08-11 and is unconfirmed.
- SETUP switch while an axis is still powered → `500`, `080F0042` `"Some callables refused the event SCHED_EVENT_SWITCH_TO_SETUP"`, cause `"axis <name> has still power"`.
- Browse `motion/axs?type=browse` → liefert Liste der angelegten Achsen (type: `arstring`). `GET motion/axs` ohne `?type=browse` → `DL_INVALID_ADDRESS`.
- `cmd/set-pos` does not exist — but **`cmd/set-pos-abs` does** (`types/motion/axs/cmd/set-pos-abs`, "cmd to set absolute position"), as does `cmd/set-ipo-pos-from-act-pos`. The 2026-06-10 note "position reset node does not exist on standard axes" was wrong: only the guessed *name* was absent. Verified 2026-08-11.
- **Before concluding a node does not exist, browse its parent** (`?type=browse`) and check the child list. Command nodes are create-only: a plain `GET` returns `501`, and `?type=metadata` is the correct existence check. Guessing paths instead of browsing produced three wrong entries in this skill.
- **Axis config is not persisted by anything documented here.** Axes survive a
  Configuration → Running cycle but are lost on reboot. `motion/admin/cfg/save` and
  `make-persistent` exist but no working payload is known — see
  `axis-config-persistence.md`.
- Creating many axes in one pass works without delays (15 verified, 2026-08-11).
- **PowerShell pitfall:** never name a helper function `Move` — it collides with the `Move-Item` alias and tries to move filesystem paths. Use `Send-Move` or similar.
- **Axes must be powered off (DISABLED) before deleting them in Configuration mode.** If axes are STANDSTILL when you switch to SETUP, Motion silently stays in Running and DELETE returns `DL_INVALID_CONFIGURATION`.

## Velocity Reference

| Travel | Time | mm/s | mm/min (velPos) |
|--------|------|------|-----------------|
| 1000 mm | 10 s | 100 | **6000** |
| 1000 mm | 5 s  | 200 | 12000 |
| 500 mm  | 10 s | 50  | 3000 |
