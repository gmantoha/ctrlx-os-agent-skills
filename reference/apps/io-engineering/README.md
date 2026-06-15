# ctrlX WORKS IO Engineering

ctrlX WORKS IO Engineering (IoStudio) ist das PC-basierte Engineering-Tool für die ctrlX I/O-Familie. Es läuft lokal auf dem Engineering-PC und stellt eine REST API bereit.

## API-Dokumentation

| Quelle | URL |
|--------|-----|
| OpenAPI-Übersicht (alle ctrlX WORKS APIs) | https://boschrexroth.github.io/rest-api-description/ctrlx-automation/ctrlx-works/index.html |
| IO Engineering OpenAPI JSON (v2.10.0) | https://boschrexroth.github.io/rest-api-description/ctrlx-automation/ctrlx-works/io-engineering/io-engineering.v2.10.0.openapi.json |
| REST API Upstream Repository | https://github.com/boschrexroth/rest-api-description |

> **Offline-Fallback:** Die lokale OpenAPI-Spec liegt in der Installation:
> `C:\Program Files\ctrlX WORKS\ctrlX IO Engineering\{version}\Studio\Help\OpenAPI\io-engineering-api-v2.json`

## Lokale Basis-URL

```
http://localhost:{port}/io/engineering/api/v2
```

Der Port muss bei der Installation gewählt werden. Typisch: `9003`.

### Port-Erkennung (schnellster Test)

```powershell
Invoke-RestMethod "http://localhost:9003/io/engineering/api/v2/product/info"
# → {"versionText":"4.6.1"}  ✅
```

Wenn IO Engineering noch nicht gestartet ist, zuerst starten:

```powershell
Start-Process "C:\Program Files\ctrlX WORKS\ctrlX IO Engineering\4.6.1\Studio\Common\ctrlX-IO-Engineering.exe"
Start-Sleep 10
```

Der Swagger-Port `9003` ist **nur die Doku-Seite** (`/` → Swagger UI). Die API-Endpunkte liegen unter `/io/engineering/api/v2/...`.

## Installationsort

| Version | Pfad |
|---|---|
| v4.6.x (ctrlX WORKS neu) | `C:\Program Files\ctrlX WORKS\ctrlX IO Engineering\4.6.1\Studio\Common\ctrlX-IO-Engineering.exe` |
| v2.x (ctrlX WORKS alt) | `C:\Program Files\Rexroth\ctrlX WORKS(1)\StudioIo\Common\ctrlX-IO-Engineering.exe` |

## Geräte-Cache

Gerätebeschreibungen (ESI-XMLs, device.xml) liegen unter:

```
C:\ProgramData\Rexroth\WRK-V-0204\0\Studio\Devices\
```

Unterordner-Schema: `{deviceType}\{deviceId}\{encodedVersion}\`

- `deviceType 65` = EtherCAT Slave
- ctrlX IO-Geräte haben IDs der Form `24_00242A*`

## NewProjectJob – korrekte Parameter (v4.6.x)

Ab ctrlX WORKS v4.6 hat sich das Schema für `NewProjectJob` geändert:

```json
{
  "jobType": "NewProjectJob",
  "jobParameters": {
    "filePath": "C:\\Users\\<User>\\Documents\\My ctrlX",
    "fileName": "MeinIOProjekt",
    "template": "ctrlXOSIO"
  }
}
```

- `filePath` = **Zielordner** (nicht der vollständige Dateipfad!)
- `fileName` = Projektname ohne Dateiendung
- `template` = Enum-Wert: `ctrlXOSIO` oder `EmptyProject`

> **Versionsunterschiede:**
> - v4.6.x: Parameter `filePath` + `fileName` + `template`; Template-Wert `ctrlXOSIO` ✅
> - v2.1.0: Parameter `projectFolder` + `projectName` + `templateKey`; Template-Wert `ctrlXCOREIO`

## Projekt-Templates

| Template | Version | Beschreibung |
|---|---|---|
| `ctrlXOSIO` | v4.6.x | Standardprojekt ctrlX I/O (verifiziert 2026-06-11) |
| `EmptyProject` | v4.6.x | Leeres Projekt |
| `ctrlXCOREIO` | v2.1.0 | Standardprojekt ctrlX I/O (ältere Installation) |

## Projektstruktur (Standardtemplate)

```
Devices (Root)
└── Device  (ctrlX CORE I/O Configuration)
    └── ethercatmaster  (EtherCAT Master)
        └── {Slave-Knoten}
