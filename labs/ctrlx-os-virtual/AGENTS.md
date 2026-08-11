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

Eine `DRIVEAXS`-Achse **ohne physischen Antrieb funktioniert** auf der virtuellen ctrlX CORE: anlegen → Power ON → verfahren. Kein Sonder-Flag nötig (`ignore-axisprofile = false`, ungespeichert). Verified: 2026-08-11, ctrlX OS 4.6 virtual.

- Schlägt der Wechsel nach Running fehl, zuerst `motion/state/boot-state` lesen (18 Schritte, zeigt den genauen Abbruchpunkt) — nicht raten.
- `scheduler/admin/state` und `motion/state/opstate` sind unabhängig: `OPERATING` heißt nicht, dass Motion läuft.
- Das Flag `ignore-axisprofile` liegt unter `motion/axs/{name}/cfg/functions/`, **nicht** unter `cfg/`.
