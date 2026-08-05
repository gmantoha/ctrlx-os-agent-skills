# ctrlX OS Agent Skill Repository

## Start Here

1. **Device involved?** → Check MCP first: `tool_search_tool_regex("datalayer|ctrlx")`
   - Tools found → use them directly, skip REST/curl
   - Not found → use workflows below
2. **Pick workflow** from `workflows/` that matches the task
3. **Read** `reference/AGENTS.md` for platform rules before making assumptions
4. **Use recipe** from `recipes/` when a concrete playbook exists
5. **Confirm** before any persistent change on a real device

## Routing

| Task | Workflow |
|---|---|
| Device interaction (MCP available) | `workflows/use-mcp.md` |
| Crash / OOM / service failure / logs | `workflows/debug-issue.md` |
| Network / VPN / firewall / users / certs | `workflows/configure-device.md` |
| App install / update / remove | `workflows/manage-apps.md` |
| Snap build / Data Layer app / SDK | `workflows/build-app.md` |
| REST automation / external client | `workflows/use-rest-api.md` |
| Device Portal templates / serial commissioning | `workflows/device-portal-templates.md` |
| Data Layer reads / writes / PLC IPC | `workflows/use-datalayer.md` |
| File transfer / app data | `workflows/use-webdav.md` |
| UI config / Playwright | `workflows/use-web-ui.md` |
| Customer / colleague answer | `workflows/answer-customer.md` |
| ctrlX OS update | `workflows/update-os.md` |
| Virtual lab | `workflows/use-virtual-core.md` |

## Safety Rules

**Safe without confirmation:** reading docs, logs, local files, drafting commands/code/answers.

**Require confirmation on real device:**
- app install / remove / update
- network / firewall / VPN / certificates / users / storage changes
- service restarts, reboots
- any config write via REST, SSH, WebDAV, or Web UI

## Folder Intent

- `workflows/`: agent entry points per task type
- `reference/`: platform knowledge, best practices, app references
- `recipes/`: concrete playbooks for recurring procedures
- `labs/`: virtual ctrlX lab guides and scripts
- `cases/`: reusable sanitized investigations
- `customers/`: private workspaces, excluded from git

## Evidence Order

1. Official docs / OpenAPI / product PDFs
2. `reference/` notes
3. `cases/reusable/`
4. Direct device verification (virtual or real, with safety policy)
