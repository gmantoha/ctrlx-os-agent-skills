# PLC Engineering: POUs und GVLs per REST API anlegen

Verified on ctrlX WORKS 4.6.1, PLC Engineering — 2026-06-11.

## Voraussetzungen

- ctrlX PLC Engineering geöffnet, Port **9002**
- Projekt ist geöffnet (`ProjectJob` → `action: Open`)
- Basis-URL: `http://localhost:9002/plc/engineering/api/v2`

---

## Projekt öffnen

```powershell
$base = "http://localhost:9002/plc/engineering/api/v2"
$h = @{ "Content-Type" = "application/json" }

$job = Invoke-RestMethod "$base/jobs" -Method POST -Headers $h -Body (@{
    jobType = "ProjectJob"
    jobParameters = @{
        action = "Open"
        path   = "C:\MeinProjekt\MeinProjekt.plc.project"
    }
} | ConvertTo-Json)
do { Start-Sleep 1; $r = Invoke-RestMethod "$base/jobs/$($job.id)" }
while ($r.state -eq "Running" -or $r.state -eq "Pending")
Write-Host "$($r.state): $($r.jobResultInfo)"
```

---

## Function Block anlegen

```powershell
function Encode-Path($p) { [Uri]::EscapeDataString($p) }
$APP = "Device/Plc Logic/Application"

Invoke-RestMethod "$base/devices/$(Encode-Path $APP)" -Method POST -Headers $h -Body (@{
    name           = "FB_EdgeCounter"
    elementType    = "POU"
    language       = "ST"
    declaration    = @"
FUNCTION_BLOCK FB_EdgeCounter
VAR_INPUT
    bInput  : BOOL;
    bReset  : BOOL;
END_VAR
VAR_OUTPUT
    iCounter : INT;
END_VAR
VAR
    rTrig : R_TRIG;
END_VAR
"@
    implementation = @"
rTrig(CLK := bInput);
IF bReset THEN iCounter := 0; END_IF
IF rTrig.Q THEN iCounter := iCounter + 1; END_IF
"@
} | ConvertTo-Json)
```

> **Typ-Bestimmung:** Der POU-Typ ergibt sich aus dem Schlüsselwort in `declaration`:
> `FUNCTION_BLOCK`, `PROGRAM`, `FUNCTION <name> : <Typ>`

---

## GVL anlegen

```powershell
Invoke-RestMethod "$base/devices/$(Encode-Path $APP)" -Method POST -Headers $h -Body (@{
    name        = "GVL"
    elementType = "GVL"           # ← nicht "POU"!
    language    = "ST"
    declaration = @"
VAR_GLOBAL
    Zaehlerinput1 AT %IX10.0 : BOOL;    (* XI110116_DI Kanal 1 *)
END_VAR
"@
} | ConvertTo-Json)
```

> **Wichtig:** `elementType = "GVL"` (nicht `"POU"`). Sonst wird ein reguläres POU erstellt.

---

## POU aktualisieren (PUT)

```powershell
$path = "Device/Plc Logic/Application/PLC_PRG"
Invoke-RestMethod "$base/devices/$(Encode-Path $path)" -Method PUT -Headers $h -Body (@{
    name           = "PLC_PRG"
    elementType    = "POU"
    language       = "ST"
    declaration    = "<declaration>"
    implementation = "<implementation>"
} | ConvertTo-Json)
```

---

## Projekt speichern

```powershell
$job = Invoke-RestMethod "$base/jobs" -Method POST -Headers $h -Body (@{
    jobType = "ProjectJob"
    jobParameters = @{ action = "Save" }
} | ConvertTo-Json)
do { Start-Sleep 1; $r = Invoke-RestMethod "$base/jobs/$($job.id)" }
while ($r.state -eq "Running" -or $r.state -eq "Pending")
Write-Host "$($r.state)"
```

---

## Namenskonventionen (IEC 61131-3)

| Präfix | Typ | Beispiel |
|---|---|---|
| `FB_` | Function Block | `FB_EdgeCounter` |
| `GVL` / `GVL_` | Global Variable List | `GVL`, `GVL_IO` |
| `b` | BOOL | `bInput`, `bReset` |
| `i` | INT | `iCounter` |
| `r` | REAL | `rSetpoint` |
| `t` | TIME | `tTimer` |

> ⚠️ **Keine Umlaute in Variablennamen!** `ä → ae`, `ö → oe`, `ü → ue`
> Beispiel: `Zaehlerinput1` statt `Zählerinput1`

---

## Pfad-Schema

```
Device/Plc Logic/Application/{POU-Name}
Device/Plc Logic/Application/{GVL-Name}
```

URL-Encoding: `/` → `%2F`, Leerzeichen → `%20`
