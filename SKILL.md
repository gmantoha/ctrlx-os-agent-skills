---
name: ctrlx
description: Use for Bosch Rexroth ctrlX OS and ctrlX CORE tasks including debugging apps and services, configuring devices, VPN/network/firewall/storage setup, building ctrlX snaps, REST/Data Layer/WebDAV/Web UI workflows, PLC integration, virtual labs, demos, and customer technical answers.
allowed-tools: Read, Bash, Glob, Grep, WebFetch
---

# ctrlX OS Skill

Use this skill for ctrlX OS, ctrlX CORE, ctrlX apps, ctrlX Data Layer, ctrlX REST APIs, PLC integration, virtual ctrlX labs, app packaging, device configuration, diagnostics, customer answers, and demos.

## First Steps

1. Identify the task type.
2. **If a device is involved: check for MCP Server first.**
   Detect the `ctrlx-ai` snap via `GET /package-manager/api/v1/packages/ctrlx-ai`.
   - If installed → use `workflows/use-mcp.md` and MCP tools for all device interactions.
   - If not installed → proceed with standard workflows (REST, SSH, WebDAV, Web UI).
3. For Device Portal template or serial-commissioning work, read `workflows/device-portal-templates.md` before using any cloud or device endpoint.
4. Read the matching workflow from `workflows/`.
5. Read `reference/AGENTS.md` and any relevant platform, app, or access-method references under `reference/`.
6. Produce commands, UI steps, code, or a customer answer with evidence and clear verification steps.

## Safety

Inspection, log review, local file analysis, and drafting commands are safe without confirmation.

Never perform persistent changes on a real ctrlX device without explicit user confirmation. Persistent changes include app install/removal/update, firewall/network/VPN/storage/user/certificate changes, service restarts, reboots, and config writes through SSH, REST, WebDAV, or Web UI.

For real-device changes, inspect first, propose exact commands or UI actions, wait for confirmation, apply the change, verify the result, and report what changed.

Always check and report the virtual lab instance status at the start and end of any session that uses it. Stop the virtual instance after testing completes unless the user explicitly asks to keep it running.

## Routing

Use `workflows/use-mcp.md` **first** when a device is involved — check if `ctrlx-ai` (MCP Server) is installed. If yes, use MCP tools for all device operations. If no, fall back to the workflows below.

Use `workflows/debug-issue.md` for crashes, OOM, service failures, logs, token verifier floods, Data Layer disconnects, and performance investigations.

Use `workflows/configure-device.md` for persistent ctrlX CORE configuration such as network, VPN, firewall, users, certificates, storage, routes, hostname, and system settings.

Use `workflows/manage-apps.md` for app installation, update, removal, service lifecycle, and app package handling.

Use `workflows/build-app.md` for snap packaging, app development, SDK usage, Data Layer integration, deployment, and build-deploy-debug loops.

Use `workflows/use-rest-api.md` for external automation, browser/client integration, and documented REST endpoints.

Use `workflows/device-portal-templates.md` for Device Portal API template creation/application, full-device restore demonstrations, and serial commissioning design.

Use `workflows/use-datalayer.md` for on-device IPC, PLC-to-service communication, Data Layer reads/writes/calls, and node schema questions.

Use `workflows/use-web-ui.md` for UI-driven configuration, browser validation, screenshots, and Playwright-backed workflows.

Use `workflows/learn-from-ui.md` when the correct Data Layer payload format is unknown, a REST write fails with type errors, or the user performs a UI action and you want to learn the underlying API calls via Data Layer Diff.

Use `workflows/use-webdav.md` for file transfer and app data inspection through WebDAV.

Use `workflows/work-with-plc.md` for PLC Engineering, ST examples, and PLC integration guidance.

Use `workflows/use-virtual-core.md` for launching, stopping, monitoring, and testing against a local virtual ctrlX CORE lab.

Use `workflows/answer-customer.md` when the primary output is a customer or colleague technical answer.

Use `workflows/update-os.md` for upgrading ctrlX OS from local .app files, including system snap ordering, version polling, reboot handling, and core22 removal via remodel.

Use `workflows/contribute-skill.md` for installing/updating this skill (Pull), capturing something newly learned (Teach), or contributing a learning back to this repository (Push).

## Common Recipes

