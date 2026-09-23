# Node-RED: S7 lesen → REST-Server senden, bei Ausfall in InfluxDB puffern und nachsenden

Verified on a real ctrlX CORE (Node-RED 4.1.11-ctrlx, node-red-contrib-s7 3.1.3, node-red-contrib-influxdb 0.7.0,
InfluxDB 2 lokal), echte S7 + simulierte S7, 2026-09-22. Vollständiger, anonymisierter Flow:
`cases/reusable/node-red-s7-rest-buffer/`.

## Architektur (ein Tab)

```
Start/Reload/watch(config) → Konfig laden ─┬→ S7-Poller (nodes7, n S7) ─┐
                                           ├→ S7-Simulator             ─┼→ Sammeln je objectId (Upload-Takt)
                                           └───────────────────────────→┘          │
                         REST-Request vorbereiten (Signatur) ← ─────────────────────┘
                                   → http request (senderr:false) → Antwort auswerten
                                        Fehler → In InfluxDB puffern (influxdb batch)
                                        Erfolg → Nachsenden starten → influxdb in → Nachsende-Batch → REST …
```

## Konfiguration aus Dateien (pro Anlage austauschbar)

- Ablage: `userDir/config/` = WebDAV `appdata/node-RED/config/` (manuell hinkopiert).
- Lesen im Function-Node mit lib `fs`, Pfad über `env.get("SNAP_DATA")`.
- `watch`-Node auf den Ordner + `trigger` (2 s entprellen) → automatisches Neuladen bei Dateiänderung.
- Validieren, Defaults setzen, bei Fehler alte Konfiguration behalten und Fehler in `flow.status.config` melden.
- `s7-config.json`: `defaults` + `plcs[]` (je `id`, `host`, `rack`, `slot`, `objectId`, `variables[{name,addr,datapoint}]`,
  optional `enabled`, `simulate`, `cycleTimeMs`, `sendMode`).
- `rest-config.json`: `url`, `publicKey`, `privateKey`, optional `objects[objectId]` mit abweichenden Keys/URL,
  `uploadIntervalMs`, `timeoutMs`, Pufferparameter.
- Schlüssel mit `_` als Kommentare im JSON (`_hint`, `_felder`).

## Senden

- Werte je `objectId` sammeln, alle `uploadIntervalMs` pro objectId genau ein Request.
- `http request`: Methode "set by msg.method", URL leer (aus `msg.url`), Rückgabe Text, **`senderr: false`**
  (sonst kommen Fehler nie am Ausgang an), `msg.requestTimeout` setzen.
- Erfolg = `statusCode` 2xx. Verbindungsfehler liefern `statusCode` wie `ECONNREFUSED`, `EHOSTUNREACH`.

## Puffer in InfluxDB

- Fehlgeschlagener Live-Batch → `influxdb batch` mit Punkten
  `{measurement:"rest_buffer", tags:{dp, seq, obj}, fields:{value}, timestamp: <Messzeit ms>}`, Precision ms.
- `seq` = fortlaufende Batch-Nummer (12-stellig mit Nullen, damit String-Vergleich in Flux funktioniert).
- Zustand im Flow-Context Store **`file`**: `bufferSeq` (letzte vergebene), `bufferCursor` (letzte nachgesendete),
  `bufferPending`, `bufferFailedSeqs`. Überlebt Neustarts.
- InfluxDB-Config-Node des Kunden wiederverwenden (Token liegt nur in `flows_cred.json`).

## Nachsenden

- Auslöser: erster erfolgreicher Live-Request bei `bufferPending` oder periodischer Check (Inject 10 s,
  gedrosselt auf `resendCheckIntervalMs`).
- Flux-Abfrage über `influxdb in` (Query in `msg.query`):
  `from(bucket) |> range(start:-30d) |> filter(_measurement=="rest_buffer" and _field=="value" and seq > "<cursor>")
   |> group() |> sort(columns:["seq","_time"]) |> limit(n:<chunk>)`
- Nur lückenlos aufeinanderfolgende `seq` derselben objectId senden; bei vollem Chunk letzten (evtl. angeschnittenen)
  Batch zurückstellen; Lücke > 60 s → überspringen und in `bufferFailedSeqs` merken.
- Erfolg → `bufferCursor = cursorEnd`, sofort nächsten Chunk holen, bis Abfrage leer → `bufferPending=false`.
- Fehler beim Nachsenden → abbrechen, Cursor bleibt, nächster Check versucht erneut.
- Nachgesendete Punkte bleiben liegen; Aufräumen über Bucket-Retention.

## Testmethode ohne Eingriff beim Kunden-Server

- Kleinen Test-REST-Server auf dem Laptop im selben Netz starten (Python `http.server`, loggt Query + Body),
  `rest-config.json` per WebDAV auf dessen URL umstellen, Server stoppen/starten = Ausfall/Wiederkehr.
- Signatur im Log nachrechnen.
- Simulator (`simulate: true`) erzeugt Werte ohne SPS; mehrere S7 auf verschiedene objectIds testbar.
- Danach Produktivkonfiguration zurückkopieren und Test-Server stoppen.

Ergebnis: 28 s Ausfall → 10 Batches / 220 Werte gepuffert → nach Wiederkehr lückenlos je objectId in
Reihenfolge nachgesendet.

## InfluxDB-UI zeigt "2 Werte alle 10 s"

Kein Fehler. Der Data Explorer aggregiert mit `aggregateWindow(every: v.windowPeriod, fn: mean)`.
Weil `seq` ein Tag ist, ist jeder Batch eine eigene Serie; ein Fenster schneidet meist zwei Batches → zwei Mittelwerte.
Rohdaten: "View Raw Data" oder ohne Aggregation abfragen:
```
from(bucket: "iot") |> range(start: -1h)
  |> filter(fn: (r) => r._measurement == "rest_buffer" and r._field == "value")
  |> group() |> sort(columns: ["_time"])
```
Hinweis Kardinalität: `seq` als Tag erzeugt pro Batch eine Serie (bei 10 s Intervall ca. 8.600 Serien pro Tag Ausfall).
Alternative: `seq` als Feld speichern (erfordert Pivot/Filter auf Feld in der Nachsende-Abfrage).
