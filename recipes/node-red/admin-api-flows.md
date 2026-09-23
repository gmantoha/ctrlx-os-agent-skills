# Node-RED Flows per Admin API lesen, anlegen, deployen und diagnostizieren

Verified on a real ctrlX CORE, Node-RED 4.1.11-ctrlx, 2026-09-22.

## Ziel

Flows auf der ctrlX ohne Browser anlegen oder ändern, deployen und den laufenden Zustand prüfen.

## Voraussetzungen

- ctrlX-Token: `recipes/rest-api/connect-with-token.md`. Der Token wird von `/node-red/*` direkt akzeptiert.
- Token wiederverwenden und am Ende mit `DELETE /identity-manager/api/v2/auth/token` freigeben (Session-Limit).
- Flow-Änderungen sind persistente Änderungen: vor dem Deploy auf einem echten Gerät bestätigen lassen.

## Endpunkte

| Zweck | Methode | Pfad | Hinweis |
|---|---|---|---|
| Alle Flows + Revision | GET | `/node-red/flows` | Header `Node-RED-API-Version: v2` → `{"flows":[...],"rev":"..."}` |
| Deploy | POST | `/node-red/flows` | Body `{"flows":[...],"rev":"<rev>"}`, Header `Node-RED-Deployment-Type` |
| Laufzustand | GET | `/node-red/flows/state` | `{"state":"start"}` |
| Installierte Nodes | GET | `/node-red/nodes` | Header `Accept: application/json` |
| Settings | GET | `/node-red/settings` | Version, Context-Stores, Sandbox-Settings |
| Flow-Context lesen | GET | `/node-red/context/flow/<tab-id>/<key>` | optional `?store=file` |
| Node-Context lesen | GET | `/node-red/context/node/<node-id>` | alle Stores |
| Inject auslösen | POST | `/node-red/inject/<inject-node-id>` | wie Klick auf den Inject-Button |

`Node-RED-Deployment-Type`:
- `nodes`: nur geänderte Nodes werden neu gestartet (Standard für Änderungen, andere Flows laufen weiter).
- `flows`: geänderte Flows komplett neu starten (nötig, wenn Function-`libs` neu geladen werden müssen).
- `full`: alles neu starten.

## Ablauf: neuen Tab anlegen

1. `GET /node-red/flows` → `flows` und `rev` merken.
2. Neue Nodes anhängen: ein Node `{"id":"<16 hex>","type":"tab","label":"Flow 2","disabled":false}`
   und die Nodes mit `"z":"<tab-id>"`. Bestehende Nodes unverändert übernehmen.
3. `POST /node-red/flows` mit `{"flows": alt + neu, "rev": rev}` und `Node-RED-Deployment-Type: nodes`.
4. Antwort enthält die neue `rev`. Mit `GET /node-red/flows` gegenprüfen, dass die alten Nodes unverändert sind.

Einen Tab deaktivieren: beim Tab-Node `"disabled": true` setzen. Einzelnen Node deaktivieren: `"d": true`.

Deterministische, sprechende IDs (z. B. `f2collect0000001`) erleichtern späteres Ersetzen:
"alle Nodes mit `z == <tab>` entfernen, neue Liste anhängen, deployen".

## Beispiel (bash)

```bash
IP=192.168.1.1
TOKEN=$(curl -sk -X POST https://$IP/identity-manager/api/v2/auth/token -H "Content-Type: application/json" \
  -d '{"name":"<user>","password":"<pw>"}' | python3 -c 'import sys,json;print(json.load(sys.stdin)["access_token"])')
H=(-H "Authorization: Bearer $TOKEN" -H "Node-RED-API-Version: v2")
curl -sk "${H[@]}" https://$IP/node-red/flows > flows_cur.json
python3 - <<'PY'
import json
d = json.load(open("flows_cur.json"))
tab = "f2example0000001"
keep = [n for n in d["flows"] if n.get("z") != tab and n["id"] != tab]
new = [{"id": tab, "type": "tab", "label": "Flow 2", "disabled": False, "info": "", "env": []},
       {"id": "f2inject00000001", "type": "inject", "z": tab, "name": "alle 10s", "props": [{"p": "payload"}],
        "repeat": "10", "once": True, "onceDelay": 0.1, "payloadType": "date", "x": 150, "y": 100,
        "wires": [["f2debug000000001"]]},
       {"id": "f2debug000000001", "type": "debug", "z": tab, "name": "debug", "active": True, "tosidebar": True,
        "complete": "payload", "targetType": "msg", "x": 400, "y": 100, "wires": []}]
json.dump({"flows": keep + new, "rev": d["rev"]}, open("flows_new.json", "w"))
PY
curl -sk -X POST "${H[@]}" -H "Content-Type: application/json" -H "Node-RED-Deployment-Type: nodes" \
  --data-binary @flows_new.json https://$IP/node-red/flows
curl -sk -X DELETE -H "Authorization: Bearer $TOKEN" https://$IP/identity-manager/api/v2/auth/token
```

## Diagnose ohne Editor

Die Debug-Sidebar ist über die API nicht lesbar. Bewährt hat sich:

- Function-Nodes schreiben ihren Zustand in den Flow-Context (z. B. `flow.set("status", {...})`) oder
  einen Ringpuffer `events` (letzte ~60 Ereignisse). Lesen per `GET /node-red/context/flow/<tab>/status`.
- Die Antwort ist `{"msg":"<JSON-String>","format":"Object"}` → `json.loads(r["msg"])`.
  Nicht gesetzte Keys liefern `{"msg":"(undefined)","format":"undefined"}`.
- Aktionen über `POST /node-red/inject/<id>` auslösen (Status sammeln, Nachsenden, Reparatur …).

## Temporäre Probe-Nodes (Geräte-Erkundung)

Um Pfade, Netzwerkerreichbarkeit oder Dateien vom Node-RED-Prozess aus zu prüfen, einen temporären
Tab/Node mit `inject (once)` → `function` deployen, Ergebnis in den Flow-Context schreiben, lesen,
Probe-Nodes wieder entfernen. Beispiele:
- TCP-Erreichbarkeit mit lib `net` (`new net.Socket().connect(port, host)`, Timeout 3 s) — zeigt, ob S7 (102),
  REST-Server oder lokale InfluxDB (8086) aus Sicht der ctrlX erreichbar sind.
- Dateien mit lib `fs` nach `userDir/<tmp>/` kopieren und per WebDAV herunterladen (z. B. Quellcode von
  Palette-Nodes lesen). Temporäre Ordner danach per WebDAV `DELETE` entfernen.
- In der Function-Sandbox kein `process`: Umgebung über `env.get(...)`.

Auf einem Kundengerät jede Probe vorher ankündigen und danach aufräumen.
