# Analyse: ctrlx-linck-linckdc apidata-Crash vom 17.04.2026

**Plattform:** Bosch Rexroth ctrlX M4 (ARM64), Kernel `6.1.80-rt26-ctrlx-43`  
**Betroffener Snap:** `ctrlx-linck-linckdc` (Revision x12)  
**Betroffener Service:** `snap.ctrlx-linck-linckdc.apidata.service`  
**Logquelle:** Loki/Grafana-Export, 782 Eintraege, Geraetezeit ~11:19 bis ~11:33 UTC  
**Analysedatum:** 17.04.2026

---

## Zusammenfassung

Der `apidata`-Service des Linck-Snaps ist **nicht** durch einen OOM-Kill abgestuerzt, sondern durch einen **InfluxDB-Timeout** waehrend einer blockierenden TSM-Cache-Snapshot-Operation. InfluxDB war fuer ca. 31 Sekunden nicht ansprechbar, was zu kaskadenartigen Fehlern im gesamten System fuehrte.

---

## Ursachenkette

```
InfluxDB TSM Cache-Snapshot auf langsamer eMMC/SD (31s blockierend)
  --> Alle Lese-/Schreibzugriffe auf Port 8086 laufen in Timeout (10s)
    --> API-Poller-Thread: ReadTimeoutError in find_bucket_by_name() --> Thread-Crash
    --> DCPoller: Leere Messwerte, kein Publish
    --> apidata-Service versucht Neustart
      --> InfluxDataBaseHandler.__init__() --> find_authorizations() --> ReadTimeoutError
        --> Prozess-Exit mit Status 1/FAILURE
```

---

## Detaillierte Zeitleiste (Geraetezeit UTC)

| Zeit (UTC) | Ereignis | Schwere |
|---|---|---|
| 11:19 -- 11:31:41 | Normalbetrieb: DCPoller und API-Poller arbeiten fehlerfrei | OK |
| 11:31:39 | InfluxDB Retention-Policy-Check (1,9 ms) | OK |
| 11:32:28 | **InfluxDB TSM Cache-Snapshot startet** | Kritisch |
| 11:31:52 | Token-Verifier-Timeouts beginnen (Symptom der Systemlast) | Symptom |
| ~11:32:00 | MQTT: `packet queue is empty, aborting` | Warnung |
| ~11:32:00 | `(Storage) Could not query database: ReadTimeoutError` (Port 8086) | Fehler |
| ~11:32:00 | DCPoller: `Measurements values is None` -- kein Publish | Fehler |
| ~11:32:12 | **API-Poller-Thread stuerzt ab** (`ReadTimeoutError` in `bucket_api.find_bucket_by_name`) | Fehler |
| ~11:32:12 | `(API-Poller) Poller isn't running anymore. Establish new connection in 10 seconds...` | Fehler |
| 11:32:31 | Data-Layer-Provider wird wegen Inaktivitaet getrennt (Systemstress) | Warnung |
| ~11:32:32 | `(Storage) Could not write in database: ReadTimeoutError` (mehrfach) | Fehler |
| ~11:32:55 | apidata-Neustart schlaegt fehl: `find_authorizations()` --> `ReadTimeoutError` | Fehler |
| ~11:32:55 | `(Storage) Database ... is currently not available. Storing data in a temporary file.` | Warnung |
| ~11:32:55 | **`apidata.service: Main process exited, code=exited, status=1/FAILURE`** | Kritisch |
| 11:32:58 | Cache-Snapshot endet nach **31.000 ms** | Info |
| 11:32:58 | TSM-Kompaktierung startet (8 Dateien, Level 1) -- endet nach 698 ms | Info |
| 11:33:01 | Token-Validation Broken Pipes (~30 Stueck), Scheduler-Fehler, DL_TIMEOUT | Symptom |

---

## Relevante Log-Auszuege

### Cache-Snapshot (Grundursache)

```
ts=2026-04-17T11:32:28.407667Z lvl=info msg="Cache snapshot (start)" service=storage-engine engine=tsm1
ts=2026-04-17T11:32:58.416387Z lvl=info msg="Snapshot for path written" path=/media/mmcblk1p1/ctrlx-influxdb/common/engine/data/0a595a6a7e691014/autogen/197 duration=31000.408ms
```

### API-Poller-Thread-Crash

```
(Storage) Could not query database: ReadTimeoutError("HTTPConnectionPool(host='127.0.0.1', port=8086): Read timed out. (read timeout=9.99919076700462)")
Exception in thread Thread-1 (loop):
  File ".../linckapi/poller/poller.py", line 215, in loop
    results = self.influxdb.query_data("linckapi", self.start_period, self.stop_period)
  File ".../utils/db.py", line 601, in query_data
    if not self.connected or not self.bucket_api.find_bucket_by_name(bucket):
urllib3.exceptions.ReadTimeoutError: HTTPConnectionPool(host='127.0.0.1', port=8086): Read timed out.
```

