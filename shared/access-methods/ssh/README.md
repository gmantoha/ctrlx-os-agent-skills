# SSH Access

Use SSH for shell inspection, service status, log review, and targeted configuration work.

SSH access requires a shell-capable user on the ctrlX OS device. On managed devices this user is typically provisioned through a Rexroth/manual process and delivered as an access file that must be uploaded to the device.

SSH must also be enabled on the device before login is possible. Where public defaults apply, credentials are typically `rexroot` / `rexroot`.

Typical uses:

- `snap list`
- `snap services`
- `snap logs <snap>.<service>`
- inspecting files under `/var/snap/...`
- reviewing deeper system logs and runtime state

For real devices, write operations should be confirmed first.

Do not assume every device setting can or should be changed through SSH. For persistent configuration, especially network interfaces, prefer the Web UI or REST API unless a documented workflow requires shell-level access.
