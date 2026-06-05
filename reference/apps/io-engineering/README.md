# ctrlX WORKS IO Engineering

ctrlX WORKS IO Engineering (IoStudio) ist das PC-basierte Engineering-Tool für die ctrlX I/O-Familie. Es läuft lokal auf dem Engineering-PC und stellt eine REST API bereit.

## API-Dokumentation

| Quelle | URL |
|--------|-----|
| OpenAPI-Übersicht (alle ctrlX WORKS APIs) | https://boschrexroth.github.io/rest-api-description/ctrlx-automation/ctrlx-works/index.html |
| IO Engineering OpenAPI JSON (v2.10.0) | https://boschrexroth.github.io/rest-api-description/ctrlx-automation/ctrlx-works/io-engineering/io-engineering.v2.10.0.openapi.json |
| REST API Upstream Repository | https://github.com/boschrexroth/rest-api-description |

> **Hinweis:** Die OpenAPI-Spezifikation beschreibt Version 2.10.0. Die installierte Software kann eine ältere Version sein (z.B. 2.1.0). Einige Felder oder Jobs können dann abweichen.

## Lokale Basis-URL

```
http://localhost:{port}/io/engineering/api/v2
```

Der Port muss bei der Installation gewählt werden. Typisch: `9003`.

## Installationsort

```
C:\Program Files\Rexroth\ctrlX WORKS(1)\StudioIo\Common\ctrlX-IO-Engineering.exe
```

## Geräte-Cache

Gerätebeschreibungen (ESI-XMLs, device.xml) liegen unter:

```
C:\ProgramData\Rexroth\WRK-V-0204\0\Studio\Devices\
```

Unterordner-Schema: `{deviceType}\{deviceId}\{encodedVersion}\`

- `deviceType 65` = EtherCAT Slave
- ctrlX IO-Geräte haben IDs der Form `24_00242A*`

## Projekt-Templates

Beim Anlegen neuer Projekte über `POST /jobs` mit `NewProjectJob`:

| Template-Key | Beschreibung |
|---|---|
| `ctrlXCOREIO` | Standardprojekt für ctrlX I/O (ctrlX CORE I/O Configuration) |

> **Achtung:** Der in der OpenAPI-Spezifikation genannte Beispiel-Key `ctrlXOSIO` funktioniert **nicht**. Der korrekte Key `ctrlXCOREIO` wurde durch String-Extraktion aus `Studio.RestApi.dll` ermittelt.

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
| XI422204 | `24_00242A0700000100` | 4-Kanal Analog Output |
| XI412204 | `24_00242A0800000100` | 4-Kanal Analog Input |

Version-String immer: `Revision=16#00000100` (außer XB-EC-31: `16#00000200`)

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
