# Antwort: USB-Mount via ctrlX PLC Engineering (ST-Code)

**Datum:** 2026-04-20  
**Bezug:** Kundenanfrage — HTTP-REST-Request aus SPS für USB-Mount

---

## Kurzantwort

Der Umweg über HTTP/REST aus der SPS ist **nicht erforderlich** und auch nicht der empfohlene Weg.

Ab **ctrlX OS 4.4** stellt der `rexroth-deviceadmin`-Snap die USB-Mount-Funktion direkt über den **ctrlX Data Layer** bereit. Der Aufruf erfolgt mit dem Funktionsbaustein **`DL_Call`** aus der in ctrlX PLC Engineering enthaltenen Bibliothek **`CXA_DataLayer`** — keine Zusatzlibrary, kein HTTP, kein TLS, keine Token-Verwaltung.

Das auf dem Testgerät (ctrlX M4, OS 4.6) verifizierte Ergebnis der Device-Probe:

| Data-Layer-Knoten | Operation | Beschreibung |
|---|---|---|
| `system/resources/tasks/storage/mountDevice` | POST (DL_Create) | USB-Stick mounten |
| `system/resources/tasks/storage/unmount` | POST (DL_Create) | USB-Stick sicher entfernen |
| `system/resources/storage` | GET (DL_Read) | Aktuelle Mount-Zustände aller Speichermedien |

---

## Konkrete Beantwortung Ihrer vier Fragen

### Frage 1: Welche CODESYS-Bibliothek für REST API Calls (HTTP POST/GET)?

**Es gibt keine von Bosch Rexroth offiziell empfohlene und unterstützte HTTP-Client-Bibliothek für ctrlX PLC Engineering.**

Die im CODESYS-Store erhältlichen HTTP-Client-Libraries (3S, OSCAT, kommerzielle Anbieter) sind:
- nicht für ctrlX PLC Engineering zertifiziert
- erfordern manuelles HTTPS/TLS-Handling (selbstsigniertes Zertifikat des ctrlX)
- erfordern Session-Token-Management (OAuth2 Bearer Token)
- nicht von Bosch Rexroth supportet

Für die konkrete Aufgabe (USB-Mount) ist dieser Weg **unnötig**. Für andere Anwendungsfälle, die echte externe HTTP-Calls erfordern, empfiehlt sich die Architektur via Node-RED (siehe unten).

### Frage 2: Welcher Funktionsbaustein für den Mount-Aufruf?

**`DL_Create`** aus der Bibliothek **`CXA_DataLayer`** (in ctrlX PLC Engineering standardmäßig enthalten):

- **Knoten:** `system/resources/tasks/storage/mountDevice`
- **Datentyp:** JSON-Objekt (wird in ctrlX PLC Engineering als `DL_STRING` übergeben)
- **Pflichtfelder:**
  - `media`: UUID des Mediums (z. B. `"3C20-2F7A"`) — aus `system/resources/storage` lesbar
  - `device`: Gerätename der Partition (z. B. `"sdb1"`)
  - `assignment`: `"DataExchange"` (für Datenaustausch, USB-Stick) oder `"StorageExtension"` (verschlüsselte Erweiterung, gerätegebunden)

**Für sicheres Entfernen:**
- **Knoten:** `system/resources/tasks/storage/unmount`
- **Pflichtfelder:** `media` und `device`

**Status abfragen (vor dem Mount):**
- **Knoten:** `system/resources/storage`
- **Operation:** `DL_Read`
- Liefert alle Medien mit `mounted: true/false`, `uuid`, `device`

Ein minimales ST-Beispiel finden Sie in der beigelegten Datei **`st-snippet-dl-call.st`**.

### Frage 3: SPS direkt, HMI oder externe Runtime — was ist Best Practice?

| Ansatz | Aufwand | Offiziell | Empfehlung |
|---|---|---|---|
| **SPS via Data Layer `DL_Create`** (≥ OS 4.4) | gering | ja | **Primär — genau dieser Weg** |
| HMI/WebIQ mit `fetch()` direkt gegen `/storage/api/v1/tasks` | mittel | ja | Alternativ, wenn HMI ohnehin im Einsatz |
| Node-RED als Vermittler, SPS-Trigger via Data Layer | mittel | ja | Für allgemeine HTTP-Calls zu externen Diensten |
| CODESYS-Store HTTP-Client-Library aus ST | hoch | **nein** | Nicht empfohlen |
| Eigener ctrlX-Snap (Python/Go) | hoch | ja | Nur bei komplexem, generischem Bedarf |
| SysSocket / TCP Roh-HTTP(S) | sehr hoch | nein | **Abraten** |

