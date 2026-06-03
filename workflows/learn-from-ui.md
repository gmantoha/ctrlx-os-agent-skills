# Learn from UI — API-Verhalten durch Browser-Beobachtung erlernen

Verwende diesen Workflow wenn:
- Ein Data Layer Knoten sich per REST nicht korrekt beschreiben lässt
- Das korrekte Payload-Format oder der richtige Typ unklar ist
- Du ein neues Feature der ctrlX Web UI in eine Automatisierung übersetzen möchtest
- Der Benutzer eine UI-Aktion durchführt und du die zugehörigen API-Calls lernen willst

## Methode: Data Layer Diff (empfohlen)

Nginx-Traffic ist verschlüsselt (TLS). Die zuverlässigste Methode ist der **Data Layer Diff**: Zustand vor und nach der UI-Aktion vergleichen.

### Ablauf

1. **Baseline erfassen** — alle relevanten Knoten auslesen und speichern
2. **Benutzer führt UI-Aktion durch** und beschreibt sie kurz
3. **Diff lesen** — dieselben Knoten erneut lesen, Änderungen identifizieren
4. **Dokumentieren** — geänderte Pfade, Typen, Payload-Struktur als Rezept festhalten

### Baseline erfassen

```http
GET /automation/api/v2/nodes/{app}/instances/{name}/cfg?type=browse
GET /automation/api/v2/nodes/{app}/instances/{name}/cfg/{node}
```

Alle relevanten Kindknoten rekursiv lesen und Werte notieren.

### Diff nach UI-Aktion

Dieselben Knoten erneut lesen. Geänderte Werte zeigen:
- welcher Pfad beschrieben wurde
- welchen Typ (`type`) der Wert hat
- wie die Payload-Struktur aufgebaut ist

## Methode: nginx Access Log (ergänzend)

Der nginx-Proxy loggt alle HTTP-Requests (nicht WebSocket-Traffic).

```bash
# Log-Pfad auf ctrlX CORE:
/var/snap/rexroth-ide/common/nginx-access.log

# Live-Filter für API-Calls:
tail -f /var/snap/rexroth-ide/common/nginx-access.log | grep -E '(automation/api|identity-manager)'

# Nachträglich lesen:
grep -E '(automation/api)' /var/snap/rexroth-ide/common/nginx-access.log | tail -50
```

**Einschränkung:** Die Oscilloscope-UI und viele ctrlX-Apps kommunizieren über **WebSockets** direkt mit dem Data Layer — dieser Traffic erscheint nicht im nginx-Log. Daher ist der Data Layer Diff die primäre Methode.

## Gelerntes Beispiel: Oscilloscope Kanal-Konfiguration

Beobachtung: UI legt Kanäle anders an als aus der JSON-Schema-Dokumentation erwartet.

| Feld | Aus Schema erwartet | Tatsächlich (UI-Diff) |
|------|--------------------|-----------------------|
| `type` | `"RT"` | `"NRT"` |
| `alias` | (leer / nicht verwendet) | = `source` (identisch) |
| `name` | frei wählbar | `NRT<signal><autoID>` (z.B. `NRTvel8`) |
| Trigger `name` | Data Layer Pfad | Channel-Name (z.B. `NRTvel8`) |
| `diagramview/views` | per POST schreibbar | automatisch befüllt — **nicht manuell beschreiben** |

→ Vollständiges Rezept: `recipes/oscilloscope/setup-oscilloscope-instance.md`

## Hinweis zur Dokumentation

Erkenntnisse aus UI-Tracking immer als Rezept unter `recipes/` ablegen mit dem Hinweis:
> Lernquelle: UI-Tracking (Data Layer Diff)

Das schlägt offizielle Dokumentation wenn diese veraltet oder unvollständig ist.
