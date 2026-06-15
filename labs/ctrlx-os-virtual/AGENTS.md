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
## Login-Workflow (aiuser, bevorzugt)

1. Passwort aus `Core4_6\aiUserPasswort` lesen und in die Zwischenablage kopieren:
   ```powershell
   $pw = (Get-Content "C:\Users\jmu1but\OneDrive - Bosch Group\MY_Daten\GitHub\Core4_6\aiUserPasswort" | Where-Object { $_ -match 'Passwort' }) -replace '.*:\s*'
   Set-Clipboard -Value $pw
   ```
2. Edge mit der URL öffnen:
   ```powershell
   cmd /c start msedge "https://127.0.0.1:8443"
   ```
3. Benutzer `aiuser` eintippen, ins Passwortfeld klicken → **Ctrl+V** → Einloggen.
