# Quellenverzeichnis

Datum: 2026-04-20

## Community-Threads

**[1] Mount and remove safety USB from Datalayer (PLC or Node Red)**  
https://community.boschrexroth.com/ctrlx-core-25gnfzl4/post/mount-and-remove-safety-usb-from-datalayer-plc-or-node-red-5fn56hKDAZRATPF  
Relevanz: Best Reply von Moderator *CodeShepherd* bestätigt Data-Layer-Pfad `system/resources/tasks/storage` ab OS 4.4; nennt außerdem kommerzielle HTTP-Libraries für PLC als Alternative.

**[2] USB mount/remove commands via PLC**  
https://community.boschrexroth.com/ctrlx-core-25gnfzl4/post/usb-mount-remove-commands-via-plc-MnSgAKZqsSeZCzi  
Relevanz: Ähnliches Szenario, Community-Nutzer *alink* beschreibt Workaround über WebBrowser-Widget in WebVisu mit eingeschränktem Storage-User.

## SDK-Dokumentation

**[3] ctrlX Automation SDK — Storage Extension**  
https://boschrexroth.github.io/ctrlx-automation-sdk/4.6.0/storage-extension.html  
Hinweis: Beschreibt "Storage Extension" (verschlüsselte Gerätebindung) — unterschiedlich vom hier beschriebenen "Data Exchange" (normales USB-Mounten für Datenaustausch).

**[4] ctrlX Automation SDK — Data Layer**  
https://github.com/boschrexroth/ctrlx-automation-sdk/blob/main/doc/datalayer.md  
Allgemeine Dokumentation des Data-Layer-Konzepts und der REST-API.

**[5] ctrlX CORE REST API — Overview**  
https://boschrexroth.github.io/rest-api-description/ctrlx-automation/ctrlx-core/index.html  
OpenAPI-Beschreibungen für alle ctrlX CORE REST APIs.

## Handbücher (lokal)

**[6] ctrlX PLC App, Application Manual EN (Rev 03)**  
`ctrlx-docs/R911423401_03_ctrlX PLC, App, ApplicationManual_EN.pdf`  
Kapitel Data Layer Connection (Kap. 6): Beschreibt CXA_DataLayer-Integration, DL_Read/Write/Call-Bausteine.

**[7] CXA_DataLayer — Bibliotheksdokumentation**  
https://docs.automation.boschrexroth.com/doc/593878435/cxa-datalayer/latest/en/  
Referenz für alle Funktionsbausteine der CXA_DataLayer-Bibliothek in ctrlX PLC Engineering.

## Device-Probe (direkt verifiziert)

**[8] Direkte Inspektion ctrlX M4 (192.168.47.219), ctrlX OS 4.6**  
Datum: 2026-04-20  
Methode: SSH (rexroot), sudo python3, DL REST API v2 via Unix Socket  
`/var/snap/rexroth-automationcore/2302/package-run/rexroth-automationcore/datalayer.web.sock`  
Ergebnisse: Siehe `device-probe.txt`

Verifizierte Knoten:
- `system/resources/tasks/storage/mountDevice` — POST, JSON-Schema `tasks_MountDevice`
- `system/resources/tasks/storage/unmount` — POST, JSON-Schema `tasks_Unmount`
- `system/resources/storage` — GET, liefert Liste aller Medien mit UUID/mounted-Status
- Typ-Schemas aus: `types/storage/tasks/mountDevice`, `types/storage/tasks/unmount`
