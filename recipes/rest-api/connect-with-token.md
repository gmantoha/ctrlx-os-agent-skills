# ctrlX REST API — Token holen und Verbindung verifizieren

Verified on ctrlX OS 4.6, real device 192.168.1.1 — 2026-06-11.

## Ziel

Bearer-Token holen und die Verbindung mit einem zuverlässigen Endpunkt verifizieren.

## Richtige Endpunkte

| Zweck | Methode | Pfad |
|---|---|---|
| Token holen | POST | `/identity-manager/api/v2/auth/token` |
| Verbindung verifizieren | GET | `/package-manager/api/v1/packages` |
| Data Layer lesen | GET | `/automation/api/v2/nodes/{node-path}` |

## ⚠️ Falsche Endpunkte (nicht verwenden)

| Pfad | Fehler |
|---|---|
| `/automation/api/v2/nodes` | `404 Not Found` — Root-Node kann nicht gelistet werden |
| `/automation/api/v2/nodes/framework` | `DL_INVALID_ADDRESS` |
| `/automation/api/v2/system/info` | `404 Not Found` |
| `/device/api/v1/device/info` | gibt HTML zurück (keine API) |

## PowerShell-Rezept

```powershell
# 1. Token holen
$pw = "YOUR_PASSWORD"
$token = (Invoke-RestMethod "https://192.168.1.1/identity-manager/api/v2/auth/token" `
    -Method POST -ContentType "application/json" -SkipCertificateCheck `
    -Body (@{name="aiuser"; password=$pw} | ConvertTo-Json)).access_token

# 2. Verbindung verifizieren (installierte Snaps)
$h = @{ Authorization = "Bearer $token" }
$snaps = Invoke-RestMethod "https://192.168.1.1/package-manager/api/v1/packages" `
    -Headers $h -SkipCertificateCheck
$snaps | Select-Object name, version | Sort-Object name | Format-Table -AutoSize

# 3. Data Layer lesen (Beispiel: Motion-Zustand)
$state = Invoke-RestMethod "https://192.168.1.1/automation/api/v2/nodes/motion/state/opstate" `
    -Headers $h -SkipCertificateCheck
Write-Host "Motion state: $($state.value)"
```

## Hinweise

- `SkipCertificateCheck` ist erforderlich (self-signed cert auf 192.168.1.1).
- Token-Lebensdauer: kurz (~30 min). Bei längeren Sessions neu holen.
- Für `aiuser`-Passwort: siehe `recipes/users/aiUserPasswort`.
- Die Paket-Liste ist groß (~28 KB). Mit `Select-Object name, version` auf relevante Felder filtern.
