# Configure Device

Use this workflow for persistent ctrlX OS configuration tasks such as network, VPN, firewall, storage, users, certificates, routes, hostname, and system settings.

## Required Behavior

- Inspect current state first.
- Determine whether the target is real or virtual before writing changes.
- Prefer Web UI or documented REST for persistent configuration.
- Use SSH mainly for inspection, logs, services, and diagnostics unless a documented workflow requires shell-level changes.
- On real devices, propose exact UI actions, REST calls, or shell commands and wait for explicit confirmation before persistent changes.
- Document exact steps used and verify the result.

## Standard Flow

1. Ask for missing target details: IP, target type, credentials/access method, and desired end state.
2. Inspect mode, app list, service status, interface state, routes, and relevant app configuration.
3. Select the least invasive documented interface for the change.
4. Propose the exact change and verification method.
5. Apply only after confirmation when the target is real.
6. Verify from the device and, where useful, from the affected network/client side.
7. Report what changed, evidence, and rollback notes.

## Useful Recipes

- `recipes/network/`
- `recipes/firewall/`
- `recipes/storage/`
- `recipes/vpn/route-through-plc.md`
