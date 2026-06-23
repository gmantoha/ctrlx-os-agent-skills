# ctrlX MCP Server App

The ctrlX MCP Server app exposes ctrlX OS device capabilities as
[Model Context Protocol (MCP)](https://modelcontextprotocol.io) tools. This allows AI agents
(Copilot CLI, Claude Code, OpenCode, etc.) to interact with ctrlX Data Layer nodes, device
management, logs, and app lifecycle through structured MCP tool calls instead of raw REST or SSH.

## Why MCP First

- No manual HTTP construction: the agent calls typed MCP tools instead of building `curl` commands.
- The MCP server handles authentication internally once configured.
- Tool schemas are self-describing — the agent can browse available operations at runtime.
- Reduces risk of malformed REST payloads or wrong Data Layer node paths.

## MCP Detection

Check with the correct package-manager endpoint:

```powershell
$token = (Invoke-WebRequest -Uri "https://<IP>/identity-manager/api/v1/auth/token" `
  -SkipCertificateCheck -Method POST -ContentType "application/json" `
  -Body '{"name":"boschrexroth","password":"boschrexroth"}' -UseBasicParsing | ConvertFrom-Json).access_token

Invoke-WebRequest -Uri "https://<IP>/package-manager/api/v1/packages/ctrlx-ai" `
  -SkipCertificateCheck -Headers @{Authorization="Bearer $token"} -UseBasicParsing | ConvertFrom-Json |
  Select-Object name, title, installed
```

If `installed: true` → MCP is available at `https://<IP>/mcp`.

## MCP Server Details (v0.2.3 / ctrlx-mcp-server 1.1.0)

| Property | Value |
|---|---|
| App snap name | `ctrlx-ai` |
| MCP Server version | `1.1.0` |
| MCP Protocol version | `2024-11-05` |
| Transport | Streamable HTTP (SSE) |
| Endpoint | `https://<IP>/mcp` |
| Auth header | `CTRLX_TOKEN: <token>` |
| Alt auth | `CTRLX_USERNAME` + `CTRLX_PASSWORD` headers |
| Required `Accept` | `application/json, text/event-stream` |

## Available Tools

### Data Layer
| Tool | Operation |
|---|---|
| `datalayer_read` | Read single value or bulk array of paths |
| `datalayer_write` | Write typed value (`{"type":"int32","value":42}`) |
| `datalayer_create` | Create node or call method with input params |
| `datalayer_delete` | Delete a node (irreversible) |
| `datalayer_browse` | Explore node tree from a given path |
| `datalayer_metadata` | Read node metadata (type, unit, ops supported) |
| `datalayer_subscribe` | Subscribe to value changes for N seconds |

### Apps & Device
| Tool | Operation |
|---|---|
| `apps_list_installed` | List all installed apps |
| `apps_get_details` | Detailed info on a specific app |
| `apps_enable` / `apps_disable` | Enable or disable an app |
| `logbook_list_entries` | Read logbook (filterable by level, time, type) |

### Embedded Skills (return structured guidance)
| Tool | Domain |
|---|---|
| `skill_motion` | Axes, kinematics, drives, EtherCAT, PLCopen |
| `skill_plc` | PLC runtime info |
| `skill_oscilloscope` | Signal recording and monitoring |
| `skill_ServiceIndicator` | Drive/motor health and lifetime |
| `skill_diagnosis` | Alarm overview, troubleshooting guidance |
| `skill_skillcreation` | How to create custom MCP skills |

### File System (app data access)
`read_text_file`, `write_file`, `edit_file`, `read_multiple_files`,
`list_directory`, `list_directory_with_sizes`, `directory_tree`,
`search_files`, `create_directory`, `move_file`, `get_file_info`,
`list_allowed_directories`, `read_media_file`

### Documentation
| Tool | Description |
|---|---|
| `askrexroth_documentation_search` | Query Bosch Rexroth knowledge base |
| `server_vscode_install_link` | Get VS Code MCP install link |

## MCP-First Policy (when installed)

When this app is installed and running:

1. Use `tools/list` to discover available operations.
2. Prefer MCP tool calls over direct REST calls or SSH for all device interactions.
3. Use REST / SSH only as fallback when a specific operation is not exposed as an MCP tool.
4. Apply the same confirmation policy for MCP write calls as for REST writes on real devices.

## References

- ctrlX App Catalog: `reference/apps/catalog.md`
- MCP detection workflow: `workflows/use-mcp.md`
- REST API workflow (fallback): `workflows/use-rest-api.md`
