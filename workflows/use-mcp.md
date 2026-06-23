# Use MCP Server

Use this workflow when the ctrlX MCP Server app is (or may be) installed on the target device.
MCP (Model Context Protocol) is the preferred interaction layer when available — it exposes ctrlX
REST, Data Layer, and device management as structured MCP tools that the agent can call directly
without manually constructing HTTP requests or SSH commands.

## MCP Detection (Run First on Every Device Session)

Before using any other access method (REST, SSH, WebDAV, Web UI), check whether the MCP Server
app is installed on the target ctrlX device.

### Method 1 — REST API (preferred, no SSH required)

The correct package-manager endpoint on ctrlX OS 4.x is `/package-manager/api/v1/packages/<name>`:

```powershell
$token = (Invoke-WebRequest -Uri "https://<IP>/identity-manager/api/v1/auth/token" `
  -SkipCertificateCheck -Method POST -ContentType "application/json" `
  -Body '{"name":"boschrexroth","password":"boschrexroth"}' -UseBasicParsing |
  ConvertFrom-Json).access_token

Invoke-WebRequest -Uri "https://<IP>/package-manager/api/v1/packages/ctrlx-ai" `
  -SkipCertificateCheck -Headers @{Authorization="Bearer $token"} -UseBasicParsing |
  ConvertFrom-Json | Select-Object name, title, installed
```

If `installed: true` → **MCP is available. Use MCP for all further operations.**

If 404 → MCP is not installed → continue with the standard workflows.

> **Note:** The snap name is `ctrlx-ai`. The MCP server component inside is `ctrlx-mcp-server`.
> Do NOT use `/api/v1/package-manager/applications` — that path returns HTML on ctrlX OS 4.6.

### Method 2 — Web UI

Open `https://<IP>` → **Apps** → search for "ctrlx-ai". If it appears as installed, MCP is available.

### Method 3 — SSH fallback

```bash
ssh -p 8022 boschrexroth@<IP> "snap list ctrlx-ai"
```

## When MCP Is Available

Use the MCP tools provided by the MCP Server app for **all** of the following instead of direct
REST calls, SSH commands, or WebDAV:

| Task | Without MCP | With MCP |
|---|---|---|
| Read/write Data Layer nodes | REST `GET/PUT /api/v1/...` | `datalayer_read`, `datalayer_write` MCP tools |
| Browse Data Layer tree | SSH + ctrlx-datalayer-client | `datalayer_browse` MCP tool |
| Read device state, apps, logs | REST `/api/v1/...` | MCP system/device tools |
| Manage apps | REST package-manager API | MCP app-management tools |
| Diagnose services | SSH journalctl | MCP log/diagnostic tools |

> The exact MCP tool names depend on the installed MCP Server app version. Browse the available
> MCP tools at session start with the agent's built-in MCP tool listing.

## MCP Connection Setup

### Endpoint

```
https://<IP>/mcp
```

The app name on ctrlX OS is **`ctrlx-ai`**. Detect it via:

```powershell
Invoke-WebRequest -Uri "https://<IP>/package-manager/api/v1/packages/ctrlx-ai" `
  -SkipCertificateCheck -Headers @{Authorization="Bearer <token>"} -UseBasicParsing
```

### Authentication

**Option A — Token (recommended):**
```
Header: CTRLX_TOKEN: <bearer-token>
```
Obtain token: `POST https://<IP>/identity-manager/api/v1/auth/token` with `{"name":"...","password":"..."}`

**Option B — Credentials directly:**
```
Header: CTRLX_USERNAME: <user>
Header: CTRLX_PASSWORD: <pass>
```

### Required Headers for Every Request

```
Content-Type: application/json
Accept: application/json, text/event-stream
CTRLX_TOKEN: <token>
```

The response is always a **Server-Sent Events stream** (`text/event-stream`).
Each `data:` line is a JSON-RPC response object.

### Session Handshake (Batch — Recommended)

Send initialize + notifications/initialized + tools/list in a single batch POST:

```json
[
  {"jsonrpc":"2.0","id":1,"method":"initialize","params":{
    "protocolVersion":"2024-11-05","capabilities":{},
    "clientInfo":{"name":"my-agent","version":"1.0"}}},
  {"jsonrpc":"2.0","method":"notifications/initialized","params":{}},
  {"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}
]
```

> **Note:** Sequential single requests require passing `Mcp-Session-Id` from the initialize
> response header in all subsequent requests. The batch approach avoids this complexity.

## Copilot CLI Integration (mcp.json)

To use ctrlX MCP tools natively as agent tools (without manual HTTP calls), register the server
in `~/.copilot/mcp.json`:

```json
{
  "servers": {
    "ctrlx": {
      "type": "http",
      "url": "https://127.0.0.1:8443/mcp",
      "headers": {
        "CTRLX_USERNAME": "boschrexroth",
        "CTRLX_PASSWORD": "boschrexroth"
      }
    }
  }
}
```

Adjust `url` to match the actual device IP/port. Use `/mcp` in the CLI to open this file.
After adding the entry, restart the session — `datalayer_read`, `datalayer_write`,
`datalayer_browse`, `skill_motion`, `skill_oscilloscope` etc. become available as native tools.

> **Self-signed certificate:** ctrlX OS uses a self-signed TLS certificate. If the CLI rejects it,
> the connection will fail silently. In that case, fall back to raw HTTP calls via `powershell`
> using `-SkipCertificateCheck`.

## Fallback Decision

```
Device involved?
  └─ Yes → Is MCP Server app installed and running?
              ├─ Yes  → Use MCP tools (this workflow)
              └─ No   → Use standard workflows:
                          REST     → workflows/use-rest-api.md
                          DataLayer→ workflows/use-datalayer.md
                          SSH diag → workflows/debug-issue.md
                          File I/O → workflows/use-webdav.md
                          UI       → workflows/use-web-ui.md
```

## Safety

MCP tool calls that write state or change configuration on a real device are persistent changes.
Apply the same confirmation policy as for REST and SSH:

- Inspect first.
- Propose the MCP call and expected result.
- Wait for explicit user confirmation before executing writes on a real device.
- Verify the result after execution.
