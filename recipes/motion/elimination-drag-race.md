# Elimination Drag Race

Verified on ctrlX OS 4.6, real device 192.168.1.1 — 2026-06-11.
4 virtual LINEAR axes (DRIVEAXS + ignore-axisprofile), no physical drive.

## Concept

All axes race simultaneously to 1000mm at different speeds.
Last to arrive is eliminated (deleted from Motion config).
Survivors race back the other direction next round — no artificial position reset needed.
Last axis standing wins.

```
Round 1: 0mm → 1000mm   (loser eliminated)
Round 2: 1000mm → 0mm   (loser eliminated)
Round 3: 0mm → 1000mm   (winner!)
```

The alternating direction means survivors start each round from exactly where they ended — clean, no wasted return trip.

## Speed Spread (recommended)

| Axes remaining | Speeds (mm/min) | Travel times (~) |
|---|---|---|
| 4 | 3000, 4500, 6000, 8000 | 20s, 13s, 10s, 7.5s |
| 3 | 3000, 5500, 9000 | 20s, 11s, 7s |
| 2 | 3000, 9000 | 20s, 7s — maximum drama |

Shuffle speeds randomly each round so no axis is always fast/slow.

## Elimination Sequence

1. Fire all axes simultaneously with `cmd/pos-abs`
2. Poll all axes every 500ms — log `actualPos` until all but one reach target
3. **Halt the loser** before powering off — send `cmd/pos-abs` to its current position at low vel (100 mm/min) and wait for STANDSTILL. Skipping this causes `DL_CREATION_FAILED` if the axis is still in `DISCRETE_MOTION` when you call `cmd/power false`.
4. Power off loser → power off survivors
5. Switch to Configuration (`scheduler/admin/state` → `SETUP`)
6. DELETE the loser axis
7. Switch back to Running (`OPERATING`)
8. Power on survivors, start next round

## Key Pitfalls

- **Cannot power off a moving axis.** State must be `STANDSTILL` before `cmd/power false`. Send it to its current position to stop it cleanly.
- **`cmd/set-pos` does not exist** on standard LINEAR axes — returns `DL_INVALID_ADDRESS`. Direct position write without moving is not supported. Use alternating race direction instead of resetting to 0.
- **Mode switch requires all axes DISABLED.** Power off all survivors before switching to SETUP, or the switch silently fails and Motion stays in Running.
- **`ERRORSTOP` after abrupt stop** — if an axis ends up in ERRORSTOP, use `cmd/reset` (POST, null body). After reset it may land on `DISABLED` — power on again if needed.
- **Never name a PowerShell helper function `Move`** — collides with `Move-Item` alias. Use `Send-Move` or similar.
- **Max 4 axes** on entry-level Motion license. Standard license = 10. Upgradeable via ctrlX Shop.

## PowerShell Skeleton

```powershell
$pw    = "YOUR_PASSWORD"
$token = (Invoke-RestMethod "https://192.168.1.1/identity-manager/api/v2/auth/token" `
    -Method POST -ContentType "application/json" -SkipCertificateCheck `
    -Body (@{name="aiuser"; password=$pw} | ConvertTo-Json)).access_token
$h    = @{ Authorization = "Bearer $token"; "Content-Type" = "application/json" }
$base = "https://192.168.1.1/automation/api/v2/nodes"

function Send-Move($name, $pos, $vel) {
    $body = "{`"type`":`"object`",`"value`":{`"axsPos`":$pos,`"buffered`":false,`"lim`":{`"vel`":$vel,`"acc`":5.0,`"dec`":5.0,`"jrkAcc`":0.0,`"jrkDec`":0.0}}}"
    Invoke-RestMethod "$base/motion/axs/$name/cmd/pos-abs" -Method POST -Headers $h -SkipCertificateCheck -Body $body | Out-Null
}
function Get-Pos($name) { [math]::Round((Invoke-RestMethod "$base/motion/axs/$name/state/values/actual" -Headers $h -SkipCertificateCheck).value.actualPos,0) }
function Get-Plc($name) { (Invoke-RestMethod "$base/motion/axs/$name/state/opstate/plcopen" -Headers $h -SkipCertificateCheck).value }
function Halt-Axis($name) {
    $pos = Get-Pos $name
    Send-Move $name $pos 100
    do { Start-Sleep -Milliseconds 200 } while ((Get-Plc $name) -eq "DISCRETE_MOTION")
}
function Set-Power($name, $on) {
    $val = if ($on) { "true" } else { "false" }
    Invoke-RestMethod "$base/motion/axs/$name/cmd/power" -Method POST -Headers $h -SkipCertificateCheck `
        -Body "{`"type`":`"bool8`",`"value`":$val}" | Out-Null
}

# See full implementation in session history (2026-06-11)
```
