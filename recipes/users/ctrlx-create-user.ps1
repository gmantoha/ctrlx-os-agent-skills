<#
.SYNOPSIS
    Legt einen neuen Benutzer auf einem ctrlX CORE an.

.DESCRIPTION
    Authentifiziert sich mit dem boschrexroth-Admin-Account und erstellt
    einen neuen Benutzer. Das Passwort wird automatisch generiert und im
    gleichen Verzeichnis wie das Skript als "aiUserPasswort" gespeichert.
    Der Forced-Password-Change beim ersten Login wird automatisch entfernt.

    Passwort-Policy des Geräts:
      - Mindestens 12 Zeichen
      - Mindestens 1 Großbuchstabe
      - Mindestens 1 Kleinbuchstabe
      - Mindestens 1 Ziffer

.PARAMETER DeviceIP
    IP-Adresse des ctrlX CORE. Standard: 192.168.1.1

.PARAMETER AdminUser
    Benutzername des Admin-Accounts. Standard: boschrexroth

.PARAMETER AdminPassword
    Passwort des Admin-Accounts. Standard: boschrexroth

.PARAMETER NewUser
    Name des anzulegenden Benutzers. Standard: aiuser

.PARAMETER NewPassword
    Optionales Passwort. Wird keines angegeben, wird automatisch ein
    zufälliges Passwort generiert und in "aiUserPasswort" gespeichert.
    Muss mind. 12 Zeichen, Groß-/Kleinbuchstaben und Ziffern enthalten.

.EXAMPLE
    .\ctrlx-create-user.ps1
    .\ctrlx-create-user.ps1 -DeviceIP 192.168.1.1 -NewUser aiuser
    .\ctrlx-create-user.ps1 -DeviceIP 192.168.1.1 -NewUser aiuser -NewPassword "ctrlX_AI_2024"
#>
param(
    [string]$DeviceIP      = "192.168.1.1",
    [string]$AdminUser     = "boschrexroth",
    [string]$AdminPassword = "boschrexroth",
    [string]$NewUser       = "aiuser",
    [string]$NewPassword   = ""
)

function Test-CtrlXPasswordPolicy {
    param([string]$Password)
    $errors = @()
    if ($Password.Length -lt 12)      { $errors += "Mindestens 12 Zeichen erforderlich (aktuell: $($Password.Length))" }
    if ($Password -cnotmatch '[A-Z]') { $errors += "Mindestens 1 Großbuchstabe erforderlich" }
    if ($Password -cnotmatch '[a-z]') { $errors += "Mindestens 1 Kleinbuchstabe erforderlich" }
    if ($Password -notmatch '\d')     { $errors += "Mindestens 1 Ziffer erforderlich" }
    return $errors
}

function New-CtrlXPassword {
    # Zeichenklassen (keine Anführungszeichen/Backticks um JSON-Probleme zu vermeiden)
    $upper   = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.ToCharArray()
    $lower   = 'abcdefghijklmnopqrstuvwxyz'.ToCharArray()
    $digits  = '0123456789'.ToCharArray()
    $special = '_-.@+='.ToCharArray()
    $all     = $upper + $lower + $digits + $special

    do {
        # Mindestens je 2 aus jeder Pflichtklasse, Rest zufällig auf 16 Zeichen
        $chars  = @()
        $chars += ($upper  | Get-Random -Count 2)
        $chars += ($lower  | Get-Random -Count 2)
        $chars += ($digits | Get-Random -Count 2)
        $chars += ($special| Get-Random -Count 2)
        $chars += ($all    | Get-Random -Count 8)
        $pw = -join ($chars | Sort-Object { Get-Random })
    } while (Test-CtrlXPasswordPolicy $pw)
    return $pw
}

# Passwortdatei im gleichen Verzeichnis wie das Skript
# $PSScriptRoot ist leer wenn per "Mit PowerShell ausführen" gestartet → Fallback auf PSCommandPath
$scriptDir    = if ($PSScriptRoot) { $PSScriptRoot } `
                elseif ($PSCommandPath) { Split-Path -Parent $PSCommandPath } `
                else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$passwordFile = Join-Path $scriptDir "aiUserPasswort"

