# ctrlX PLC Engineering REST API v2

**Base URL:** `http://localhost:9002/plc/engineering/api/v2`  
**Version:** 2.11.0  
**Swagger UI:** `http://localhost:9002/?url=./plc-engineering-api-v2.json`

> Die API ist nur verfügbar wenn **ctrlX PLC Engineering geöffnet** ist (Port 9002).

---

## Endpoints

```
GET    /device-repositories
POST   /device-repositories/{repositoryName}
GET    /device-repositories/{repositoryName}
DELETE /device-repositories/{repositoryName}/{deviceName}
GET    /devices
POST   /devices
GET    /devices/{path}
PUT    /devices/{path}
DELETE /devices/{path}
POST   /devices/{path}
PATCH  /devices/{path}
GET    /devices/{path}/symbol-config
PUT    /devices/{path}/symbol-config
DELETE /devices/{path}/symbol-config
GET    /devices/{path}/task-config
PUT    /devices/{path}/task-config
DELETE /devices/{path}/task-config
GET    /devices/{path}/task-config/{taskName}
PUT    /devices/{path}/task-config/{taskName}
DELETE /devices/{path}/task-config/{taskName}
GET    /devices/{path}/recipe-manager/{recipeDefinition}/variables
DELETE /devices/{path}/recipe-manager/{recipeDefinition}/variables
POST   /devices/{path}/recipe-manager/{recipeDefinition}/variables
GET    /devices/{path}/recipe-manager/{recipeDefinition}/variables/{name}
DELETE /devices/{path}/recipe-manager/{recipeDefinition}/variables/{name}
PUT    /devices/{path}/recipe-manager/{recipeDefinition}/variables/{name}
GET    /devices/{path}/recipe-manager/{recipeDefinition}/recipes
DELETE /devices/{path}/recipe-manager/{recipeDefinition}/recipes
POST   /devices/{path}/recipe-manager/{recipeDefinition}/recipes
GET    /devices/{path}/recipe-manager/{recipeDefinition}/recipes/{name}
DELETE /devices/{path}/recipe-manager/{recipeDefinition}/recipes/{name}
PUT    /devices/{path}/recipe-manager/{recipeDefinition}/recipes/{name}
GET    /jobs
POST   /jobs
GET    /jobs/{jobId}
GET    /library-repositories
POST   /library-repositories/{repositoryName}
GET    /library-repositories/{repositoryName}
DELETE /library-repositories/{repositoryName}/{libraryDisplayName}
GET    /online-change-memory-reserve
GET    /online-change-memory-reserve/{applicationName}
PUT    /online-change-memory-reserve/{applicationName}
GET    /pous
POST   /pous
GET    /pous/{path}
PUT    /pous/{path}
DELETE /pous/{path}
POST   /pous/{path}
POST   /pous/project-settings/users-groups/user
GET    /pous/project-settings/users-groups/user/{userName}
PUT    /pous/project-settings/users-groups/user/{userName}
DELETE /pous/project-settings/users-groups/user/{userName}
POST   /pous/project-settings/users-groups/group
GET    /pous/project-settings/users-groups/group/{groupName}
PUT    /pous/project-settings/users-groups/group/{groupName}
DELETE /pous/project-settings/users-groups/group/{groupName}
GET    /product/info
GET    /projects/current
```

---

## Job-basierter Workflow

Lange Operationen laufen als Jobs:

1. `POST /jobs` mit jobType + jobParameters → erhält `id`
2. `GET /jobs/{id}` pollen bis `state == "Done"` oder `"Failed"`
3. `jobResultInfo` enthält Ergebnis-Text

### Wichtige Job-Typen

