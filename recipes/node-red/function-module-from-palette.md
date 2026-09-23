# Bibliothek aus einem Palette-Paket im Function-Node nutzen (Beispiel @st-one-io/nodes7)

Verified on a real ctrlX CORE, Node-RED 4.1.11-ctrlx, node-red-contrib-s7 3.1.3, 2026-09-22.

## Wann

Ein Palette-Node ist zu starr (z. B. `s7 endpoint`: IP, Rack, Slot und Variablen nur im Editor, nicht aus einer
Datei), die Bibliothek darunter kann es aber. Dann die Bibliothek direkt in einem Function-Node verwenden.

## Wie Node-RED 4 Function-Module lädt

Quelle: `@node-red/registry/lib/externalModules.js`.
- Erlaubt sind nur Module, die in `userDir/package.json` unter `dependencies` stehen ("known modules").
- Geladen wird `require(userDir/node_modules/<modul>)`.
- Unbekanntes Modul in den `libs` eines **aktiven** Function-Nodes → Node-RED versucht `npm install` →
  offline Fehler → **kein einziger Flow startet**. Deaktivierte Nodes (`d: true`) werden übersprungen.
- Subpfade (`paket/node_modules/x`) funktionieren nicht als Umgehung, der Modulname muss selbst bekannt sein.
- Der Ordner `userDir/externalModules/` ist Legacy und wird nicht gelesen.

## Registrierung (persistente Änderung, vorher bestätigen lassen)

userDir = `/var/snap/ctrlx-node-red/current/solutions/activeConfiguration/node-RED`

1. Symlink (relativ, damit Snap-Revisionswechsel egal sind):
   `userDir/node_modules/@st-one-io/nodes7 -> ../node-red-contrib-s7/node_modules/@st-one-io/nodes7`
2. `userDir/package.json` vorher sichern, dann ergänzen:
   `"@st-one-io/nodes7": "file:node_modules/node-red-contrib-s7/node_modules/@st-one-io/nodes7"`
3. Flow mit `Node-RED-Deployment-Type: flows` neu deployen.

Es gibt kein SSH-freies Shell-Werkzeug dafür. Umsetzung über einen einmaligen Function-Node mit lib `fs`
(`fs.mkdirSync`, `fs.symlinkSync`, `fs.writeFileSync`) oder dauerhaft über einen Wartungs-Node (unten).
WebDAV kann Symlinks weder anlegen noch zuverlässig anzeigen, aber löschen.

## Wartungs-Node "Registrierung prüfen/reparieren"

Empfohlen in jedem Flow, der auf eine registrierte Bibliothek angewiesen ist:
- Inject `topic: "check"` (once beim Start): prüft Bibliothek vorhanden (Version), Symlink vorhanden und
  auflösbar, package.json-Eintrag vorhanden. Schreibt das Ergebnis in `flow.status.registration`.
- Inject `topic: "repair"`: legt fehlenden/toten Symlink neu an, ergänzt package.json mit Zeitstempel-Backup.
  Idempotent: ist alles ok, wird nichts geändert. Danach Hinweis "Flow neu deployen".
- Vollständiger Code: `cases/reusable/node-red-s7-rest-buffer/flow/gen_flow.py` (`FN_REGISTER`).

Getestet: Symlink per WebDAV gelöscht → Check meldet "Symlink fehlt" → Repair legt ihn neu an → Check ok;
laufende S7-Verbindung blieb unberührt (bereits geladenes Modul bleibt im Speicher).

## Notfall: Node-RED startet keinen Flow mehr

Ursache meist: package.json-Eintrag fehlt (z. B. nach Neuinstallation/Update von node-red-contrib-s7),
Function-Node mit dem Modul ist aber aktiv. Dann läuft auch der Wartungs-Node nicht.
1. Den Function-Node mit dem Modul deaktivieren (`"d": true`), deployen.
2. "Registrierung reparieren" auslösen.
3. Node wieder aktivieren, mit `flows` deployen.

## Nutzung im Function-Node

Setup → Module: Variable `nodes7`, Modul `@st-one-io/nodes7`.

```js
const plc = new nodes7.S7Endpoint({ host, port: 102, rack: 0, slot: 2, autoReconnect: 5000, s7ConnOpts: { timeout: 2000 } });
const group = new nodes7.S7ItemGroup(plc);
group.setTranslationCB(name => addr[name]);   // addr = { Marker: "DB1,WORD0", ... }
group.addItems(Object.keys(addr));
plc.on("connect", () => { /* setInterval(() => group.readAllItems().then(values => ...), cycleMs) */ });
plc.on("disconnect", () => { /* Timer stoppen */ });
plc.on("error", e => node.warn(String(e)));
```
Im `finalize` (Close-Tab) Timer stoppen, `plc.removeAllListeners()`, `plc.disconnect()`.
Adressformat wie im `s7 endpoint`: `DB1,WORD0`, `DB5,REAL12`, `DB2,INT4`, `M10.0`, `I0.1`, `DB3,X2.3`.
