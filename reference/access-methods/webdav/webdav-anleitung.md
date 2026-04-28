# WebDAV-Verbindung zur ctrlX OS App-Datenverwaltung

## Hintergrund

Das ctrlX OS-Gerät stellt über die integrierte **Solutions-App** einen WebDAV-Server bereit.
Über diesen Server lassen sich die Konfigurationsdaten aller installierten Apps lesen und – sofern
die App dies erlaubt – auch schreiben.

## Verbindungsparameter

| Parameter | Wert |
|---|---|
| Protokoll | WebDAV über HTTPS |
| URL | `https://192.168.47.219/solutions/webdav/` |
| Port | 443 |
| Benutzername | `rexroot` |
| Passwort | `rexroot` |
| TLS-Zertifikat | Selbstsigniert (Prüfung im Client deaktivieren) |

## Verzeichnisstruktur

```
/solutions/webdav/
└── appdata/                  ← aktive Konfigurationsdaten aller Apps
    ├── node-RED/
    ├── display/
    ├── framework/
    ├── remote-logging/
    ├── synchronization/
    └── configuration.json
```

## Verbindung herstellen mit WinSCP

1. **WinSCP herunterladen und installieren:** [https://winscp.net](https://winscp.net)

2. **Neue Verbindung anlegen:**
   - WinSCP starten → *Neue Sitzung*
   - Dateiprotokoll: **WebDAV**
   - Verschlüsselung: **TLS/SSL explizit** (oder *Implizites TLS*)
   - Hostname: `192.168.47.219`
   - Portnummer: `443`
   - Benutzername: `rexroot`
   - Passwort: `rexroot`

3. **Selbstsigniertes Zertifikat akzeptieren:**
   - Beim ersten Verbindungsaufbau erscheint eine Zertifikatswarnung.
   - Zertifikat prüfen und mit *Akzeptieren* (dauerhaft speichern) bestätigen.

4. **Verbinden** und zum Pfad `/solutions/webdav/appdata/` navigieren.

> **Hinweis:** Standardmäßig sind App-Verzeichnisse schreibgeschützt. Schreibzugriff ist nur
> möglich, wenn die jeweilige App in ihrer `package-manifest.json` den Parameter
> `"writeProtected": false` gesetzt hat.