Use concrete playbooks under `recipes/` when available. For example:
- `recipes/app-build/profile-driven-hmi.md` — project-specific PLC discovery, mapping, diagnostics, Motion separation, and capability-aware UI gating
- `recipes/app-build/ctrlx-snap-build-install-loop.md` — Windows source to ABE build, architecture selection, snap inspection, and virtual/real CORE installation
- `recipes/app-build/minimal-web-app.md` — package-assets, reverse proxy, and web-snap verification
- `recipes/app-build/datalayer-provider.md` — Data Layer provider design, packaging, and runtime checks
- `recipes/vpn/route-through-plc.md` — VPN-Route durch ctrlX CORE zu PLC/SPS-Netz
- `recipes/motion/axis-create-delete.md` — Axes anlegen, konfigurieren, löschen; posMax-Grenzen; Rotary Spindle (constant RPM)
- `recipes/motion/axis-power-and-move.md` — Power ON/OFF (POST!), absolute move, unit table, polling
- `recipes/motion/axis-error-reset.md` — ERRORSTOP reset; `cmd/reset` known issues; STOPPED deadlock fix; SETUP-cycle fallback
- `recipes/motion/axis-velocity-limits.md` — Achsgeschwindigkeitsgrenzen lesen/schreiben
- `recipes/motion/bom-to-motion-profile.md` — Kunden-Stückliste (Motoren/Drives/Lizenzen) → Motion-Achskonfiguration; BOM-Plausibilitätsprüfungen
- `recipes/motion/axis-config-persistence.md` — Motion-Konfiguration speichern: **ungelöst** über REST; Achsen gehen beim Reboot verloren
- `recipes/motion/motion-opstate-switch.md` — SETUP ↔ OPERATING; axes must be DISABLED first
- `recipes/motion/simultaneous-axis-moves.md` — Mehrere Achsen gleichzeitig bewegen
- `recipes/oscilloscope/setup-oscilloscope-instance.md` — Oszilloskop-Instanz einrichten und starten
- `recipes/io-engineering/project-and-ethercat-topology.md` — IO Engineering Projekt anlegen und EtherCAT-Topologie mit ctrlX I/O aufbauen
- `recipes/io-engineering/topology-from-bom.md` — Kunden-Stückliste → EtherCAT-Topologie; was aus einer BOM ableitbar ist und was nicht ("eine BOM sagt *was*, nie *wo*")
- `recipes/plc/deploy-and-start.md` — PLC Build → Download → Start via Engineering REST API (vollständige Job-Sequenz, Ports, Troubleshooting)
- `recipes/plc/axis-interface-motion.md` — AxisInterface (CXA_MotionInterface) ST-Muster: Init, Power, Move, Diagnose
- `recipes/plc/axis-interface-velocity.md` — Direkte arAxisCtrl_gb/arAxisStatus_gb Velocity-Steuerung; Admin.Active Guard; Datalayer Symbols
- `recipes/plc/real-device-ports.md` — Ports real vs. virtuell (httpsPort 443/8443, plcPort 11740/8740); nodeUrl-Format; Auth-Session-Limit
- `recipes/plc/create-pou-gvl.md` — POUs und GVLs per REST API anlegen und aktualisieren
- `recipes/plc/engineering-scripting.md` — CODESYSScript (Verfügbarkeit prüfen!) vs. REST API

## Motion Task — Standard Sequence

For any motion task (create axes, move, sequence), follow this order:

1. **Read** the relevant recipe(s) first — never guess API format
2. **Check mode**: `GET motion/state/opstate` — is it Configuration or Running?
3. **For config changes**: ensure all axes DISABLED, switch to SETUP, make changes, save, switch to OPERATING
4. **Wait** 10–12 s after OPERATING switch before polling axis states
5. **Power ON**: `POST cmd/power {"type":"bool8","value":true}` (POST, not PUT)
6. **Move**: `POST cmd/pos-abs` — fire all simultaneous moves before any polling
7. **Poll**: check `state/opstate/plcopen` until STANDSTILL; check for ERRORSTOP
8. **Power OFF all axes** before ending — any axis left STANDSTILL blocks the next SETUP switch

## Evidence Order

Prefer evidence in this order:

1. Official online docs, SDK pages, product PDFs, and documented REST/OpenAPI references.
2. Repository reference notes under `reference/`.
3. Reusable cases under `cases/reusable/`.
4. Direct inspection on a virtual or real ctrlX target, respecting the safety policy above.

For app-building and snap-packaging tasks, start with `reference/app-development/sources.md` and the live ctrlX Automation SDK docs. Treat offline or copied examples as fallback guidance, not as the primary source of truth.
