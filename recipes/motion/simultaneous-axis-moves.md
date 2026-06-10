# Simultaneous Multi-Axis Moves

Verified on ctrlX OS 4.6, real hardware — 2026-06-10.

## How It Works

Send `cmd/pos-abs` to multiple axes back-to-back **before polling any of them**.
ctrlX Motion executes all commands that arrive before the next motion cycle simultaneously.

```powershell
# Send both commands immediately — do NOT wait between them
Send-MoveCmd "Gantry_X" 250 1500   # 25 mm/s
Send-MoveCmd "Gantry_Y" 150 900    # 15 mm/s

# Then poll both together
Wait-BothStandstill "Gantry_X" "Gantry_Y"
```

## Full PowerShell Pattern

```powershell
function Send-MoveCmd($axs, $pos, $vel) {
    $body = "{`"type`":`"object`",`"value`":{`"axsPos`":$pos,`"buffered`":false,`"lim`":{`"vel`":$vel,`"acc`":2.0,`"dec`":2.0,`"jrkAcc`":0.0,`"jrkDec`":0.0}}}"
    curl.exe -sk -X POST "$base/automation/api/v2/nodes/motion/axs/$axs/cmd/pos-abs" `
      -H "Authorization: Bearer $token" -H "Content-Type: application/json" -d $body | Out-Null
}

function Wait-BothStandstill($axs1, $axs2) {
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    do {
        Start-Sleep -Milliseconds 200
        $st1 = (curl.exe -sk -H "Authorization: Bearer $token" `
          "$base/automation/api/v2/nodes/motion/axs/$axs1/state/opstate/plcopen" | ConvertFrom-Json).value
        $st2 = (curl.exe -sk -H "Authorization: Bearer $token" `
          "$base/automation/api/v2/nodes/motion/axs/$axs2/state/opstate/plcopen" | ConvertFrom-Json).value
    } while (
        ($st1 -notin @("STANDSTILL","ERRORSTOP") -or $st2 -notin @("STANDSTILL","ERRORSTOP")) -and
        $sw.Elapsed.TotalSeconds -lt 120
    )
    Write-Host "$axs1 [$st1]  $axs2 [$st2]  ($([math]::Round($sw.Elapsed.TotalSeconds,1))s)"
}

# Simultaneous move
Send-MoveCmd "Gantry_X" 250 1500
Send-MoveCmd "Gantry_Y" 150 900
Wait-BothStandstill "Gantry_X" "Gantry_Y"

# Simultaneous home (3 axes)
Send-MoveCmd "Gantry_X" 0 1500
Send-MoveCmd "Gantry_Y" 0 900
Send-MoveCmd "Rotary_Table" 0 30
# ... poll all three
```

## Velocity Units

| Axis Type  | Unit in `cmd/pos-abs` lim.vel |
|------------|-------------------------------|
| LINEAR     | mm/min  (÷ 60 = mm/s)        |
| ROTATIONAL | rpm                           |

## Notes

- Do **not** insert `Start-Sleep` or any polling between send commands — that would serialize the moves.
- Works for 2, 3, or more axes in the same cycle.
- Axes arrive at their targets at different times if distances/velocities differ — each reaches STANDSTILL independently.
- Poll all axes in a single loop and exit when **all** are STANDSTILL/ERRORSTOP.
- **PowerShell pitfall:** never name your helper function `Move` — it aliases to `Move-Item` (filesystem). Use `Send-Move`, `Send-MoveCmd`, or similar.
