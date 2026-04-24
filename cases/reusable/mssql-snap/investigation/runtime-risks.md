# Laufzeit-Risiken jenseits des `/.system`-Problems

Auch wenn der `layout:`-Ansatz das konkrete `/.system`-Problem löst,
gibt es weitere Themen, die vor einem Release geklärt sein müssen.

## 1. Fehlende Capabilities

SQL Server erwartet auf Linux mehrere Privileges, die unter strict-
Confinement **nicht** verfügbar sind:

| Capability | Zweck in MSSQL | Verfügbarkeit in strict-Snap |
|---|---|---|
| `CAP_SYS_NICE` | Realtime-Scheduling-Prio für SQLOS-Scheduler | **nicht verfügbar** |
| `CAP_IPC_LOCK` | `mlock()` für Buffer Pool (memory-pinning) | **nicht verfügbar** |
| `CAP_NET_BIND_SERVICE` | Binden an Port < 1024 | nicht relevant (1433 ist > 1024) |
| `CAP_SYS_PTRACE` | Dump-On-Crash, SQLDumper | nicht verfügbar; führt nur zu weniger nützlichen Crash-Dumps |

**Auswirkung:** MSSQL startet trotzdem, loggt aber beim Start
Warnungen der Art:

```
ERROR: Unable to set Scheduler Monitor priority.
WARNING: Unable to lock pages in memory. Large page allocations
         may fall back to standard pages.
```

Das ist akzeptabel für Dev/Test, für produktive Workloads auf
ctrlX mit hohen Anforderungen an Echtzeit-Determinismus aber ein
**Performance-Risiko** — insbesondere weil ctrlX-M4-Systeme
ohnehin einen RT-Kernel haben und Scheduling-Konflikte entstehen
können. Für den hier betrachteten amd64-Fall (virtual/X3) ist das
unkritischer.

Kein Interface kann diese Capabilities unter strict wieder
freischalten. Wer sie braucht, muss zu classic wechseln — was hier
ausgeschlossen ist.

## 2. Lizenz / Redistribution

Die Microsoft-SQL-Server-EULA erlaubt **keine eigenständige
Weiterverteilung** der Binaries. Konsequenzen für den Snap:

- **Empfohlen:** Der Snap enthält das MSSQL-Binary **nicht**, sondern
  lädt das offizielle `.deb` von Microsofts APT-Repository beim
  ersten Start herunter und installiert es unter `$SNAP_DATA`.
  Das Verfahren ist mit dem ctrlX-App-Installer grundsätzlich
  vereinbar, hat aber eigene Fallstricke (Offline-Installationen
  funktionieren nicht out-of-the-box).
- **Alternative:** Der Kunde holt bei Microsoft ein OEM- bzw.
  Embedded-Agreement, das die Distribution innerhalb eines
  ctrlX-Snaps abdeckt. Ist ein Vertrieb-/Legal-Thema, kein
  technisches.

Vor einem produktiven Build dringend mit Kunden-Legal klären.

## 3. Base-Snap und glibc

MSSQL 2022/2025 ist gegen Ubuntu 20.04 / 22.04 zertifiziert:

- `base: core22` → glibc 2.35 ✅ empfohlen
- `base: core24` → glibc 2.39 ⚠ nicht von Microsoft getestet

Bei `core24` kann es zu Warnungen oder subtilen Inkompatibilitäten
kommen. Für einen produktionsnahen Snap → `core22`.

## 4. Speicherbedarf

MSSQL reserviert per Default ca. 87% des RAMs als Buffer Pool.
In einem ctrlX-System, auf dem bereits PLC, Data Layer, Node-RED,
Grafana etc. laufen, muss der Buffer Pool zwingend begrenzt werden:

```
mssql-conf set memory.memorylimitmb 1024
```

Sonst kommt es zum selben Typ von OOM-Situation, wie wir ihn im
`influx-crash/`-Fall gesehen haben (snapd-Watchdog → SIGABRT).

## 5. Persistenz und Updates

`$SNAP_DATA` wird bei jedem Snap-Update **kopiert** (nicht
überschrieben). Für MSSQL-Datenbanken, die durchaus mehrere GB groß
werden, ist das problematisch:

- Updates werden spürbar langsam.
- Plattenbedarf verdoppelt sich kurzzeitig.

Besser: Datenbank-Dateien unter `$SNAP_COMMON` ablegen (wird bei
Updates **nicht** kopiert, bleibt einfach bestehen). System-Directory
darf in `$SNAP_DATA` bleiben; Nutzdaten (`/var/opt/mssql/data`)
sollten nach `$SNAP_COMMON` gemappt werden:

```yaml
layout:
  /.system:
    bind: $SNAP_DATA/mssql-system
  /var/opt/mssql:
    bind: $SNAP_COMMON/var-opt-mssql    # <- COMMON statt DATA
```

## 6. ctrlX-Integration (optional)

MSSQL hat keine ctrlX-Data-Layer-Anbindung out-of-the-box. Falls
SPS-Daten in MSSQL landen sollen, ist zusätzlich ein Adapter nötig
(Telegraf mit sqlserver-Output, Node-RED-Flow, eigener Go-Provider).
Nicht Teil dieses Debug-Tickets.