```

## Wichtige Job-Typen

| JobType | Aktion |
|---|---|
| `NewProjectJob` | Neues Projekt anlegen |
| `OpenProjectJob` | Bestehendes Projekt öffnen |
| `ProjectJob` + `action: Save` | Projekt speichern |
| `ExportJob` | Projekt/Knoten exportieren (benötigt `parentNode`) |
| `ExportEthercatConfigJob` | EtherCAT-Konfiguration exportieren |
| `ImportJob` | Importieren |

## ctrlX IO-Geräte (Auswahl)

| Bestellnummer | ID | Beschreibung |
|---|---|---|
| XB-EC-12 | `24_00242A0F00000100` | EtherCAT Bus Coupler PwrIn UL UP |
| XB-EC-31 | `24_00242A1200000200` | EtherCAT Bus Coupler (erweiterter Typ) |
| XB-ET-31 | `24_00242A2900000100` | EtherCAT Bus Coupler (ET-Variante) |
| XI110208 | `24_00242A0300000100` | 8-Kanal Digital Input 24V 3ms |
| XI110116 | `24_00242A0400000100` | 16-Kanal Digital Input 24V |
| XI211208 | `24_00242A0100000100` | 8-Kanal Digital Input (erweitert) |
| XI211116 | `24_00242A0200000100` | 16-Kanal Digital Output 24V/0.5A |
| XI312204 | `24_00242A0C00000100` | 4-Kanal Analog Input 0-10V 16Bit DIFF |
| XI422204 | `24_00242A0700000100` | 4-Kanal Analog Output |
| XI412204 | `24_00242A0800000100` | 4-Kanal Analog Output 0-10V 16Bit BIPOLAR |

Version-String immer: `Revision=16#00000100` (außer XB-EC-31: `16#00000200`)

## EtherCAT I/O-Adressen (verifiziert 2026-06-11)

Topologie: XB-EC-12 → XF71 → IO-Module (Reihenfolge wie eingefügt)

| Position | Modul | Erste Adresse |
|---|---|---|
| 1. Modul nach XB-EC-12 | XI110116 (16x DI) | `%IX10.0` |
| 2. Modul | XI211116 (16x DO) | `%QX12.0` |

> Adressen können per IO Engineering API abgefragt werden:
> `GET /devices/Device/ethercatmaster/XB_EC_12/XF71/{ModulName}` → `ioMapping[0].address`

## Bekannte Einschränkungen / Erkenntnisse

### Channel-IDs bei XI110208

Die IoChannel-Einträge im ioMapping des XI110208 haben **leere `id`-Felder**. Das führt dazu, dass beim PUT mit mehreren Kanälen alle Kanäle die Daten des ersten Kanals übernehmen. Dies ist ein bekanntes Verhalten von IoStudio 2.1.0 für dieses Gerät.

**Workaround:** Den Buskoppler (XB-EC-12) zuerst unter `ethercatmaster` anlegen, dann das IO-Modul unter dem `XF71`-Connector des Buskopplers einfügen:

```
POST /devices/Device/ethercatmaster          → XB_EC_12 (XB-EC-12)
POST /devices/Device/ethercatmaster/XB_EC_12/XF71  → DI_Modul (XI110208)
```

### Topologie-Pfade

IO-Module können **nicht direkt** unter `ethercatmaster` eingefügt werden, wenn ein Buskoppler vorhanden ist. Sie müssen unter dem `XF71` (Explicit Connector) des Buskopplers eingefügt werden.

### EtherCAT Master App vs. Instanz

**App installieren reicht nicht!** Nach der Installation der App `rexroth-ethercatmaster` muss zusätzlich eine **Instanz** im Data Layer angelegt werden:

```powershell
$body = @{
    type  = "object"
    value = @{
        request = @{
            instanceName = "ethercatmaster"
            port         = "eth1"
        }
    }
} | ConvertTo-Json -Depth 5

Invoke-RestMethod "https://{IP}/automation/api/v2/nodes/fieldbuses/ethercat/master/instances" `
    -Method POST -Headers $h -Body $body -SkipCertificateCheck
```

Ohne diese Instanz schlägt `TransferFieldbusConfigJob` mit _"EtherCAT-Master-Instanz 'ethercatmaster' ist nicht vorhanden"_ fehl.

### Package Manager API (verifiziert 2026-06-12)

| Endpunkt | Beschreibung |
|---|---|
| `GET /package-manager/api/v1/packages` | Installierte Snaps auflisten ✅ |
| `GET /package-manager/api/v2/applications` | Gibt HTML zurück (UI-Route) ❌ |
| `GET /package-manager/api/v3/applications` | Gibt HTML zurück ❌ |

Immer `Accept: application/json` Header setzen, sonst kommt die Web-UI zurück.

### PDF-Extraktion

Für PDF-Dateien direkt `pdfplumber` verwenden (nicht erst Rohbytes versuchen):

```powershell
pip install pdfplumber -q
python -c "import pdfplumber; ..."
```
