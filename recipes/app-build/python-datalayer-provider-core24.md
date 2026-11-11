# Python-Data-Layer-Provider als core24-Snap (Build, Deploy, Test, arm64-Check)

Verified: 2026-11-05 — ctrlX OS 4.6 COREvirtual, ctrlX AUTOMATION SDK 4.6.0
(`ctrlx-datalayer` 3.5.2 deb, PyPI `ctrlx-datalayer` 3.5.0), snapcraft 9.2, Build-Host Ubuntu 24.04 amd64.
Ergänzt `recipes/app-build/datalayer-provider.md` um eine erprobte Python-Variante.

## snapcraft.yaml – bewährte Bausteine

Statt `stage-packages: [ctrlx-datalayer]` (braucht das SDK-APT-Repo im Build) das Deb aus dem
SDK-Release mitliefern und per `dump` auspacken – funktioniert in LXD und im destructive mode gleich:

```yaml
base: core24
confinement: strict
platforms:
  amd64:
  arm64:
    build-on: [amd64, arm64]
    build-for: [arm64]

apps:
  connector:
    command: bin/python3 -m <python_package>.main
    daemon: simple
    restart-condition: always
    restart-delay: 10s
    environment:
      PYTHONUNBUFFERED: "1"          # sonst erscheinen Logs verzögert im Logbuch
    plugs: [network, network-bind, datalayer]

parts:
  app:
    plugin: python
    source: .
    after: [datalayer-lib]
    override-pull: |
      craftctl default
      rm -rf .venv tests build parts stage prime ./*.snap   # lokale Entwicklungsreste nicht einpacken
  datalayer-lib:
    plugin: dump
    source: ./vendor/ctrlx-datalayer-3.5.2.deb   # GitHub-Release-Asset des SDK 4.6.0
    source-type: deb
    override-prime: |
      craftctl default
      # Das Deb ist "Architecture: all" und enthält x86_64 UND aarch64 inkl. statischer Libs (~100 MB)
      for dir in "$CRAFT_PRIME"/usr/lib/*-linux-gnu; do
        [ "$(basename "$dir")" = "$CRAFT_ARCH_TRIPLET_BUILD_FOR" ] || rm -f "$dir"/libcomm_datalayer*
      done
      rm -rf "$CRAFT_PRIME"/usr/include "$CRAFT_PRIME"/usr/bin/dl_compliance "$CRAFT_PRIME"/usr/bin/mddb_compiler \
             "$CRAFT_PRIME"/usr/lib/*/libcomm_datalayer_static.a "$CRAFT_PRIME"/usr/lib/*/pkgconfig

plugs:
  datalayer:
    interface: content
    content: datalayer
    target: $SNAP_DATA/.datalayer

lint:
  ignore:
    - library:
        - usr/lib/aarch64-linux-gnu/libcomm_datalayer.so*
        - usr/lib/x86_64-linux-gnu/libcomm_datalayer.so*
```

- Ergebnis: ca. 13 MB statt > 100 MB. `core24` enthält bereits Python 3.12, `libssl3`, `libstdc++`, `libsystemd0`.
- snapcraft setzt `LD_LIBRARY_PATH` (inkl. `$SNAP/usr/lib/<triplet>`) automatisch; `ctrlxdatalayer` lädt
  `libcomm_datalayer.so` per `ctypes.CDLL` über den Namen.
- Reine Python-Abhängigkeiten (`ctrlx-datalayer<=3.6`, `ctrlx-fbs`, `flatbuffers`, Hersteller-Wheels über
  `python-packages: [./vendor/<name>.whl]`) sind architekturunabhängig → der arm64-Snap lässt sich auf amd64 bauen.
- Ein `package-assets`-Slot mit Minimal-Manifest (`$schema` v1.6, `id`, `version`) genügt für eine App ohne Web-UI.

## Bauen (Ubuntu 24.04, ohne sudo)

```bash
snapcraft pack --destructive-mode --build-for=amd64 --output build/   # X5/X7/IPC/COREvirtual
snapcraft clean --destructive-mode                                     # zwischen den Architekturen!
snapcraft pack --destructive-mode --build-for=arm64 --output build/   # X3
snapcraft clean --destructive-mode
```

destructive mode braucht kein sudo, solange die Build-Pakete des Python-Plugins (`python3-venv`, `python3-dev`)
installiert sind. Ohne `clean` zwischen zwei Architekturen werden Teile aus `parts/`, `stage/`, `prime/`
wiederverwendet. Prüfen: `unsquashfs -cat <snap> meta/snap.yaml` (Architektur, `LD_LIBRARY_PATH`) und
`unsquashfs -l <snap> | grep libcomm` (nur das Ziel-Triplet). Zielarchitektur je Gerät:
`reference/platform/hardware-architectures.md`.

