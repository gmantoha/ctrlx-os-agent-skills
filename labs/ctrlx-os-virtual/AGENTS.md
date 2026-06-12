# Virtual Lab Guidance

Use this folder when verifying workflows against a local virtual ctrlX target.

Rules:

- do not expect the VM image to be present in git
- keep runtime artifacts under `assets/`
- document expected ports and access URLs in local environment files
- distinguish clearly between behavior verified on virtual and real devices

Allowed documented defaults:

- Web UI: `boschrexroth` / `boschrexroth`
- SSH: document only if the lab setup intentionally uses a public default

## Edge auf Windows öffnen (Windows-Tipp)

Zuverlässiger Befehl zum Öffnen der virtuellen Steuerung in Edge:

```powershell
cmd /c start msedge "https://127.0.0.1:8443"
```

`Start-Process msedge` und der direkte Pfad zu `msedge.exe` öffnen keinen neuen Tab zuverlässig — `cmd /c start msedge` funktioniert immer.

## Chrome auf Windows öffnen

```powershell
cmd /c start chrome --new-window "https://127.0.0.1:8443"
```

## Motion auf virtueller Steuerung ohne physische Drives

Auf einer virtuellen ctrlX CORE ohne konfigurierte Drives bleibt Motion im Zustand **Booting** (>60 s) und fällt danach zurück nach **Configuration**. Der Wechsel nach Running scheitert mit `0xf0100001`.

- Der DL-Knoten `motion/axs/{name}/cfg/ignore-axisprofile` existiert **nicht** (`DL_INVALID_ADDRESS`).
- Der vorhandene Knoten lautet `motion/axs/{name}/cfg/axisprofile` (type: `string`, default: `""`).
- Achsen können erstellt und konfiguriert werden (Properties + Limits OK), aber Motion lässt sich ohne Drive-Zuweisung nicht in Running schalten.
- Verified: 2026-06-12, ctrlX OS 4.6 virtual.