# TLS/Zertifikat-Kompatibilität: @irm gibt es nur in PS 7+
# In Windows PowerShell 5.1 (Rechtsklick → "Mit PowerShell ausführen") brauchen wir diesen Workaround
$irm = @{}   # splatting-Parameter für Invoke-RestMethod
if ($PSVersionTable.PSVersion.Major -ge 6) {
    $irm = @{ SkipCertificateCheck = $true }
} else {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Add-Type -TypeDefinition @"
using System.Net; using System.Security.Cryptography.X509Certificates;
public class TrustAllCerts : ICertificatePolicy {
    public bool CheckValidationResult(ServicePoint sp, X509Certificate cert, WebRequest req, int problem) { return true; }
}
"@
    [Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCerts
}

# Passwort erzeugen oder prüfen
if (-not $NewPassword) {
    $NewPassword = New-CtrlXPassword
    Write-Host "Zufälliges Passwort generiert." -ForegroundColor Cyan
} else {
    $policyErrors = Test-CtrlXPasswordPolicy $NewPassword
    if ($policyErrors) {
        Write-Host "Fehler: Passwort erfüllt die Geräte-Policy nicht:" -ForegroundColor Red
        $policyErrors | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
        Read-Host "`nDrücke Enter zum Schließen"
        exit 1
    }
}

$base = "https://$DeviceIP"

Write-Host "`nctrlX CORE User-Verwaltung" -ForegroundColor Cyan
Write-Host "Gerät  : $base"
Write-Host "Admin  : $AdminUser"
Write-Host "Neuer  : $NewUser"
Write-Host ""

# ── 1. Admin-Token holen ─────────────────────────────────────────────────────
Write-Host "[1/4] Authentifizierung als '$AdminUser'..." -NoNewline
try {
    $tokenResp = Invoke-RestMethod "$base/identity-manager/api/v2/auth/token" `
        -Method POST -ContentType "application/json" @irm `
        -Body (@{name=$AdminUser; password=$AdminPassword} | ConvertTo-Json)
    $token = $tokenResp.access_token
    Write-Host " OK" -ForegroundColor Green
} catch {
    Write-Host " FEHLER" -ForegroundColor Red
    Write-Error "Token konnte nicht geholt werden: $($_.ErrorDetails.Message)"
    exit 1
}

$h = @{Authorization="Bearer $token"; "Content-Type"="application/json"}

# ── 2. Prüfen ob User bereits existiert ─────────────────────────────────────
Write-Host "[2/4] Prüfe ob '$NewUser' bereits vorhanden..." -NoNewline
$users = Invoke-RestMethod "$base/identity-manager/api/v2/users" -Headers $h @irm
$existing = $users | Where-Object { $_.name -eq $NewUser }
if ($existing) {
    Write-Host " bereits vorhanden (ID $($existing.id))" -ForegroundColor Yellow
    $overwrite = Read-Host "Benutzer '$NewUser' existiert schon. Überschreiben/Löschen und neu anlegen? (j/n)"
    if ($overwrite -ne "j") { Write-Host "Abgebrochen."; exit 0 }

    # Löschen
    Invoke-RestMethod "$base/identity-manager/api/v2/users/$($existing.id)" `
        -Method DELETE -Headers $h @irm | Out-Null
    Write-Host "  -> Alter User gelöscht." -ForegroundColor Yellow
} else {
    Write-Host " frei" -ForegroundColor Green
}

# ── 3. Neuen User anlegen ─────────────────────────────────────────────────────
Write-Host "[3/4] Lege Benutzer '$NewUser' an..." -NoNewline

# Temporäres Passwort für die Zwischenstufe (muss sich vom finalen unterscheiden)
$tempPassword = New-CtrlXPassword

$template = $users | Where-Object { $_.name -eq $AdminUser }

$newUserBody = @{
    name                     = $NewUser
    password                 = $tempPassword
    locked                   = $false
    useGlobalSessionSettings = $template.useGlobalSessionSettings
    passwordPolicyId         = $template.passwordPolicyId
    sessionSettings          = $template.sessionSettings
} | ConvertTo-Json

try {
    $created = Invoke-RestMethod "$base/identity-manager/api/v2/users" `
        -Method POST -Headers $h -Body $newUserBody @irm
    Write-Host " OK (ID $($created.id))" -ForegroundColor Green
} catch {
    Write-Host " FEHLER" -ForegroundColor Red
    Write-Error "User konnte nicht angelegt werden: $($_.ErrorDetails.Message)"
    Read-Host "`nDrücke Enter zum Schließen"
    exit 1
}

# ── 3b. Temp-Passwort via Admin freischalten (entfernt "!"-Flag) ──────────────
Write-Host "[3b] Freischalten des temporären Passworts..." -NoNewline
try {
    $credBody = @{ newPassword = $tempPassword; currentPassword = "!" } | ConvertTo-Json
    Invoke-RestMethod "$base/identity-manager/api/v2/users/$($created.id)/credentials" `
        -Method PUT -Headers $h -Body $credBody @irm | Out-Null
    Write-Host " OK" -ForegroundColor Green
} catch {
    Write-Host " FEHLER" -ForegroundColor Red
    Write-Error "Temp-Credentials konnten nicht gesetzt werden: $($_.ErrorDetails.Message)"
    Read-Host "`nDrücke Enter zum Schließen"
    exit 1
}

# ── 3c. User ändert Passwort selbst → löscht Web-UI Forced-Change-Flag ────────
Write-Host "[3c] Setze finales Passwort (als User selbst)..." -NoNewline
try {
    $newUserToken = (Invoke-RestMethod "$base/identity-manager/api/v2/auth/token" `
        -Method POST -ContentType "application/json" @irm `
        -Body (@{name=$NewUser; password=$tempPassword} | ConvertTo-Json)).access_token

    $newUserHeaders = @{Authorization="Bearer $newUserToken"; "Content-Type"="application/json"}
    $selfCredBody = @{ newPassword = $NewPassword; currentPassword = $tempPassword } | ConvertTo-Json

    Invoke-RestMethod "$base/identity-manager/api/v2/users/$($created.id)/credentials" `
        -Method PUT -Headers $newUserHeaders -Body $selfCredBody @irm | Out-Null
    Write-Host " OK" -ForegroundColor Green
} catch {
    $errMsg = ($_.ErrorDetails.Message | ConvertFrom-Json -ErrorAction SilentlyContinue).dynamicDescription
    Write-Host " FEHLER" -ForegroundColor Red
    Write-Warning "Finales Passwort konnte nicht gesetzt werden: $errMsg"
}

# ── 3d. Berechtigungen setzen (explizit rexroth-device.all.rwx) ──────────────
# Scopes vom Admin-User zu kopieren ist nicht zuverlässig — die API gibt
# manchmal nur "identitymanager.own_credential.w" zurück, sodass der neue
# User keinen Gerätezugriff hat (Data Layer, Motion, REST alle gesperrt).
# Deshalb wird rexroth-device.all.rwx immer explizit gesetzt.
# (verified 2026-06-10, ctrlX OS 4.6)
Write-Host "[3d] Setze Berechtigungen (rexroth-device.all.rwx)..." -NoNewline
try {
    $scopeBody = '[{"identifier":"rexroth-device.all.rwx"}]'
    Invoke-RestMethod "$base/identity-manager/api/v2/users/$($created.id)/scopes" `
        -Method PUT -Headers $h -Body $scopeBody @irm | Out-Null
    Write-Host " OK (rexroth-device.all.rwx)" -ForegroundColor Green
} catch {
    $errMsg = ($_.ErrorDetails.Message | ConvertFrom-Json -ErrorAction SilentlyContinue).dynamicDescription
    Write-Host " FEHLER" -ForegroundColor Red
    Write-Warning "Scopes konnten nicht gesetzt werden: $errMsg"
}

# ── 3e. SSH-Gruppe zuweisen ───────────────────────────────────────────────────
Write-Host "[3e] SSH-Gruppe zuweisen..." -NoNewline
try {
    $sshGroups = Invoke-RestMethod "$base/identity-manager/api/v2/groups" -Headers $h @irm
    $sshGroup  = @($sshGroups) | Where-Object { $_.name -eq "sshuser" } | Select-Object -First 1
    if ($sshGroup) {
        Invoke-RestMethod "$base/identity-manager/api/v2/groups/$($sshGroup.id)/members" `
            -Method POST -Headers $h -Body (@{id=$created.id} | ConvertTo-Json) @irm | Out-Null
        Write-Host " OK (sshuser)" -ForegroundColor Green
    } else {
        Write-Host " übersprungen (keine sshuser-Gruppe gefunden)" -ForegroundColor Yellow
    }
} catch {
    $errMsg = ($_.ErrorDetails.Message | ConvertFrom-Json -ErrorAction SilentlyContinue).dynamicDescription
    Write-Host " FEHLER: $errMsg" -ForegroundColor Red
}

# ── 4. Ergebnis verifizieren ─────────────────────────────────────────────────
Write-Host "[4/4] Verifiziere Login mit finalem Passwort..." -NoNewline
try {
    $testToken = Invoke-RestMethod "$base/identity-manager/api/v2/auth/token" `
        -Method POST -ContentType "application/json" @irm `
        -Body (@{name=$NewUser; password=$NewPassword} | ConvertTo-Json)
    if ($testToken.access_token) {
        Write-Host " OK - Login erfolgreich!" -ForegroundColor Green
    }
} catch {
    Write-Host " Login-Test fehlgeschlagen" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Fertig!" -ForegroundColor Cyan
Write-Host "  Benutzer : $NewUser"
Write-Host "  ID       : $($created.id)"
Write-Host "  Gerät    : $base"

# ── Passwort in Datei speichern ───────────────────────────────────────────────
$pwContent = @"
Benutzer : $NewUser
Gerät    : $base
Passwort : $NewPassword
Erstellt : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
"@
try {
    Set-Content -Path $passwordFile -Value $pwContent -Encoding UTF8 -ErrorAction Stop
    Write-Host "  Passwort : gespeichert in '$passwordFile'" -ForegroundColor Yellow
} catch {
    Write-Host "  FEHLER beim Speichern der Passwortdatei: $_" -ForegroundColor Red
}
Write-Host ""
Write-Host "Alle angelegten Benutzer:"
$allUsers = Invoke-RestMethod "$base/identity-manager/api/v2/users" -Headers $h @irm
$allUsers | Format-Table name, id, locked, systemuser -AutoSize

Read-Host "`nDrücke Enter zum Schließen"