| jobType | Parameter | Beschreibung |
|---------|-----------|-------------|
| `NewProjectJob` | `filePath`, `fileName`, `template` | Neues Projekt (templates: `EmptyProject`, `ctrlXOSARM64`, `ctrlXOSx64`, `EmptyLibrary`, `StandardLibrary`) |
| `ProjectJob` | `action`: `Open`/`Close`/`Save` | Projekt öffnen/schließen/speichern |
| `BuildJob` | `action`: `GenerateCodeJob` | Anwendung kompilieren |
| `ApplicationLoginJob` | `nodeUrl`, `loginOption` | Verbinden (options: `LoginWithOnlineChange`, `LoginWithDownload`, `LoginWithoutAnyChange`) |
| `ApplicationJob` | `nodeUrl`, `action`: `Start`/`Stop`/`Logout` | Starten/Stoppen/Trennen |
| `PreCompileJob` | `action`: `Enable`/`Disable` | Vor/nach Import-Operationen deaktivieren |

---

## POUs / FBs anlegen

`POST /devices/{appPath}` — neues POU unter Application anlegen:

```json
{
  "name": "FB_Counter",
  "elementType": "POU",
  "language": "ST",
  "declaration": "FUNCTION_BLOCK FB_Counter\nVAR_INPUT\n    bStart : BOOL;\n...",
  "implementation": "..."
}
```

**Wichtig:** `elementType` ist immer `"POU"` — Typ wird über Schlüsselwort in `declaration` bestimmt:

| Schlüsselwort | Typ |
|---|---|
| `FUNCTION_BLOCK <name>` | Function Block |
| `PROGRAM <name>` | Programm |
| `FUNCTION <name> : <Typ>` | Funktion |

---

## POU lesen / schreiben

```
GET    /devices/{path}     → declaration + implementation lesen
PUT    /devices/{path}     → schreiben (name + elementType Pflicht)
POST   /devices/{parent}   → neues Kind-Element anlegen
DELETE /devices/{path}     → Element löschen
```

---

## Pfad-Encoding

Pfade mit Leerzeichen müssen URL-encoded werden:

```
Device/Plc Logic/Application  →  Device%2FPlc%20Logic%2FApplication
```

In Python: `urllib.parse.quote("Device/Plc Logic/Application", safe="")`

---

## Python-Snippet (ohne externe Abhängigkeiten)

```python
import urllib.request, urllib.parse, json, time

BASE = "http://localhost:9002/plc/engineering/api/v2"

def api(method, path, body=None):
    data = json.dumps(body).encode() if body else None
    req = urllib.request.Request(
        f"{BASE}{path}", data=data,
        headers={"Content-Type": "application/json"}, method=method)
    with urllib.request.urlopen(req) as r:
        return json.loads(r.read().decode())

def wait_job(jid):
    while True:
        time.sleep(1)
        s = api("GET", f"/jobs/{jid}")
        print(f"  {s['state']} {s['progress']}% | {s.get('jobResultInfo','')}")
        if s["state"] in ("Done", "Failed"):
            return s

def post_job(body):
    return wait_job(api("POST", "/jobs", body)["id"])

def device_path(path):
    return urllib.parse.quote(path, safe="")

# Beispiel: Neues Projekt erstellen
post_job({
    "jobType": "NewProjectJob",
    "jobParameters": {
        "filePath": "C:\\MeinProjekt",
        "fileName": "Demo",
        "template": "ctrlXOSARM64"
    }
})

# FB anlegen
APP = "Device/Plc Logic/Application"
api("POST", f"/devices/{device_path(APP)}", {
    "name": "FB_Demo",
    "elementType": "POU",
    "language": "ST",
    "declaration": "FUNCTION_BLOCK FB_Demo\nVAR_INPUT\n    bEnable : BOOL;\nEND_VAR",
    "implementation": ";"
})

# Speichern
post_job({"jobType": "ProjectJob", "jobParameters": {"action": "Save"}})
```

---

## Bekannte Eigenheiten

- `BuildJob` ohne `action`-Parameter bleibt im State `Running` — korrekt: `action: "GenerateCodeJob"` setzen
- Pfade mit URL-Encoding: `%2F` für `/`, `%20` für Leerzeichen
- Projekt muss offen sein für `/pous`, `/devices`, etc. — sonst 404
- Die Visu kann nur über die IDE angelegt werden, nicht via REST API
