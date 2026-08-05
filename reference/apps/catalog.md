# App Catalog

This folder contains operational notes for commonly used ctrlX apps.

Tracked here:

- what the app does
- how it is typically installed or used
- key docs links
- troubleshooting notes

Not tracked here:

- app binaries or downloaded packages

## App Package Location

Locally available `.app` package files are stored under:

```
labs/app-packages/DC_App_Paket_4.6.0/
```

This includes user apps, system apps (`SYSTEM_APPS/`), and hardware-specific apps (`X3/`, `X5_X7_IPC/`).

Note: `.app` files are git-ignored and must be copied manually onto each machine.

On this machine the following packages have also been downloaded separately:

```
C:\Users\jmu1but\Downloads\DC_App_Paket_4.6.1\          ← user apps 4.6.1
C:\Users\jmu1but\Downloads\DC_App_Paket_3.6.8\          ← user apps 3.6.8
C:\Users\jmu1but\Downloads\DC_App_Paket_3.6.8\SYSTEM_APPS\  ← incl. core22-20260225.app
```

## Collaboration Room

Bosch Rexroth Collaboration Room (MyRexroth Login erforderlich) — Ablageort für App-Releases die nicht im Standard DC_App_Paket enthalten sind:

```
https://www.boschrexroth.com/de/de/myrexroth/myrexroth-home/collaboration-rooms/?path=%2FCtrlx-Automation%2FctrlX_CORE_APPS_Releases
```

Bekannte Pfade:

| App | Pfad im Collaboration Room |
|---|---|
| DRIVE Connect 3.6.x | `/CtrlX-Automation/ctrlX_CORE_APPS_Releases/V3.6/ctrlX Apps/ctrlX OS - DRIVE Connect App` |
| SYSTEM_APPS 3.6.x (inkl. core22) | `/CtrlX-Automation/ctrlX_CORE_APPS_Releases/V3.6/ctrlX Apps/SYSTEM_APPS` |

## App Dependencies

Manche Apps benötigen eine spezifische Base-Snap, die nicht automatisch vom Store geladen werden kann (z. B. in isolierten Umgebungen). Diese muss lokal vorab installiert werden.

| App | Snap-Name | Base-Snap | Hinweis |
|---|---|---|---|
| DRIVE Connect 3.6.x | `rexroth-drive-comm` | `core22` | Nicht in ctrlX OS 4.x enthalten — muss aus 3.6.x SYSTEM_APPS nachgeladen werden |

Details → `reference/apps/drive-connect/README.md`

## Release Notes

Official release notes PDFs for version 4.6.0 are stored under:

```
reference/docs/release-notes/4.6.0/EN/   ← English
reference/docs/release-notes/4.6.0/DE/   ← German
```

These are the primary AI-readable source for what changed in each app version.
