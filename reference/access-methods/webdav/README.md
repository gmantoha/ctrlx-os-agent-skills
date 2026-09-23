# WebDAV Access

The Solutions app can expose app data through WebDAV.

Use WebDAV primarily for inspecting, transferring, or editing app data exposed through the Solutions app.

Use WebDAV for:

- inspecting app data trees
- transferring app-related files
- checking whether app directories are writable or write-protected

Write access depends on the app configuration and manifest.

Detailed legacy notes are kept in `webdav-anleitung.md` in this folder.

## Verified on ctrlX CORE (2026-09-22)

- Endpoint `https://<ip>/solutions/webdav/appdata/<app>/...` accepts the ctrlX bearer token
  (`Authorization: Bearer <token>`).
- `PROPFIND` (Depth 1), `GET`, `PUT` (201 Created), `MKCOL` (new folder), `DELETE` (files and folders) work.
- Node-RED userDir is `appdata/node-RED/` (flows.json, package.json, node_modules, context); files placed there
  are readable from Function nodes. Symlinks cannot be created via WebDAV.