## Provider-Code: Fallstricke

- Provider-Callbacks (`on_read`, `on_write`, …) synchron beantworten und **nie** mit Geräte- oder Netzwerk-I/O
  blockieren: Schreibzugriffe nur validieren und an einen Worker-Thread übergeben, Lesezugriffe aus einem Cache.
- Ausnahmen im Setter auf Data-Layer-Ergebnisse abbilden (z. B. `ValueError` → `INVALID_VALUE`,
  `TypeError` → `TYPE_MISMATCH`); REST-Clients sehen dann HTTP 4xx statt eines stillen Fehlers.
- Worker-Threads **vor** dem Registrieren der Knoten starten (sonst landen frühe Schreibzugriffe im Leeren).
- Knoten vorsorglich nicht innerhalb eines Provider-Callbacks (un)registrieren, sondern in einem eigenen Thread.
- Bricht `provider.is_connected()` weg, Prozess mit Exit-Code ≠ 0 beenden; `restart-condition: always` startet neu.

## Lokal debuggen gegen eine COREvirtual

App direkt auf dem Host starten und per TCP mit der Data Layer der VM verbinden – Ports **explizit** angeben,
siehe `reference/app-development/datalayer-apps.md` (Connection Pattern):

```text
Provider: tcp://boschrexroth:boschrexroth@127.0.0.1:<host-port→2070>?sslport=<host-port→443>
Client:   tcp://boschrexroth:boschrexroth@127.0.0.1:<host-port→2069>?sslport=<host-port→443>
```

Die Verbindungszeichenkette am besten über eine Umgebungsvariable der App setzen; im Snap immer `ipc://`.

## Installieren und Logs lesen per REST (COREvirtual)

```text
GET  /package-manager/api/v1/settings              → {"allowUnknownApps": true} nötig für eigene Snaps
PUT  /package-manager/api/v1/settings              {"allowUnknownApps": true}   (laut OpenAPI; im Test war es schon true)
PUT  /automation/api/v2/nodes/scheduler/admin/state {"type":"object","value":{"state":"SERVICE"}}
POST /package-manager/api/v1/packages              multipart: file=<snap>, update=true  → 202 + Location /tasks/<id>
GET  /package-manager/api/v1/tasks/<id>            (beobachtet: "state":"done", "progress":100 bei einer User-App)
PUT  /automation/api/v2/nodes/scheduler/admin/state {"type":"object","value":{"state":"OPERATING"}}
GET  /logbook/api/v2/entries?unit=snap.<snap>.<app>.service&limit=50   → Felder timestamp, mainTitle
```

`update=true` funktioniert auch bei der Erstinstallation. Die Konfiguration in `$SNAP_COMMON` bleibt bei Updates erhalten.
REST-Typnamen beim Schreiben (geprüft): `bool8`, `double`, `string`, Arrays von float64 als `arfloat64` oder
`ardouble`; Lesen meldet `ardouble` bzw. `arstring`.

## arm64-Build ohne X3 funktional testen (QEMU-User-Emulation)

```bash
sudo apt-get install qemu-user-static           # meist schon vorhanden
UBUNTU_STORE_ARCH=arm64 snap download core24    # arm64-Base (ca. 65 MB)
unsquashfs -d core24-arm64 core24_*.snap usr/bin/python3.12 usr/lib/python3.12 usr/lib/aarch64-linux-gnu \
    usr/lib/ld-linux-aarch64.so.1 lib etc/ld.so.cache
unsquashfs -d app-arm64 build/<snap>_arm64.snap

R=$PWD/core24-arm64; S=$PWD/app-arm64
PYTHONNOUSERSITE=1 PYTHONPATH=$S/lib/python3.12/site-packages \
LD_LIBRARY_PATH=$S/usr/lib/aarch64-linux-gnu:$R/usr/lib/aarch64-linux-gnu \
qemu-aarch64-static -L $R $R/usr/bin/python3.12 smoke_test.py
```

- `PYTHONNOUSERSITE=1` ist nötig, sonst lädt Python x86-Pakete aus `~/.local` (z. B. numpy) und bricht ab.
- `smoke_test.py` kann echte Verbindungen aufbauen: Provider/Client per TCP zur Data Layer einer COREvirtual
  (Ports wie oben) – so wurden die aarch64-`libcomm_datalayer` und der komplette Python-Code geprüft.
- Ersetzt keinen Test auf echter X3-Hardware (Confinement, Leistung), deckt aber Architekturfehler im Paket auf.
