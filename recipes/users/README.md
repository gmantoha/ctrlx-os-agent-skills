# ctrlX CORE — Benutzerverwaltung per Skript

## Zweck

Das PowerShell-Skript `ctrlx-create-user.ps1` legt auf einem ctrlX CORE einen neuen
Service-Account (`aiuser`) mit einem zufälligen, policy-konformen Passwort an.  
Das Passwort wird als Datei `aiUserPasswort` im gleichen Verzeichnis abgelegt.

## Voraussetzungen

| Anforderung | Detail |
|---|---|
| PowerShell | 5.1 oder 7+ (beide werden unterstützt) |
| Netzwerkzugang | `https://192.168.1.1` erreichbar |
| Admin-Account | `boschrexroth` / `boschrexroth` (Werkseinstellung) |

## Schnellstart

```powershell
# Im Ordner mit dem Skript ausführen
.\ctrlx-create-user.ps1
```

Optional mit expliziter IP und/oder Benutzername:

```powershell
.\ctrlx-create-user.ps1 -DeviceIP 192.168.1.1 -NewUser aiuser
```

## Was das Skript tut

1. **Admin-Token holen** — Authentifizierung mit `boschrexroth`-Account
2. **Prüfung** — Existiert `aiuser` bereits? Falls ja: interaktives Überschreiben
3. **User anlegen** — Temporäres Passwort, dann finales Passwort (self-change)
4. **Berechtigungen** — Scopes vom Admin-Account übernommen (`rexroth-device.all.rwx`)
5. **SSH-Gruppe** — `sshuser`-Gruppe wird zugewiesen (falls vorhanden)
6. **Login-Verifikation** — Token-Test mit dem neuen User und finalem Passwort
7. **Passwort speichern** — Datei `aiUserPasswort` im Skriptverzeichnis

## Passwort-Policy

Das generierte Passwort erfüllt automatisch die ctrlX-Geräte-Policy:

- Mindestens 12 Zeichen
- Mindestens 1 Großbuchstabe
- Mindestens 1 Kleinbuchstabe
- Mindestens 1 Ziffer

## Passwort-Datei lesen (für weitere Skripte)

```powershell
$pw = (Get-Content ".\aiUserPasswort" | Where-Object { $_ -match '^Passwort' }) -replace '.*:\s*'
```

## Einrichten für Core4_6

Der Ordner `Core4_6` im lokalen GitHub-Arbeitsverzeichnis enthält eine eigene Kopie dieses Skripts.
Die zugehörige Passwortdatei liegt unter:

```
C:\Users\jmu1but\OneDrive - Bosch Group\MY_Daten\GitHub\Core4_6\aiUserPasswort
```

> Die Passwortdatei wird **nicht** in Git eingecheckt (via `.gitignore`).

## Verifikation nach der Anlage

```powershell
$pwFile = ".\aiUserPasswort"
$pw     = (Get-Content $pwFile | Where-Object { $_ -match '^Passwort' }) -replace '.*:\s*'

$token = (Invoke-RestMethod "https://192.168.1.1/identity-manager/api/v2/auth/token" `
    -Method POST -ContentType "application/json" -SkipCertificateCheck `
    -Body (@{name="aiuser"; password=$pw} | ConvertTo-Json)).access_token

$h = @{Authorization="Bearer $token"}

# Benutzer-Info
Invoke-RestMethod "https://192.168.1.1/identity-manager/api/v2/users/1002" -Headers $h -SkipCertificateCheck

# CPU-Auslastung
Invoke-RestMethod "https://192.168.1.1/automation/api/v2/nodes/framework/metrics/system/cpu-utilisation-percent" `
    -Headers $h -SkipCertificateCheck
```
