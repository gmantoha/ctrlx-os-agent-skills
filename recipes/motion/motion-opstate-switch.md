# Motion Betriebszustand wechseln (Configuration ↔ Running)

## Anwendungsfall

ctrlX OS zeigt „partially operating" weil Motion App im Zustand `Configuration` ist.
Ziel: Motion zurück in `Running` schalten.

## Aktuellen Zustand lesen

```
GET /automation/api/v2/nodes/motion/state/opstate
```

Mögliche Werte: `Running`, `Configuration`, `Booting`

Zustand der einzelnen Achsen (PLCopen):

```
GET /automation/api/v2/nodes/motion/axs/{AXSNAME}/state/opstate/plcopen
```

Typische Werte: `DISABLED` (normal in Running), `OUTDATED` (in Configuration), `STANDSTILL`, `ERRORSTOP`

## Zustandsübergänge

```
Configuration → Booting → Running
```

Direkt von `Configuration` nach `Running` ist **nicht erlaubt** (`0xf0100001`).
Zwischenschritt über `Booting` ist zwingend erforderlich.

## Schritt 1: Configuration → Booting

```
POST /automation/api/v2/nodes/motion/cmd/opstate
Body: {"type":"string","value":"Booting"}
```

Erfolgsantwort: `{"type":"string","value":"Booting"}`

## Schritt 2: Warten bis Booting abgeschlossen

Polling (alle 2 Sekunden):

```
GET /automation/api/v2/nodes/motion/state/opstate
```

Wenn der Wert nicht mehr `Booting` ist (typisch nach 2–5 Sekunden), weiter mit Schritt 3.

## Schritt 3: Booting → Running

```
POST /automation/api/v2/nodes/motion/cmd/opstate
Body: {"type":"string","value":"Running"}
```

## Verifizieren

```
GET /automation/api/v2/nodes/motion/state/opstate
→ "Running"

GET /automation/api/v2/nodes/motion/axs/{AXSNAME}/state/opstate/plcopen
→ "DISABLED"  (normal, warten auf Power-Enable durch SPS)
```

`DISABLED` ist der korrekte Ausgangszustand nach dem Hochfahren.
Die Achsen werden durch das PLC-Programm per `Power`-Kommando aktiviert.

## Hinweise

- `motion/cmd/opstate` unterstützt nur `POST` (onCreate), kein `GET` / `PUT`.
- `GET` auf `motion/cmd/opstate` liefert `DL_UNSUPPORTED` — das ist normal.
- Nach dem Wechsel in Running werden ungespeicherte Konfigurationsänderungen **nicht** automatisch verworfen.
- ctrlX OS zeigt „partially operating" solange Motion in `Configuration` ist.
