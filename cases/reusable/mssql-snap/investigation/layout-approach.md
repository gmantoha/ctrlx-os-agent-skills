# Lösungsweg: `layout:` in snapcraft.yaml

## Was `layout:` macht

Jeder Snap läuft in einem eigenen **Mount-Namespace** (Linux-Kernel-
Feature, `CLONE_NEWNS`). Snapd baut diesen Namespace beim Start des
Snaps auf und legt darin das Root-Filesystem des `core`-Snaps als
`/` ab. Anwendungsdaten liegen unter `$SNAP`, `$SNAP_DATA`,
`$SNAP_COMMON` — das Root-Filesystem selbst ist **read-only**.

Das `layout:`-Feature in `snapcraft.yaml` weist snapd an, **beim
Aufbau des Mount-Namespace zusätzliche Bind-Mounts** anzulegen.
Diese sind nur im Namespace des Snaps sichtbar, der Host ist davon
nicht betroffen. Das funktioniert unter **strict-Confinement**,
gerade weil der Namespace vollständig unter Kontrolle von snapd
steht — es wird kein Host-Pfad geöffnet.

Offizielle Doku: https://snapcraft.io/docs/snap-layouts

## Syntax

```yaml
layout:
  <zielpfad-im-snap-namespace>:
    bind: <quelle>            # Verzeichnis-Bind-Mount (rw)
  <zielpfad>:
    bind-file: <quelle>       # Datei-Bind-Mount
  <zielpfad>:
    symlink: <quelle>         # Symlink (leichtgewichtig, kein Mount)
  <zielpfad>:
    type: tmpfs               # In-Memory-tmpfs
```

Als `<quelle>` sind nur diese Präfixe erlaubt:
- `$SNAP`          — read-only Snap-Inhalt
- `$SNAP_DATA`     — per-Revision writable (bei Updates migriert)
- `$SNAP_COMMON`   — revisionsübergreifend writable

## Anwendung auf MSSQL

```yaml
layout:
  /.system:
    bind: $SNAP_DATA/mssql-system
  /var/opt/mssql:
    bind: $SNAP_DATA/var-opt-mssql
  /var/log/mssql:
    bind: $SNAP_DATA/var-log-mssql
  /opt/mssql:
    bind: $SNAP/opt/mssql            # read-only aus dem Snap-Paket
```

Wichtig: Die Quellverzeichnisse unter `$SNAP_DATA` müssen **bei
Snap-Start existieren**. snapd legt leere Verzeichnisse automatisch
an, wenn das Ziel ein Verzeichnis-Bind ist. Erstbefüllung (z.B. die
Master-DB-Templates) macht man typischerweise in einem
`configure`-Hook oder beim ersten Start des Services.

## Grenzen von `layout:`

Folgende Zielpfade akzeptiert snapd **nicht** (hart verdrahtet in
`snapd` — siehe `cmd/snap-confine/mount-support.c`):

- `/bin`, `/sbin`, `/lib`, `/lib32`, `/lib64`, `/libx32`
- `/usr` und dessen Unterverzeichnisse (Ausnahmen: `/usr/share`,
  `/usr/src`, `/usr/local` sind erlaubt)
- `/etc` (mit Einschränkungen; einzelne Dateien via `bind-file` gehen)
- `/dev`, `/proc`, `/sys`, `/run`, `/tmp`, `/var/snap`, `/var/lib/snapd`

`/.system` ist ein frei erfundener Top-Level-Pfad und kollidiert mit
keinem dieser geschützten Namen — snapd sollte ihn ohne Weiteres
akzeptieren. Für `/var/opt/mssql` gilt dasselbe.

## Zusammenspiel mit Confinement

- **Strict:** `layout:` funktioniert uneingeschränkt.
- **Classic:** `layout:` ist **nicht** verfügbar (der Snap sieht das
  Host-Rootfs direkt, es gibt keinen separaten Namespace zum
  Umleiten).
  → Ein weiterer Grund, warum der strict-Pfad der bessere ist.

## AppArmor-Seite

Snapd generiert für `layout:`-Pfade automatisch passende AppArmor-
Regeln. Für `/.system/**` wird also automatisch `rw` erlaubt, wenn
die Zielpartition `$SNAP_DATA` ist. Keine manuellen Interface-
Anpassungen nötig.

## Base-Snap-Wahl

MSSQL 2022/2025 ist gegen **Ubuntu 20.04** (glibc 2.31) bzw.
**22.04** (glibc 2.35) gelinkt. Für einen neuen Snap:

- `base: core22`  → Ubuntu 22.04, empfohlen
- `base: core24`  → Ubuntu 24.04, glibc 2.39 — nicht offiziell getestet
  von Microsoft, vermutlich OK, aber Risiko

## Minimal-Proof-of-Concept (zum späteren Test)

```yaml
name: hk-mssql
base: core22
confinement: strict
grade: stable

apps:
  mssql:
    command: opt/mssql/bin/sqlservr
    daemon: simple
    plugs: [network-bind]

layout:
  /.system:
    bind: $SNAP_DATA/mssql-system
  /var/opt/mssql:
    bind: $SNAP_DATA/var-opt-mssql

parts:
  mssql:
    plugin: nil
    stage-packages:
      - mssql-server   # aus Microsofts APT-Repo, muss vor Build
                       # hinzugefügt werden
```

Diese YAML ist **nicht getestet** und dient nur als Diskussions-
Grundlage für die nächste Iteration.
