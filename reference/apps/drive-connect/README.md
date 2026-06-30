# DRIVE Connect App

ctrlX OS App zur Parametrierung und Inbetriebnahme von Rexroth-Antrieben (IndraDrive, etc.) direkt vom ctrlX CORE aus.

## Verfügbarkeit

- **Erstmals verfügbar ab:** ctrlX OS **3.6**
- Kein Bestandteil des Standard DC_App_Paket (nicht in 4.x-Paketen enthalten)
- Snap-Name: `rexroth-drive-comm`

## Download

**Collaboration Room (MyRexroth Login erforderlich):**

```
https://www.boschrexroth.com/de/de/myrexroth/myrexroth-home/collaboration-rooms/?path=%2FCtrlx-Automation%2FctrlX_CORE_APPS_Releases%2FV3.6%2FctrlX+Apps%2FctrlX+OS+-+DRIVE+Connect+App&search=&page=1
```

Bekannte Version: `DRIVE connect DCA-3.6.1.app`

## Abhängigkeiten

| Abhängigkeit | Grund | Quelle |
|---|---|---|
| `core22` Base-Snap | Drive Connect 3.6.x nutzt `base: core22` | Collaboration Room: `.../V3.6/.../SYSTEM_APPS/core22-*.app` |

### Installationsreihenfolge

1. Zuerst `core22-*.app` installieren (aus 3.6.x SYSTEM_APPS)
2. Dann `DRIVE connect DCA-3.6.1.app` installieren

**Achtung:** ctrlX OS 4.x nutzt `core24` — `core22` ist dort nicht vorinstalliert und muss manuell nachgeladen werden.

## Bekannte Paketpfade (lokal, auf diesem PC)

`.app`-Dateien sind git-ignoriert und müssen manuell bereitgestellt werden:

```
# Drive Connect App
C:\Users\jmu1but\OneDrive - Bosch Group\MY_Daten\GitHub\Core4_6\DRIVE connect DCA-3.6.1.app

# core22 Base (aus 3.6.8 SYSTEM_APPS)
C:\Users\jmu1but\Downloads\DC_App_Paket_3.6.8\SYSTEM_APPS\core22-20260225.app
```

## Installation (REST API)

```powershell
# 1. Service-Modus
PUT /automation/api/v2/nodes/scheduler%2Fadmin%2Fstate
Body: {"type":"object","value":{"state":"SERVICE"}}

# 2. core22 hochladen (Polling bis installed: true)
curl.exe -k -X POST "https://<IP>/package-manager/api/v1/packages" `
  -H "Authorization: Bearer $token" `
  -F "file=@`"core22-20260225.app`""

# 3. Drive Connect hochladen (Polling bis installed: true)
curl.exe -k -X POST "https://<IP>/package-manager/api/v1/packages" `
  -H "Authorization: Bearer $token" `
  -F "file=@`"DRIVE connect DCA-3.6.1.app`""

# 4. Zurück zu OPERATING
PUT /automation/api/v2/nodes/scheduler%2Fadmin%2Fstate
Body: {"type":"object","value":{"state":"OPERATING"}}
```

## Fehlerdiagnose

| Fehler | Ursache | Lösung |
|---|---|---|
| `cannot install snap base "core22": Could not resolve or connect to proxy or host` | core22 fehlt, Store nicht erreichbar | core22 lokal hochladen (Schritt 1) |
| `Switching not possible because service activity is actual performed by 'Device Admin'` | Device Admin noch aktiv nach Installation | 15–30 Sekunden warten, dann erneut versuchen |

## Verifiziert

- ctrlX OS 4.6.x (virtual, core24) + Drive Connect 3.6.1 — 2026-06-30