**Fazit:** Für USB-Mount ist der SPS-Data-Layer-Weg der sauberste und einfachste. Für echte HTTP-Calls zu externen Diensten (z. B. REST-API einer Prüfstandsoftware) ist Node-RED als Brücke der Best-Practice-Ansatz.

### Frage 4: Minimales ST-Beispiel

Siehe beiliegende Datei **`st-snippet-dl-call.st`**.

---

## Wichtiger Versionshinweis

Die Data-Layer-Knoten `system/resources/tasks/storage/mountDevice` und `unmount` **erfordern ctrlX OS 4.4 oder höher** (rexroth-deviceadmin ≥ 4.4).

Vor dem Einsatz bitte bestätigen, welche Version auf der Ziel-ctrlX X3 läuft:
- Weboberfläche → `Settings` → `About` → Versionsanzeige
- Oder: Data-Layer-Knoten `system/about` lesen

Auf dem Testgerät (ctrlX M4, `rexroth-deviceadmin 4.6.0`, ctrlX OS 4.6 auf Ubuntu Core 24) wurden die Knoten am 2026-04-20 verifiziert — sie existieren und reagieren korrekt auf POST-Requests (mit angestecktem USB-Medium wird der Mount ausgeführt).

---

## UUID des USB-Sticks ermitteln

Bevor der Mount ausgelöst werden kann, muss die UUID des eingesteckten Sticks bekannt sein. Es gibt zwei Wege:

**Option A (empfohlen): SPS liest `system/resources/storage` via `DL_Read`**

Der Knoten liefert eine Liste aller Medien. In der SPS kann über die zurückgegebene JSON-Struktur die UUID des nicht gemounteten externen Mediums (`mounted = false`) extrahiert werden.

**Option B: Feste UUID**

Wenn stets derselbe USB-Stick verwendet wird, kann die UUID vorab per REST einmalig ausgelesen und fix im SPS-Programm hinterlegt werden:

```
GET https://<IP>/storage/api/v1/media
Authorization: Bearer <token>
```

Antwortbeispiel (aus der ursprünglichen Rexroth-Antwort):
```json
[
  {"uuid":"7d60b16f-...","label":"ubuntu-data","mounted":true,"format":"ext4","device":"sda6","internal":true},
  {"uuid":"3C20-2F7A","mounted":false,"format":"fat32","size":15726542848,"device":"sdb1","parent":"sdb"}
]
```

---

## Fallback: ctrlX OS < 4.4

Falls der Ziel-Controller eine ältere OS-Version trägt und kein Update möglich ist, empfehlen wir **Node-RED als HTTP-Vermittler**:

1. Node-RED App installieren (ctrlX Store)
2. Im Node-RED-Flow: Data-Layer-Input-Knoten (Trigger vom SPS) → HTTP-Request-Knoten (POST gegen `/storage/api/v1/tasks`) → Data-Layer-Output-Knoten (Status zurück zur SPS)
3. Token-Verwaltung liegt vollständig in Node-RED

Node-RED hat direkten Zugriff auf den ctrlX-Localhost und kann den Bearer Token über einen separaten Auth-Request beziehen.

Community-Referenz für Node-RED + USB-Mount:  
https://community.boschrexroth.com/ctrlx-core-25gnfzl4/post/mount-and-remove-safety-usb-from-datalayer-plc-or-node-red-5fn56hKDAZRATPF

---

## Alternativer Betriebsweg ohne Programmierung (Zero-Code-Workaround)

Falls weder Data Layer noch Node-RED kurzfristig realisierbar sind: Im ctrlX-Webinterface kann ein **eingeschränkter Benutzer** mit ausschließlich `storage`-Berechtigung angelegt werden. Dieser User sieht in der Weboberfläche nur den Storage-Bereich und kann den USB-Stick mounten/entfernen.

Der WebVisu-Baustein `WebBrowser` in CODESYS ermöglicht es, dieses eingeschränkte Webinterface direkt in die eigene Visualisierung einzubetten — ohne dass der Bediener URL oder Benutzername kennen muss.

Dieser Weg ist eine pragmatische Notlösung; er gibt dem Bediener dennoch indirekten Zugang zur ctrlX-Weboberfläche.
