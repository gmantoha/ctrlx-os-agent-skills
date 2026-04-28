# VPN Route Through PLC / SPS Network

Use this recipe when configuring a ctrlX CORE so traffic from a VPN reaches a PLC/SPS or an automation subnet behind the device.

## Collect First

- ctrlX CORE IP address and whether the target is real or virtual.
- VPN app/client type and configured tunnel network.
- PLC/SPS IP address and subnet.
- Local ctrlX interface connected to the PLC/SPS network.
- Remote VPN peer/client subnet and desired routed networks.
- Whether the remote side can add routes back to the PLC/SPS subnet.
- Whether NAT/masquerading is acceptable or a pure routed setup is required.
- Current Firewall app state and whether persistent firewall changes are allowed.

## Inspect

Use read-only inspection first:

1. Check installed VPN and Firewall apps and service status.
2. Check ctrlX interface addresses and routes.
3. Check VPN tunnel status and assigned routes.
4. Check existing firewall filter, NAT, routing, and directional interface rules.
5. Verify whether the PLC/SPS gateway points back to the ctrlX CORE or another router.

## Decide

Choose one of these patterns:

- Pure routing: preferred when both VPN peer and PLC/SPS network have correct return routes.
- NAT/masquerade: useful when the PLC/SPS cannot route back to the VPN client subnet.
- Port forwarding: only for narrow access to specific PLC/SPS services, not general subnet reachability.

## Change Plan

For a real device, propose the exact Web UI steps, REST calls, or shell commands and wait for explicit confirmation before applying them.

Typical persistent changes may include:

- Add VPN route for the PLC/SPS subnet.
- Add route on the remote VPN peer for the PLC/SPS subnet via the VPN tunnel.
- Add firewall allow rules between VPN interface and PLC/SPS interface.
- Add NAT/masquerade rule if return routing is unavailable.
- Persist firewall configuration after verifying it works.

## Verify

Verify from both directions where possible:

1. From VPN client to ctrlX VPN tunnel address.
2. From VPN client to PLC/SPS IP.
3. From ctrlX CORE to PLC/SPS IP.
4. From PLC/SPS network back toward the VPN client subnet if pure routing is used.
5. Relevant application protocol, not only ping, if ICMP is blocked.

## Report

Report:

- Final route/NAT/filter model.
- Interfaces and subnets involved.
- Exact changes made.
- Verification evidence.
- Rollback steps.
