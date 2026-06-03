# Motion Axis Velocity Limits ändern

## Anwendungsfall

Geschwindigkeitslimits einer Achse per REST Data Layer ändern und dauerhaft speichern.

## Voraussetzungen

- ctrlX OS mit Motion App installiert
- Motion in Zustand `Running` oder `Configuration`
- Authentifizierungstoken vorhanden

## Achsnamen ermitteln

Achsnamen sind **case-sensitiv** — zuerst browsen:

```
GET /automation/api/v2/nodes/motion/axs?type=browse
```

Antwort enthält z. B. `["WIENERAXS", "DRIVEAXS", ...]`

## Aktuelle Limits lesen

```
GET /automation/api/v2/nodes/motion/axs/{AXSNAME}/cfg/lim?type=browse
```

Liefert die Unterknoten: `acc`, `dec`, `jrk-acc`, `jrk-dec`, `pos-max`, `pos-min`, `vel-neg`, `vel-pos`

```
GET /automation/api/v2/nodes/motion/axs/{AXSNAME}/cfg/lim/vel-pos
GET /automation/api/v2/nodes/motion/axs/{AXSNAME}/cfg/lim/vel-neg
```

## Wert setzen

```
PUT /automation/api/v2/nodes/motion/axs/{AXSNAME}/cfg/lim/vel-pos
Body: {"type":"double","value":3000}

PUT /automation/api/v2/nodes/motion/axs/{AXSNAME}/cfg/lim/vel-neg
Body: {"type":"double","value":3000}
```

## Dauerhaft speichern

Alle Änderungen werden erst durch `save-all` persistent (überleben Neustart):

```
POST /automation/api/v2/nodes/motion/cfg/save-all
Body: {"type":"bool8","value":true}
```

Erfolgsantwort: `{"type":"string","value":"Saving finished."}`

## Verifizieren

```
GET /automation/api/v2/nodes/motion/cfg/unsaved
```

Sollte nach erfolgreichem Speichern `false` zurückgeben.

## Hinweise

- Änderungen an `cfg/lim` sind im Zustand `Running` und `Configuration` möglich.
- Nur Geschwindigkeits-Limits (`vel-pos`, `vel-neg`) beeinflussen die Maximalgeschwindigkeit.
- `acc`/`dec`/`jrk-*` sind Beschleunigungs- und Rucklimits.
- Die Werte sind achsspezifisch — jede Achse hat eigene Limits.
