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
- Browse `motion/axs` (GET) → `DL_INVALID_ADDRESS` (can't list axes this way)
- To list axes: poll known names individually or read from PLC GVL
- `axsCategory: "VIRTUAL"` → `DL_TYPE_MISMATCH` (unknown enum value). Use `DRIVEAXS` for all axes.
- Velocity unit for LINEAR axes: **mm/min** (not mm/s). 1000 mm in 10 s = 100 mm/s = **6000 mm/min**.
- **`motion/axs/{name}/cfg/ignore-axisprofile` existiert nicht** (`DL_INVALID_ADDRESS`). Der tatsächliche Knoten heißt `cfg/axisprofile` (type: `string`, default: `""`). Das Switch-to-Running-Rezept, das `ignore-axisprofile=true` erwähnt, ist veraltet/falsch — verified 2026-06-12, ctrlX OS 4.6 virtual.
- **Virtuelle Steuerung ohne Drive:** Motion bleibt nach `Booting`-Kommando >60 s in Booting und fällt zurück nach Configuration. Wechsel nach Running schlägt fehl (`0xf0100001`). Achsen können erstellt/konfiguriert werden, aber Running ist ohne Drive-Zuweisung nicht erreichbar.
- Browse `motion/axs?type=browse` → liefert Liste der angelegten Achsen (type: `arstring`). `GET motion/axs` ohne `?type=browse` → `DL_INVALID_ADDRESS`.
- `cmd/set-pos` → `DL_INVALID_ADDRESS` — position reset node does not exist on standard axes (verified 2026-06-10).
- **PowerShell pitfall:** never name a helper function `Move` — it collides with the `Move-Item` alias and tries to move filesystem paths. Use `Send-Move` or similar.
- **Axes must be powered off (DISABLED) before deleting them in Configuration mode.** If axes are STANDSTILL when you switch to SETUP, Motion silently stays in Running and DELETE returns `DL_INVALID_CONFIGURATION`.

## Velocity Reference

| Travel | Time | mm/s | mm/min (velPos) |
|--------|------|------|-----------------|
| 1000 mm | 10 s | 100 | **6000** |
| 1000 mm | 5 s  | 200 | 12000 |
| 500 mm  | 10 s | 50  | 3000 |
