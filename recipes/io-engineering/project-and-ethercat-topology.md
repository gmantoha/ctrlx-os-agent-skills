# IO Engineering: Projekt und EtherCAT-Topologie anlegen

Dieses Rezept zeigt, wie man per REST API ein neues IO Engineering-Projekt anlegt und eine typische ctrlX I/O EtherCAT-Topologie aufbaut.

## Voraussetzungen

- ctrlX WORKS IO Engineering läuft lokal (z.B. Port 9003)
- Basis-URL: `http://localhost:9003/io/engineering/api/v2`
- API-Doku: https://boschrexroth.github.io/rest-api-description/ctrlx-automation/ctrlx-works/index.html

---

## 1. Neues Projekt anlegen

```powershell
$base = "http://localhost:9003/io/engineering/api/v2"
$h = @{ "Content-Type" = "application/json" }

$job = Invoke-RestMethod "$base/jobs" -Method POST -Headers $h -Body @"
{
  "jobType": "NewProjectJob",
  "jobParameters": {
    "projectName": "MeinIOProjekt",
    "projectFolder": "C:\\Users\\<User>\\Documents\\My ctrlX",
    "templateKey": "ctrlXCOREIO"
  }
}
"@

# Warten bis Job abgeschlossen
do {
    Start-Sleep 1
    $result = Invoke-RestMethod "$base/jobs/$($job.id)"
} while ($result.state -eq "Running" -or $result.state -eq "Pending")

Write-Host "Status: $($result.state) - $($result.jobResultInfo)"
```

> **Wichtig:** Template-Key ist `ctrlXCOREIO` (nicht `ctrlXOSIO` wie im OpenAPI-Beispiel).

---

## 2. Bestehende Gerätestruktur lesen

```powershell
# Alle Knoten unter Device anzeigen
Invoke-RestMethod "$base/devices/Device" | ConvertTo-Json -Depth 3
```

Das Standardtemplate enthält bereits:
- `Device` → `ethercatmaster`

---

## 3. Buskoppler XB-EC-12 einfügen

IO-Module immer **zuerst den Buskoppler** einfügen, danach Module darunter.

```powershell
$coupler = Invoke-RestMethod "$base/devices/Device/ethercatmaster" -Method POST -Headers $h -Body @"
{
  "name": "XB_EC_12",
  "elementType": "Device",
  "deviceInfo": {
    "deviceType": 65,
    "id": "24_00242A0F00000100",
    "version": "Revision=16#00000100"
  }
}
"@

Write-Host "Buskoppler: $($coupler.name), Kinder: $($coupler.children -join ', ')"
# → Kinder enthält automatisch "XF71" (Explicit Connector für IO-Module)
```

---

## 4. DI-Modul XI110208 (8x Digital Input) unter dem Buskoppler einfügen

IO-Module kommen unter den `XF71`-Connector des Buskopplers:

```powershell
$di = Invoke-RestMethod "$base/devices/Device/ethercatmaster/XB_EC_12/XF71" -Method POST -Headers $h -Body @"
{
  "name": "DI_Modul_8Ch",
  "elementType": "Device",
  "deviceInfo": {
    "deviceType": 65,
    "id": "24_00242A0300000100",
    "version": "Revision=16#00000100"
  }
}
"@

Write-Host "Modul: $($di.name)"
$di.ioMapping | ForEach-Object { Write-Host "  $($_.address) - $($_.channelName)" }
# → %IX10.0 .. %IX10.7 (nach Buskoppler-Offset)
```

---

## 5. Variablennamen setzen

```powershell
# Aktuelle ioMapping holen (Adressen können sich je nach Topologie unterscheiden)
$dev = Invoke-RestMethod "$base/devices/Device/ethercatmaster/XB_EC_12/XF71/DI_Modul_8Ch"

# PUT mit gewünschten Variablennamen (automatic=false)
$ioEntries = for ($i = 0; $i -lt 8; $i++) {
    $addr = $dev.ioMapping[$i].address
    [PSCustomObject]@{
        id          = ""
        address     = $addr
        variable    = "Eingang$($i+1)"
        automatic   = $false
        channelName = "Value"
        baseType    = "BIT"
        ioType      = "Input"
        sectionName = $null
        subChannels = @()
    }
}

$putBody = @{
    name           = "DI_Modul_8Ch"
    elementType    = "Device"
    deviceInfo     = $dev.deviceInfo
    ioMapping      = $ioEntries
} | ConvertTo-Json -Depth 5

Invoke-RestMethod "$base/devices/Device/ethercatmaster/XB_EC_12/XF71/DI_Modul_8Ch" `
    -Method PUT -Headers $h -Body $putBody
```

> **Bekannte Einschränkung (IoStudio 2.1.0):** XI110208-Kanäle haben leere `id`-Felder. Das PUT setzt dadurch alle Kanäle auf den Wert des ersten Eintrags. Für individuelle Variablennamen muss die Projektdatei ggf. direkt bearbeitet oder ein Gerät mit populierten Channel-IDs verwendet werden.

---

## 6. Projekt speichern

```powershell
$save = Invoke-RestMethod "$base/jobs" -Method POST -Headers $h -Body @"
{
  "jobType": "ProjectJob",
  "jobParameters": { "action": "Save" }
}
"@
Start-Sleep 2
$r = Invoke-RestMethod "$base/jobs/$($save.id)"
Write-Host "Gespeichert: $($r.jobResultInfo)"
```

---

## Gerätepfad-Schema

```
/devices/Device/ethercatmaster/{Buskoppler}/{Connector}/{IOModul}
```

Beispiel:
```
/devices/Device/ethercatmaster/XB_EC_12/XF71/DI_Modul_8Ch
```
