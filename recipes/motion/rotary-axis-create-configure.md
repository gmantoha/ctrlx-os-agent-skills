# Rotary Modulo Axis — Create and Configure

Verified on ctrlX OS 4.6, Motion App — 2026-06-08.
Must be in **Configuration** mode for all operations.

---

## Key Findings (ctrlX OS 4.6)

- The valid axis type string for rotary is **`"ROTATIONAL"`** — not `"ROTARY"` (rejected as unknown enum).
- Writing `cfg/properties` as a whole object fails when the body includes `axsCategory` — it returns `DL_TYPE_MISMATCH` / `Axis type missing`.
- Use the **individual sub-nodes** under `cfg/properties/` instead.
- Sub-node names differ from the object keys returned by a GET:

| GET key        | Sub-node path                  | DL type  |
|----------------|-------------------------------|----------|
| `axsType`      | `cfg/properties/type`         | string   |
| `modulo`       | `cfg/properties/modulo`       | bool8    |
| `moduloValue`  | `cfg/properties/modulo-value` | double   |
| `axsCategory`  | `cfg/properties/category`     | object   |
| `activated`    | `cfg/properties/activated`    | bool8    |

---

## 1. Switch to Configuration Mode

```http
PUT /automation/api/v2/nodes/scheduler/admin/state
Body: {"type":"object","value":{"state":"SETUP"}}
```

Verify:
```http
GET /automation/api/v2/nodes/motion/state/opstate
Expected: {"type":"string","value":"Configuration"}
```

---

## 2. Create Axis

```http
POST /automation/api/v2/nodes/motion/axs
Body: {"type":"string","value":"Rot_1"}
```

Expected: `{"type":"string","value":"Rot_1","responseType":"create"}`

---

## 3. Set Axis Type to ROTATIONAL

Write each property via its individual sub-node:

```http
PUT /automation/api/v2/nodes/motion/axs/Rot_1/cfg/properties/type
Body: {"type":"string","value":"ROTATIONAL"}

PUT /automation/api/v2/nodes/motion/axs/Rot_1/cfg/properties/modulo
Body: {"type":"bool8","value":true}

PUT /automation/api/v2/nodes/motion/axs/Rot_1/cfg/properties/modulo-value
Body: {"type":"double","value":360.0}
```

Verify with GET:
```http
GET /automation/api/v2/nodes/motion/axs/Rot_1/cfg/properties
Expected: axsType=ROTATIONAL, modulo=true, moduloValue=360 deg
```

---

## 4. Set Limits

Units for ROTATIONAL axes: `deg` for position, `rpm` for velocity.

```http
PUT /automation/api/v2/nodes/motion/axs/Rot_1/cfg/lim
Body:
{
  "type": "object",
  "value": {
    "posMin": 0.0,
    "posMax": 360.0,
    "velPos": 360.0,
    "velNeg": 360.0,
    "acc": 2.0,
    "dec": 2.0,
    "jrkAcc": 0.0,
    "jrkDec": 0.0,
    "trqPos": 10.0,
    "trqNeg": 10.0
  }
}
```

---

## 5. Save Configuration

```http
POST /automation/api/v2/nodes/motion/cfg/save-all
Body: {"type":"bool8","value":true}
Expected: {"type":"string","value":"Saving finished."}
```

---

## 6. Full PowerShell Example

```powershell
$resp = curl -sk -X POST "https://192.168.1.1/identity-manager/api/v2/auth/token" `
  -H "Content-Type: application/json" `
  -d '{"name":"boschrexroth","password":"boschrexroth"}'
$token = ($resp | ConvertFrom-Json).access_token
$h = @{ Authorization = "Bearer $token"; "Content-Type" = "application/json" }
$base = "https://192.168.1.1/automation/api/v2/nodes"

# Switch to Configuration
Invoke-RestMethod "$base/scheduler/admin/state" -Method PUT -Headers $h `
  -Body '{"type":"object","value":{"state":"SETUP"}}' -SkipCertificateCheck

Start-Sleep 2

# Create axis
Invoke-RestMethod "$base/motion/axs" -Method POST -Headers $h `
  -Body '{"type":"string","value":"Rot_1"}' -SkipCertificateCheck

# Configure via sub-nodes (whole-object write with axsCategory fails)
Invoke-RestMethod "$base/motion/axs/Rot_1/cfg/properties/type" -Method PUT -Headers $h `
  -Body '{"type":"string","value":"ROTATIONAL"}' -SkipCertificateCheck
Invoke-RestMethod "$base/motion/axs/Rot_1/cfg/properties/modulo" -Method PUT -Headers $h `
  -Body '{"type":"bool8","value":true}' -SkipCertificateCheck
Invoke-RestMethod "$base/motion/axs/Rot_1/cfg/properties/modulo-value" -Method PUT -Headers $h `
  -Body '{"type":"double","value":360.0}' -SkipCertificateCheck

# Set limits
$lim = '{"type":"object","value":{"posMin":0.0,"posMax":360.0,"velPos":360.0,"velNeg":360.0,"acc":2.0,"dec":2.0,"jrkAcc":0.0,"jrkDec":0.0,"trqPos":10.0,"trqNeg":10.0}}'
Invoke-RestMethod "$base/motion/axs/Rot_1/cfg/lim" -Method PUT -Headers $h `
  -Body $lim -SkipCertificateCheck

# Save
Invoke-RestMethod "$base/motion/cfg/save-all" -Method POST -Headers $h `
  -Body '{"type":"bool8","value":true}' -SkipCertificateCheck
```

---

## Notes

- `"ROTARY"` is **not valid** on ctrlX OS 4.6 — returns `Unknown string 'ROTARY' received`.
- Writing the whole `cfg/properties` object with an `axsCategory` field fails with `Axis type missing` even when `axsType` is correct. Always use the sub-node approach.
- `modulo=true` with `moduloValue=360.0` makes the axis wrap at 360°.
- Velocity limit unit is `rpm` for ROTATIONAL axes; position unit is `deg`.
