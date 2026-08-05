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

$job = Invoke-RestMethod "$base/jobs" -Method POST -Headers $h -Body (@{
    jobType = "NewProjectJob"
    jobParameters = @{
        filePath = "C:\Users\$env:USERNAME\Documents\My ctrlX"  # Zielordner (muss existieren)
        fileName = "MeinIOProjekt"                               # Projektname ohne Extension
        template = "ctrlXOSIO"                                   # v4.6.x
    }
} | ConvertTo-Json)

# Warten bis Job abgeschlossen
do {
    Start-Sleep 1
    $result = Invoke-RestMethod "$base/jobs/$($job.id)"
} while ($result.state -eq "Running" -or $result.state -eq "Pending")

Write-Host "Status: $($result.state) - $($result.jobResultInfo)"
```

> **Wichtig (v4.6.x):** `filePath` ist der **Ordner**, `fileName` der Projektname. Template-Enum: `ctrlXOSIO`.
> Für ältere Installationen (v2.1.0): Parameter `projectFolder` + `projectName` + `templateKey: ctrlXCOREIO`.
>
> Die lokale OpenAPI-Spec liegt unter:
> `C:\Program Files\ctrlX WORKS\ctrlX IO Engineering\{version}\Studio\Help\OpenAPI\io-engineering-api-v2.json`

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

## 7. Konfiguration auf ctrlX CORE übertragen

### Vorbedingungen prüfen

**Wichtig:** Die App `rexroth-ethercatmaster` muss installiert **und** eine Instanz angelegt sein.

```powershell
# Instanz prüfen / anlegen (einmalig pro Gerät nötig)
$dlH = @{ Authorization = "Bearer $token"; Accept = "application/json"; "Content-Type" = "application/json" }

$instBody = @{
    type  = "object"
    value = @{ request = @{ instanceName = "ethercatmaster"; port = "eth1" } }
} | ConvertTo-Json -Depth 5

Invoke-RestMethod "https://{IP}:{PORT}/automation/api/v2/nodes/fieldbuses/ethercat/master/instances" `
    -Method POST -Headers $dlH -Body $instBody -SkipCertificateCheck
# → {"type":"string","value":"fieldbuses/ethercat/master/instances/ethercatmaster","responseType":"create"}
```

> Fehler _"EtherCAT-Master-Instanz nicht vorhanden"_ → Instanz fehlt, obwohl App installiert ist.

### Verbinden, einloggen und übertragen

```powershell
$base = "http://localhost:9003/io/engineering/api/v2"
$h = @{ "Content-Type" = "application/json" }

# 1. Verbindung zur ctrlX CORE setzen
$conn = Invoke-RestMethod "$base/jobs" -Method POST -Headers $h -Body (@{
    jobType = "CommunicationSettingsJob"
    jobParameters = @{ nodeUrl = "/devices/Device"; ipAddress = "{IP}"; httpsPort = {PORT} }
} | ConvertTo-Json)
do { Start-Sleep 2; $r = Invoke-RestMethod "$base/jobs/$($conn.id)" } while ($r.state -eq "Running" -or $r.state -eq "Pending")
Write-Host "Verbindung: $($r.state)"

# 2. Login
$login = Invoke-RestMethod "$base/jobs" -Method POST -Headers $h -Body (@{
    jobType = "DeviceUserLoginJob"
    jobParameters = @{ nodeUrl = "/devices/Device"; username = "aiuser"; password = $pw }
} | ConvertTo-Json)
do { Start-Sleep 2; $r = Invoke-RestMethod "$base/jobs/$($login.id)" } while ($r.state -eq "Running" -or $r.state -eq "Pending")
# "User is already loggedIn" gilt als OK

# 3. Transfer
$transfer = Invoke-RestMethod "$base/jobs" -Method POST -Headers $h -Body (@{
    jobType = "TransferFieldbusConfigJob"
    jobParameters = @{ nodeUrl = "/devices/Device/ethercatmaster"; allowSwitchState = $true }
} | ConvertTo-Json)
do { Start-Sleep 3; $r = Invoke-RestMethod "$base/jobs/$($transfer.id)" } while ($r.state -eq "Running" -or $r.state -eq "Pending")
Write-Host "Transfer: $($r.state) - $($r.jobResultInfo)"
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
