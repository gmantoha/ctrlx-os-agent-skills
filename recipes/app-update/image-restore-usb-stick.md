# System-Image per USB-Stick (ctrlX CORE X5 / X7 / Rexroth IPC)

> Stand 2026-09-17. Quellen: Community How-to „Partition a disk as GPT & Restore ctrlX CORE X5 or X7",
> ctrlX OS Release Notes 4.6.5 (Bug 1192278, Bug 711581, Bug 853922).

## Stick vorbereiten

| Anforderung | Wert |
|---|---|
| Partitionstabelle | **GPT** (UEFI) — MBR/`dos` bootet nicht |
| Partitionen | genau **eine**, FAT32 |
| Größe | max. 32 GB |
| USB-Version | USB 2.0 empfohlen (BIOS ≤ CTL6R12 erkennt Sticks nicht automatisch) |
| Inhalt | Image-ZIP **entpackt** ins Wurzelverzeichnis |

Linux (Zielgerät vorher mit `lsblk -o NAME,SIZE,TRAN,RM,MODEL` verifizieren — `sda` ist oft die Systemplatte!):

```bash
sudo wipefs -a /dev/sdX
sudo parted -s /dev/sdX mklabel gpt
sudo parted -s /dev/sdX mkpart primary fat32 1MiB 100%
sudo partprobe /dev/sdX && sudo udevadm settle
sudo mkfs.vfat -F 32 -n CTRLX /dev/sdX1
lsblk -o NAME,FSTYPE,FSVER,LABEL,PTTYPE /dev/sdX     # erwartet: gpt, sda1 vfat FAT32
```

Windows: `diskpart` → `select disk N` → `clean` → `convert gpt`, dann FAT32-Partition in der Datenträgerverwaltung.

## Flashen

- X7: Stick in **XF01**, Gerät stromlos schalten und wieder einschalten.
- LED blinkt rot/blau während des Updates, blau = fertig. Danach Stick abziehen
  (Bug 711581: mit Stick in XF01C bootet das Gerät evtl. vom Stick bzw. Secure Boot blockiert).
- BIOS ≤ CTL6R12: beim Booten F7 (Boot-Menü) → Strg+Alt+Entf.

## Rexroth IPC (PRx) — Besonderheit

Release Notes 4.6.3, Bug 1192278: Flashen auf IPCs ging nur mit Tastatur/Monitor über das Boot-Menü.
Seit dem Fix bootet der IPC von beliebigen Wechselmedien — **aber nur, wenn das Flashen über die Web-Oberfläche
angestoßen wird**. Ein Stick allein + Neustart reicht nicht.
Alternative ohne Image: System-Apps einzeln aktualisieren → [os-update-from-local-files.md](os-update-from-local-files.md).

## Wurde wirklich geflasht? — Indizien prüfen

Ein Restore setzt das Gerät auf Werkseinstellungen. Nur „Gerät war kurz weg" beweist nichts.

| Indiz | Restore erfolgt | Nur Neustart |
|---|---|---|
| Vorher gesetzte statische IP | weg (DHCP) | noch da |
| Offline-Dauer | deutlich länger, mehrere Reboots | ~1 min |
| Login mit Default-Passwort | ggf. Passwortänderung erzwungen (nicht verifiziert) | normal |
| Versionen in `GET /package-manager/api/v1/packages` | = Image-Version | unverändert |

Monitoring vom Laptop (ohne Login): Link-Carrier, `ping -6 fe80::…%if` (bleibt über Restore gleich),
HTTP-Status der Web-UI (000 → 502 → 200 beim Hochfahren).
