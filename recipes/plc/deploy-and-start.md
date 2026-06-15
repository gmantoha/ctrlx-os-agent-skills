# PLC Deploy und Start via Engineering REST API

Verified on ctrlX WORKS 4.6.1, ctrlX CORE virtual — 2026-06-15.

## Übersicht

Vollständige Reihenfolge für **Build → Download → Start** einer PLC-Applikation:

1. `CommunicationSettingsJob` — Verbindungsparameter setzen
2. `DeviceUserLoginJob` — Benutzer-Login (einmalig pro Session)
3. `BuildJob` — Kompilieren
4. `ApplicationLoginJob (LoginWithDownload)` — Code übertragen
5. `ApplicationJob Start` — Starten

> ⚠️ Jeder Schritt muss abgeschlossen sein (`state == "Done"`) bevor der nächste gesendet wird.
> Nur ein Job läuft gleichzeitig — parallele Requests scheitern mit "blocking operation in progress".

---

## PowerShell-Skript (vollständig)

```powershell
$engBase = "http://localhost:9002/plc/engineering/api/v2"
$deviceUrl = "127.0.0.1"  # IP des ctrlX CORE
$httpsPort = 8443
$plcPort   = 8740          # ctrlX WORKS Gateway Port (lokal/virtuell)
$username  = "aiuser"
$password  = "..." # aus aiUserPasswort Datei laden

function Submit-Job($body, $timeout = 120) {
    $job = Invoke-RestMethod "$engBase/jobs" -Method POST `
        -ContentType "application/json" -Body ($body | ConvertTo-Json -Depth 5)
    $end = (Get-Date).AddSeconds($timeout)
    while ((Get-Date) -lt $end) {
        Start-Sleep -Milliseconds 800
        $j = Invoke-RestMethod "$engBase/jobs/$($job.id)"
        if ($j.state -in @("Done","Failed")) { return $j }
    }
    throw "Job timeout: $($body.jobType)"
}

# 1. Verbindungseinstellungen
$r = Submit-Job @{
    jobType = "CommunicationSettingsJob"
    jobParameters = @{
        nodeUrl   = "/devices/Device"
        ipAddress = $deviceUrl
        httpsPort = $httpsPort
        plcPort   = $plcPort
    }
}
Write-Host "CommSettings: $($r.state) - $($r.jobResultInfo)"

# 2. Benutzer-Login (Fehler "already loggedIn" ist OK)
$r = Submit-Job @{
    jobType = "DeviceUserLoginJob"
    jobParameters = @{
        nodeUrl  = "/devices/Device"
        username = $username
        password = $password
    }
}
Write-Host "DeviceLogin: $($r.state) - $($r.jobResultInfo)"

# 3. Build
$r = Submit-Job @{
    jobType = "BuildJob"
    jobParameters = @{ action = "GenerateCode" }   # ← "GenerateCode" nicht "GenerateCodeJob"!
}
Write-Host "Build: $($r.state) - $($r.jobResultInfo)"
if ($r.jobResultInfo -notmatch "0 errors") { throw "Build failed: $($r.jobResultInfo)" }

# 4. Download (LoginWithDownload)
$r = Submit-Job @{
    jobType = "ApplicationLoginJob"
    jobParameters = @{
        nodeUrl     = "devices/Device/Plc Logic/Application"   # kein führender Slash
        loginOption = "LoginWithDownload"
    }
}
Write-Host "Download: $($r.state) - $($r.jobResultInfo)"

# 5. Start
$r = Submit-Job @{
    jobType = "ApplicationJob"
    jobParameters = @{
        nodeUrl = "devices/Device/Plc Logic/Application"
        action  = "Start"
    }
}
Write-Host "Start: $($r.state) - $($r.jobResultInfo)"
```

---

## Wichtige Ports

| Port | Dienst |
|------|--------|
| `9002` | ctrlX PLC Engineering REST API |
| `8443` | ctrlX CORE HTTPS (REST, Data Layer) |
| `8740` | ctrlX WORKS PLC Gateway (lokal/virtuell) |

> Port `8740` prüfen: `(New-Object Net.Sockets.TcpClient).Connect("127.0.0.1", 8740)`

---

## nodeUrl-Format

| Job | nodeUrl Format |
|-----|---------------|
| `CommunicationSettingsJob` | `"/devices/Device"` (mit führendem `/`) |
| `DeviceUserLoginJob` | `"/devices/Device"` (mit führendem `/`) |
| `ApplicationLoginJob` | `"devices/Device/Plc Logic/Application"` (ohne `/`) |
| `ApplicationJob` | `"devices/Device/Plc Logic/Application"` (ohne `/`) |

---

## Troubleshooting

| Fehler | Ursache | Lösung |
|--------|---------|--------|
| `"Application should be logged in"` | `plcPort` falsch oder `DeviceUserLoginJob` fehlte | Port 8740 prüfen, `DeviceUserLoginJob` davor ausführen |
| `"blocking operation in progress"` | Parallel-Request während Job läuft | Immer auf `state == "Done"` warten |
| `plc/app` returns `[]` nach Download | Verbindung getrennt, Download nicht angekommen | Ports prüfen, Reihenfolge einhalten |
| `BuildJob` läuft ewig | `action` fehlt oder `"GenerateCodeJob"` statt `"GenerateCode"` | `action: "GenerateCode"` setzen |
| `isOnline: false` nach LoginJob | Download fehlgeschlagen | Ports und Credentials prüfen |

---

## Symbol-Konfiguration (Variablen im Data Layer sichtbar machen)

Nach dem Deployment sind GVL-Variablen standardmäßig nicht im Data Layer sichtbar.
`isSelected: false` → muss aktiviert werden:

```powershell
$symConfig = Invoke-RestMethod "$engBase/devices/Device/Plc Logic/Application/symbol-config"

# GVL-Variablen aktivieren
$gvl = $symConfig.symbols | Where-Object { $_.name -eq "GVL" }
$gvl.isSelected = $true
foreach ($v in $gvl.variables) {
    $v.isSelected    = $true
    $v.accessRights  = "ReadWrite"
}

Invoke-RestMethod "$engBase/devices/Device/Plc Logic/Application/symbol-config" `
    -Method PUT -ContentType "application/json" `
    -Body ($symConfig | ConvertTo-Json -Depth 20 -Compress)
```

Nach Build + Download sind Variablen dann unter `plc/app/Application/<variable>` im Data Layer erreichbar.

---

## CODESYSScript.exe

Das Skript-Werkzeug (`CODESYSScript.exe`) ist in der Standardinstallation von ctrlX WORKS **nicht vorhanden**.
Launcher ist: `C:\Program Files\ctrlX WORKS\ctrlxworks.Studio.Launcher.exe`
→ Deployment nur über Engineering REST API (Port 9002).
