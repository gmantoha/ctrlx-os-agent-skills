# ctrlX Reference Guidance

## Platform Facts

- ctrlX apps run as snaps.
- AppArmor denials are often normal confinement events, not defects by themselves.
- ctrlX Data Layer is the preferred in-device integration path.
- REST APIs are the preferred external-client integration path.
- Some actions require Service Mode rather than Operation Mode.
- Real and virtual ctrlX systems do not expose identical hardware-backed capabilities.

## Interaction Methods

- SSH for shell access, service inspection, log review, and deep diagnostics
- Web UI for default guided configuration workflows and visual checks
- WebDAV for app data inspection and file transfer where supported
- REST API for external automation and integration, using documented authentication flows
- Data Layer for internal ctrlX communication
- Playwright for repeatable browser-based UI workflows

## Credential Policy

- Public default credentials may be documented when needed for labs or device defaults.
- Do not store employee-specific or customer-specific secrets in tracked files.
- Prefer example files and placeholders for anything non-default.

## Known Devices

Device-specific connection details and service accounts are documented under `reference/devices/`.

- `reference/devices/192.168.1.1.md` — primäres Arbeitsgerät; Service-Account `aiuser` für alle Skill-Operationen verwenden.

## Change Policy

On real devices, ask before changing persistent state.

Examples:

- app install or removal
- firewall and network changes
- user and certificate changes
- service restarts and reboots
- config writes over SSH, REST, WebDAV, or Web UI

## Core Guidance

- Use Data Layer when PLC code or on-device software communicates with another local ctrlX service.
- Use REST when a remote system, browser client, CI job, or external tool calls into ctrlX.
- Use WebDAV for app data access when the app exposes writable or readable directories there.
- Use Playwright when a UI workflow needs to be verified or demonstrated repeatedly.
- Prefer Web UI or REST over SSH for persistent device configuration such as network interfaces.
- Use SSH mainly for inspection, logs, services, and diagnostics unless a workflow explicitly requires shell-level changes.

## Frequent Pitfalls

- Token verifier timeouts are often overload symptoms.
- Mass Data Layer disconnects often indicate broader system stress.
- `COMPACTION is disabled` is a normal platform behavior on ctrlX hardware.
- Virtual devices may lack hardware-backed nodes and storage behaviors seen on real devices.
