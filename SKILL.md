---
name: ctrlx
description: Use for Bosch Rexroth ctrlX OS and ctrlX CORE tasks including debugging apps and services, configuring devices, VPN/network/firewall/storage setup, building ctrlX snaps, REST/Data Layer/WebDAV/Web UI workflows, PLC integration, virtual labs, demos, and customer technical answers.
allowed-tools: Read, Bash, Glob, Grep, WebFetch
---

# ctrlX OS Skill

Use this skill for ctrlX OS, ctrlX CORE, ctrlX apps, ctrlX Data Layer, ctrlX REST APIs, PLC integration, virtual ctrlX labs, app packaging, device configuration, diagnostics, customer answers, and demos.

## First Steps

1. Identify the task type.
2. Read the matching workflow from `workflows/`.
3. Read `reference/AGENTS.md` and any relevant platform, app, or access-method references under `reference/`.
4. If a device is involved, determine whether it is real or virtual before changing anything.
5. Produce commands, UI steps, code, or a customer answer with evidence and clear verification steps.

## Safety

Inspection, log review, local file analysis, and drafting commands are safe without confirmation.

Never perform persistent changes on a real ctrlX device without explicit user confirmation. Persistent changes include app install/removal/update, firewall/network/VPN/storage/user/certificate changes, service restarts, reboots, and config writes through SSH, REST, WebDAV, or Web UI.

For real-device changes, inspect first, propose exact commands or UI actions, wait for confirmation, apply the change, verify the result, and report what changed.

Always check and report the virtual lab instance status at the start and end of any session that uses it. Stop the virtual instance after testing completes unless the user explicitly asks to keep it running.

## Routing

Use `workflows/debug-issue.md` for crashes, OOM, service failures, logs, token verifier floods, Data Layer disconnects, and performance investigations.

Use `workflows/configure-device.md` for persistent ctrlX CORE configuration such as network, VPN, firewall, users, certificates, storage, routes, hostname, and system settings.

Use `workflows/manage-apps.md` for app installation, update, removal, service lifecycle, and app package handling.

Use `workflows/build-app.md` for snap packaging, app development, SDK usage, Data Layer integration, deployment, and build-deploy-debug loops.

Use `workflows/use-rest-api.md` for external automation, browser/client integration, and documented REST endpoints.

Use `workflows/use-datalayer.md` for on-device IPC, PLC-to-service communication, Data Layer reads/writes/calls, and node schema questions.

Use `workflows/use-web-ui.md` for UI-driven configuration, browser validation, screenshots, and Playwright-backed workflows.

Use `workflows/use-webdav.md` for file transfer and app data inspection through WebDAV.

Use `workflows/work-with-plc.md` for PLC Engineering, ST examples, and PLC integration guidance.

Use `workflows/use-virtual-core.md` for launching, stopping, monitoring, and testing against a local virtual ctrlX CORE lab.

Use `workflows/answer-customer.md` when the primary output is a customer or colleague technical answer.

Use `workflows/update-os.md` for upgrading ctrlX OS from local .app files, including system snap ordering, version polling, reboot handling, and core22 removal via remodel.

## Common Recipes

Use concrete playbooks under `recipes/` when available. For example, use `recipes/vpn/route-through-plc.md` when configuring a VPN route through a ctrlX CORE to a PLC/SPS network.

## Evidence Order

Prefer evidence in this order:

1. Official online docs, SDK pages, product PDFs, and documented REST/OpenAPI references.
2. Repository reference notes under `reference/`.
3. Reusable cases under `cases/reusable/`.
4. Direct inspection on a virtual or real ctrlX target, respecting the safety policy above.

For app-building and snap-packaging tasks, start with `reference/app-development/sources.md` and the live ctrlX Automation SDK docs. Treat offline or copied examples as fallback guidance, not as the primary source of truth.