### apidata-Service-Exit

```
  File ".../linckapi/poller/poller.py", line 361, in main
    poller_thread = create_poller()
  File ".../linckapi/poller/poller.py", line 334, in create_poller
    poller = DataPoller()
  File ".../linckapi/poller/poller.py", line 138, in __init__
    self.influxdb = InfluxDataBaseHandler(url)
  File ".../utils/db.py", line 309, in __init__
    self.influx_client.authorizations_api().find_authorizations()
urllib3.exceptions.ReadTimeoutError: HTTPConnectionPool(host='127.0.0.1', port=8086): Read timed out.

snap.ctrlx-linck-linckdc.apidata.service: Main process exited, code=exited, status=1/FAILURE
```

---

## Bewertung: Was ist NICHT die Ursache

| Log-Eintrag | Bewertung |
|---|---|
| `apparmor="DENIED" ... net_admin` | Normales Snap-Sicherheitsereignis, kein Einfluss auf den Crash |
| `error send Events: ... proxy.sock: connection refused` | Vorbestehendes Problem (tritt alle 60s auf, auch im Normalbetrieb) |
| `Verifier timeout` (080F0602) | Nachgelagertes Symptom der Systemueberlastung |
| Token-Validation Broken Pipes | Nachgelagert -- Auth-Sockets brechen wegen Systemstress ab |
| `COMPACTION is disabled` / OOM | **Nicht vorhanden in diesen Logs** |

---

## Handlungsempfehlungen fuer Linck

### 1. Fehlertoleranz im apidata-Service erhoehen (Prioritaet hoch)

Der Service stuerzt bei einem InfluxDB-Timeout waehrend der Initialisierung unwiderruflich ab. Betroffene Stellen:

- **`utils/db.py:309`** -- `InfluxDataBaseHandler.__init__()` ruft `find_authorizations()` ohne Try/Except auf
- **`poller/poller.py:138`** -- `DataPoller.__init__()` ruft `InfluxDataBaseHandler(url)` ohne Retry-Logik auf
- **`poller/poller.py:334`** -- `create_poller()` faengt den Fehler nicht ab
- **`poller/poller.py:361`** -- `main()` hat keinen Retry-Loop um `create_poller()`

**Vorschlag:** Retry-Mechanismus mit exponentiellem Backoff in `main()` einbauen, damit der Service bei temporaeren InfluxDB-Ausfaellen nicht sofort terminiert.

### 2. API-Poller-Thread absichern (Prioritaet hoch)

- **`poller/poller.py:215`** (`loop`-Methode) und **`utils/db.py:601`** (`query_data`) -- ein `ReadTimeoutError` in `find_bucket_by_name()` fuehrt zum vollstaendigen Thread-Crash
- Der Poller meldet zwar `Poller isn't running anymore`, aber der Wiederherstellungsversuch nach 10 Sekunden scheitert ebenfalls, wenn InfluxDB noch blockiert ist

**Vorschlag:** `ReadTimeoutError` in der Polling-Schleife abfangen und mit Backoff wiederholen, statt den Thread abstuerzen zu lassen.

### 3. InfluxDB-Konfiguration pruefen (Prioritaet mittel)

Der 31-Sekunden-Cache-Snapshot auf `/media/mmcblk1p1` (eMMC/SD) deutet auf I/O-Engpaesse hin. Moegliche Massnahmen:

- **`cache-snapshot-write-cold-duration`** reduzieren, damit Snapshots haeufiger aber kleiner ausfallen
- **`cache-max-memory-size`** begrenzen, um die Datenmenge pro Snapshot zu reduzieren
- **Retention-Policies** pruefen -- das Shard `autogen/197` mit 8 TSM-Dateien (Index 469-476) zeigt erhebliche Datenakkumulation

### 4. Vorbestehendes Problem: rda-proxy-service (Prioritaet niedrig, nicht Linck-spezifisch)

Die Fehlermeldung `proxy.sock: connect: connection refused` tritt alle 60 Sekunden auf und betrifft den `rexroth-deviceadmin`-Snap. Dies ist ein separates Problem auf der ctrlX-Plattform, nicht im Linck-Snap.

---

## Betroffene Dateien im Snap (Revision x12)

| Datei | Relevante Zeile(n) | Thema |
|---|---|---|
| `lib/python3.10/site-packages/linckapi/poller/poller.py` | 138, 215, 334, 361 | Fehlende Fehlerbehandlung bei InfluxDB-Timeouts |
| `lib/python3.10/site-packages/utils/db.py` | 309, 601 | Keine Retry-Logik bei Verbindungsaufbau und Abfragen |

---

*Erstellt auf Basis der Logdatei `Explore-logs-2026-04-17 13_36_22.txt` (Loki/Grafana-Export).*
