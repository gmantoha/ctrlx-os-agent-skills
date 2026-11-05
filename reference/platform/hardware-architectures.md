# ctrlX CORE Hardware-Architekturen (Snap-Zielarchitektur)

Welche CPU-Architektur ein Gerät hat, entscheidet, welcher Snap (`--build-for`) installiert werden kann.

| Gerät | Architektur | Plattform-Snaps | `snapcraft pack --build-for=` |
|---|---|---|---|
| ctrlX CORE **X3** | **arm64** | `rexroth-arch01-hw`, `rexroth-arch01-kernel` | `arm64` |
| ctrlX CORE **X5**, **X7**, Rexroth **IPC** | **amd64** | `rexroth-arch02-hw`, `rexroth-arch02-kernel` | `amd64` |
| ctrlX COREvirtual (QEMU-Lab) | **amd64** | `rexroth-arch02-virtual-kernel` | `amd64` |

Belegt am 2026-11-05 an den offiziellen System-Apps (ctrlX OS 4.6.x, DC-App-Paket 4.6.2):
die `.app`-Dateien sind tar-Archive mit `public/snaps/<arch>/release/<snap>.snap`; die Pakete im Ordner
`SYSTEM_APPS/X3` sind `arm64`, die im Ordner `SYSTEM_APPS/X5_X7_IPC` sind `amd64`
(`meta/snap.yaml` → `architectures`). Die COREvirtual meldet in `GET /package-manager/api/v1/packages`
das Paket `rexroth-arch02-virtual-kernel`.

## Folgen für App-Entwicklung und Tests

- Ein **amd64**-Snap, der auf der COREvirtual getestet wurde, läuft architekturgleich auf **X5/X7/IPC**.
  Hardware-Unterschiede (Schnittstellen, Storage, Feldbus) bleiben, siehe `reference/platform/real-vs-virtual.md`.
- Für die **X3** einen **arm64**-Snap bauen. Ohne X3-Hardware lässt sich der arm64-Build per
  QEMU-User-Emulation funktional prüfen, siehe `recipes/app-build/python-datalayer-provider-core24.md`.
- Auf einem unbekannten Gerät die Architektur über die installierten Plattform-Snaps bestimmen
  (`rexroth-arch01-*` = arm64, `rexroth-arch02-*` = amd64):

```bash
curl -sk -H "Authorization: Bearer $TOKEN" https://<ip>/package-manager/api/v1/packages \
  | python3 -c 'import sys,json; print([p["name"] for p in json.load(sys.stdin) if "-arch0" in p["name"]])'
```

- System-App-Pakete und OS-Updates immer zur Architektur passend wählen
  (siehe `recipes/app-update/os-update-from-local-files.md`, „IPC = arch02“).
