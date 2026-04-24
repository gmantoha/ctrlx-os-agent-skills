# MSSQL als ctrlX-Snap — Untersuchung

## Problem

Microsoft SQL Server 2025 (Snap `hk-mssql`) bricht beim Start unter
strict-Confinement ab:

```
sqlservr: Error: The system directory [/.system] could not be created.
File: .../sqlpal/Hosts/Linux/LinuxDirectory.cpp:420
Status: 0xC0000022 Access denied errno = 0xD(13) Permission denied
```

SQLPAL (Microsoft SQL Platform Abstraction Layer) legt hartkodiert
ein Verzeichnis `/.system` direkt unter `/` an. Der Pfad ist weder
über `mssql.conf` noch über Environment-Variablen noch über
Kommandozeilen-Flags konfigurierbar — das ist im SQLPAL-Quellcode
fest verdrahtet.

Siehe `error-log.txt` für die vollständige Meldung.

## Randbedingungen (vom Kunden / vom Support festgelegt)

- **Zielhardware:** ctrlX CORE virtual / X3 (amd64).
  → ARM64 (M4) wird nicht betrachtet — MSSQL hat keinen offiziellen
  ARM64-Build; dort wäre das Vorhaben ohnehin blockiert.
- **Confinement:** strict (classic wird nicht verfolgt — für den
  ctrlX-App-Installer nicht praktikabel).
- **Diese Iteration:** nur Analyse + Dokumentation, noch kein
  `snapcraft.yaml` und kein Build.

## Kernerkenntnis

Die Kunden-Hypothese ("nur classic geht") ist **nicht korrekt**.
Der `layout:`-Mechanismus in `snapcraft.yaml` erlaubt es, beliebige
Pfade im Mount-Namespace des Snaps per Bind-Mount auf schreibbare
Locations (`$SNAP_DATA`, `$SNAP_COMMON`) umzuleiten — auch Pfade
direkt unter `/`. Das funktioniert unter **strict-Confinement**.

Beispiel (Minimal-Skizze):

```yaml
layout:
  /.system:
    bind: $SNAP_DATA/.system
  /var/opt/mssql:
    bind: $SNAP_DATA/var/opt/mssql
```

Details siehe `investigation/layout-approach.md`.

## Weitere zu erwartende Probleme

Das `/.system`-Problem ist voraussichtlich **nur das erste von
mehreren**. SQLPAL greift auf weitere hartkodierte Pfade zu (siehe
`investigation/known-mssql-paths.md`), und es gibt Laufzeit-Risiken
rund um Capabilities und Lizenz (siehe `investigation/runtime-risks.md`).

## Empfehlung

1. Prototyp mit `layout:`-Bindings für `/.system` und `/var/opt/mssql`
   bauen, unter `base: core22` (MSSQL braucht Ubuntu-22.04-glibc).
2. Start versuchen, iterativ weitere Pfade ergänzen, sobald SQLPAL
   über den nächsten hartkodierten Pfad stolpert.
3. Capability-Warnungen (`CAP_SYS_NICE`, `CAP_IPC_LOCK`) akzeptieren
   — MSSQL hat einen Fallback-Modus, läuft dann aber mit reduzierter
   Priorität / ohne Memory-Locking.
4. Lizenzfrage mit Microsoft / Kunden klären, bevor ein Snap
   tatsächlich verteilt wird (EULA verbietet Binary-Redistribution).

## Ordnerinhalt

```
mssql-snap/
├── README.md                        ← diese Datei
├── error-log.txt                    ← Original-Fehlermeldung des Kunden
└── investigation/
    ├── layout-approach.md           ← Detailierte Erklärung zu layout:
    ├── known-mssql-paths.md         ← Liste weiterer Schreibpfade
    └── runtime-risks.md             ← Capabilities, Lizenz, Glibc-Base
```
