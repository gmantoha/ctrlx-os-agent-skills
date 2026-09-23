# Case: Node-RED auf ctrlX – mehrere S7 → signierter REST-Upload mit InfluxDB-Puffer

## Use When

Maschinendaten aus einer oder mehreren Siemens S7 sollen per HTTP an einen REST-Server (Data-Receiver mit
SHA-256-signierter Query) gehen, jede S7 an ihre eigene objectId. Fällt der Server aus, dürfen keine Daten
verloren gehen: Pufferung in der lokalen InfluxDB, Nachsenden in Reihenfolge nach Wiederkehr.
S7- und Server-Konfiguration kommen als Dateien pro Anlage in die App-Daten.

## Environment

ctrlX CORE (real), Node-RED 4.1.11-ctrlx, node-red-contrib-s7 3.1.3 (Bibliothek `@st-one-io/nodes7` 1.1.2),
node-red-contrib-influxdb 0.7.0, InfluxDB 2 lokal (org/bucket `iot`). Kein ctrlX-AI/MCP installiert.
Komplett per Admin API und WebDAV umgesetzt, ohne Editor und ohne SSH.

## Verified Findings

- ctrlX-Token funktioniert direkt an der Node-RED Admin API (`recipes/node-red/admin-api-flows.md`).
- Function-Sandbox ohne `process`/`require`; Pfade über `env.get("SNAP_DATA")` (`reference/apps/node-red/README.md`).
- `s7 endpoint` ist nicht dateikonfigurierbar → `@st-one-io/nodes7` im Function-Node; dafür Registrierung
  im userDir nötig, sonst starten gar keine Flows (`recipes/node-red/function-module-from-palette.md`).
- `http request` mit `senderr: true` liefert Fehler nicht am Ausgang → Pufferung griff zuerst nicht. Fix: `false`.
- Puffer mit Batch-Sequenznummer + Cursor im File-Context ist robust gegen Neustarts und Teilabfragen.
- Scheinbar "falsche" Ablage (2 Werte / 10 s) in der InfluxDB-UI ist nur Aggregation der Anzeige.
- Ein zwischenzeitlicher echter Netzausfall (`EHOSTUNREACH`, ~4,5 min) wurde vollständig gepuffert und nachgesendet.

## Files

- `flow/gen_flow.py` — erzeugt `flow2_nodes.json` (27–30 Nodes inkl. Function-Code). Vor Nutzung `TAB` und
  `INFLUX_CFG` anpassen. `python3 gen_flow.py [modul] [disabled]`.
  Enthält: Konfig laden/validieren, S7-Poller (mehrere S7), Simulator, Sammeln je objectId, Request-Signatur,
  Antwort auswerten, Puffern, Nachsenden, InfluxDB-Fehler, Status, Ereignis-Ringpuffer, Wartungs-Node
  nodes7-Registrierung prüfen/reparieren.
- `config/s7-config.json`, `config/rest-config.json` — Beispielkonfiguration mit Platzhaltern und Feldbeschreibung.

## Deploy

1. Tab anlegen (oder vorhandenen nutzen), `gen_flow.py` ausführen.
2. `GET /node-red/flows`, Nodes mit `z == TAB` ersetzen, mit `rev` und `Node-RED-Deployment-Type: flows` posten.
3. Konfigdateien per WebDAV nach `appdata/node-RED/config/` (`MKCOL` für den Ordner, dann `PUT`).
4. Prüfen: `GET /node-red/context/flow/<TAB>/status` (config, s7, rest, buffer, registration).

## Signatur des Data-Receivers (aus dem Kundenbeispiel)

Query `id, method, public_key, private_key, ts (Unix s als String), nonce (UUID), compressed ("")`;
Hash = SHA-256 über die Werte in alphabetischer Schlüsselreihenfolge aneinandergehängt; `private_key` und `method`
danach entfernen; URL = `<base>/<method>?<query>&hash=...`; Body `{ "<dp>": [{ "dt": "YYYY-MM-DD HH:MM:SS", "value": x }] }`.
