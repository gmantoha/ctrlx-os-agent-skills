# Bekannte hartkodierte Schreibpfade von MSSQL / SQLPAL

SQLPAL (SQL Platform Abstraction Layer) emuliert Windows-Semantik
auf Linux. Einige Pfade sind im SQLPAL-Binary hartkodiert und
lassen sich nicht über Konfiguration verändern. Sie müssen unter
strict-Confinement per `layout:` auf `$SNAP_DATA`/`$SNAP_COMMON`
umgebogen werden.

## Bestätigt (aus Fehlermeldung bzw. SQLPAL-Sourcecode-Fragmenten)

| Pfad | Zweck | Umleitung via |
|---|---|---|
| `/.system` | SQLPAL-internes Arbeitsverzeichnis (System-Directory) | `layout:` → `$SNAP_DATA/mssql-system` |
| `/var/opt/mssql/data` | Nutzdaten-Verzeichnis (Datafiles, Logs) | `layout:` → `$SNAP_DATA/var-opt-mssql/data` |
| `/var/opt/mssql/log` | Error-Log, SQL-Agent-Log | `layout:` → `$SNAP_DATA/var-opt-mssql/log` |
| `/var/opt/mssql/secrets` | Machine-Key, TDE-relevante Dateien | `layout:` → `$SNAP_DATA/var-opt-mssql/secrets` |

## Erwartet (aus Erfahrung mit mssql-server.deb auf read-only-Rootfs)

| Pfad | Zweck | Anmerkung |
|---|---|---|
| `/var/opt/mssql/.system` | alternative Stelle für System-Directory | tritt bei manchen Versionen zusätzlich zu `/.system` auf |
| `/tmp/.sqlpal-*` | temporäre SQLPAL-Socket-Pfade | `/tmp` ist im Snap bereits per tmpfs je Snap verfügbar — meist kein Eingriff nötig |
| `/dev/shm/SQLSERVER_SHMEM_*` | Shared-Memory für interne Kommunikation | `/dev/shm` ist im Snap beschreibbar, aber Flags (POSIX shm) benötigen evtl. `process-control`-Interface |
| `/var/opt/mssql/mssql.conf` | Runtime-Konfiguration | liegt automatisch unter dem gemappten `/var/opt/mssql` |
| `/opt/mssql/bin/*` | Binary-Verzeichnis | read-only, gehört in `$SNAP/opt/mssql`, keine Umleitung nötig |
| `/opt/mssql/lib/*` | Libraries, mssql-native | wie oben |

## Vorgehensmuster

1. Snap mit `layout:` für die **bestätigten** Pfade bauen.
2. Starten und journalctl beobachten.
3. Bei jeder neuen `Access denied`/`Permission denied`-Meldung mit
   Dateipfad den Pfad der `layout:`-Liste hinzufügen.
4. Wiederholen, bis SQL Server den Port 1433 öffnet.

Erfahrungsgemäß konvergiert das nach 3–5 Iterationen.

## Pfade, die **nicht** umgeleitet werden dürfen

- `/proc`, `/sys` — snapd verweigert Layout hier; SQLPAL braucht
  diese auch nur read-only, was der Snap-Namespace ohnehin liefert.
- `/etc/ssl/certs` — für TLS-Verbindungen nötig; liegt im
  `core22`-Base bereits und ist im Snap sichtbar. Wenn eigene
  Zertifikate nötig sind, diese über ctrlX-Zertifikatsspeicher
  einbinden (content-interface `cert-store`).
