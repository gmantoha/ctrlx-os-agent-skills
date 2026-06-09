# Oscilloscope Instance einrichten und starten

Lernquelle: UI-Tracking am echten Gerät (192.168.1.1), Kanal-Konfiguration per Browser beobachtet via Data Layer Diff.

## Überblick

Das Oszilloskop wird über den ctrlX Data Layer konfiguriert. Die wichtigste Erkenntnis aus dem UI-Tracking:
- Kanäle müssen als **NRT** (nicht RT) angelegt werden
- Channel-Namen werden als **Typ+Signal+AutoID** vergeben (z.B. `NRTvel8`)
- Das **`alias`-Feld** muss identisch mit `source` gesetzt werden
- Der **Trigger `name`** muss auf den Channel-Namen verweisen (nicht den Signal-Pfad)
- `diagramview`-Einträge werden **automatisch** erstellt wenn Kanäle existieren — nicht manuell schreibbar

## Schritt 1: Instanz erstellen

```http
POST /automation/api/v2/nodes/oscilloscope/instances
Content-Type: application/json

{"type":"string","value":"wienerOsc"}
```

> Name: nur camelCase, keine Bindestriche oder Unterstriche.

## Schritt 2: Buffer konfigurieren

```http
PUT /automation/api/v2/nodes/oscilloscope/instances/wienerOsc/cfg/buffer
Content-Type: application/json

{
  "type": "object",
  "value": {
    "bufferType": "SINGLESHOT",
    "recordingInterval": {"value": 1000000},
    "recordingTime":     {"value": 5000000000}
  }
}
```

Zeiten in Nanosekunden: `1000000` = 1 ms, `5000000000` = 5 s.

## Schritt 3: Kanäle hinzufügen (POST je Kanal)

```http
POST /automation/api/v2/nodes/oscilloscope/instances/wienerOsc/cfg/channels
Content-Type: application/json

{
  "type": "object",
  "value": {
    "name":   "NRTpos6",
    "alias":  "motion/axs/WIENERAXS/state/values/actual/pos",
    "source": "motion/axs/WIENERAXS/state/values/actual/pos",
    "type":   "NRT",
    "unit":   "mm"
  }
}
```

Wichtig:
- `alias` = `source` (identisch setzen)
- `type` = `"NRT"` (nicht `"RT"`)
- Channel-Name frei wählbar, UI verwendet Schema `NRT<signal><id>`

## Schritt 4: Trigger setzen

```http
PUT /automation/api/v2/nodes/oscilloscope/instances/wienerOsc/cfg/trigger
Content-Type: application/json

{
  "type": "object",
  "value": {
    "triggerType": "RisingEdge",
    "name":        "NRTvel8",
    "level":       "100",
    "preTrigger":  0.0
  }
}
```

- `name`: Channel-Name (nicht Data Layer Pfad!)
- `triggerType`: `Manual` | `RisingEdge` | `FallingEdge` | `Level` | `RisingLevel` | `FallingLevel` | `RisingFalling`
- `level`: als String

## Schritt 5: Starten

```http
POST /automation/api/v2/nodes/oscilloscope/instances/wienerOsc/cmd/start
Content-Type: application/json

{"type":"bool8","value":true}
```

## State-Werte

| Wert | Bedeutung |
|------|-----------|
| 1    | Idle / bereit |
| 2    | Armed / wartet auf Trigger |
| 3    | Recording (läuft) |
| 4    | Done / Daten verfügbar |

```http
GET /automation/api/v2/nodes/oscilloscope/instances/wienerOsc/state/opstate
```

## Schritt 6: Aufzeichnung lesen

```http
GET /automation/api/v2/nodes/oscilloscope/instances/wienerOsc/rec-values/allsignals
```

## Schritt 4b: Diagram-Views anlegen (Pflicht vor Start!)

Views müssen **vor dem Start** angelegt werden — sonst schlägt `cmd/start` mit `DL_SUBMODULE_FAILURE` fehl.
Das `color`-Feld ist **Pflicht** (ohne Farbe → Flatbuffer-Deserialisierungsfehler).

```http
POST /automation/api/v2/nodes/oscilloscope/instances/wienerOsc/cfg/diagrams/Diagram_0/views
Content-Type: application/json

{
  "type": "object",
  "value": {
    "source": "NRTpos1",
    "color": "#9789f4",
    "visible": true,
    "connectionType": "LINE"
  }
}
```

Für jeden Kanal einmal wiederholen. Farben frei wählbar (Hex).

## Bekannte Fehler

| Fehler | Ursache | Lösung |
|--------|---------|--------|
| `DL_TYPE_MISMATCH` bei `cfg/diagrams/.../views` POST | `color`-Feld fehlt | `color` als Hex-String mitgeben (Pflichtfeld!) |
| `DL_SUBMODULE_FAILURE` bei `cmd/start` | Kanäle als RT statt NRT, oder keine Views angelegt | Kanäle als `"type":"NRT"` und Views mit `color` anlegen |
| WebDAV PUT → 400 | Datei ist während aktiver Instanz gesperrt | Instanz erst löschen (DELETE), dann Datei schreiben, dann neu erstellen |
| `DL_INVALID_VALUE` bei Instanzname | Bindestriche oder Unterstriche im Namen | Nur camelCase verwenden |
| DELETE Instanz → `DL_FAILED` | Instanz läuft noch | Erst `cmd/stop` senden, dann 1–2 s warten, dann DELETE |
| `DL_TYPE_MISMATCH: unknown enum value: CIRCULAR` | `bufferType: "CIRCULAR"` nicht gültig | Nur `"SINGLESHOT"` verwenden |
| `DL_INVALID_ADDRESS` bei `rec-values/{channelName}` | Kanal-Einzelabruf nicht unterstützt | Nur `rec-values/allsignals` verwenden |
| Diagramm heißt `Diagram_1`, nicht `Diagram_0` | Automatische Benennung beginnt bei 1 | Vor dem Views-POST immer `cfg/diagrams?type=browse` abfragen |

---

## ⚠ Bekanntes Problem: SINGLESHOT + NRT bleibt in State 3

**Symptom:** `state/opstate` bleibt dauerhaft auf `3` (Recording), erreicht nie `4` (Done).  
`rec-values/allsignals` liefert 1 leeres Sample — auch nach Ablauf der `recordingTime`.

**Ursache (Stand 2026-06-09, ctrlX OS 4.6):** NRT-Kanäle subscriben auf Data Layer Updates — nicht auf RT-Takt. SINGLESHOT erwartet offenbar eine RT-Quelle um den Puffer vollzuschreiben. Das Fenster läuft nie ab.

**Workaround:** Oszi nach der Bewegung manuell per `cmd/stop` beenden, dann `allsignals` lesen. Die Daten sind dann vorhanden (State nach Stop = 1, nicht 4).

```powershell
# Bewegung abwarten
do { Start-Sleep 1; $plc = ... } while ($plc -eq "DISCRETE_MOTION")

# Oszi stoppen
Invoke-RestMethod ".../cmd/stop" -Method POST -Headers $h -SkipCertificateCheck -Body '{"type":"bool8","value":true}' | Out-Null
Start-Sleep 2

# Daten lesen
$data = Invoke-RestMethod ".../rec-values/allsignals" -Headers $h -SkipCertificateCheck
```

**TODO:** Mit RT-Kanälen testen — möglicherweise funktioniert SINGLESHOT nur mit `"type":"RT"`.

