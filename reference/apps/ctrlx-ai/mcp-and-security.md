# MCP, permissions and tool safety

Scope: supplied User Manual, **MCP Server**, **Additional MCP Servers**, **Tool Approvals**, **Changelog 0.5.0** and **Migration Guide**. See [sources](sources.md). Discover actual tool names and schemas at runtime.

## Local server and external clients

The snap exposes `https://<device-hostname>/mcp`. The local built-in agent always connects to its local MCP server. The snap configures localhost/service-to-service access, destructive operations with restrictions, app-data filesystem access and skills under `./.agents/skills/`.

The HTTPS endpoint requires an authenticated user. Current HTTP headers are:

```text
ctrlx-token: <token>
```

or `ctrlx-username` and `ctrlx-password`; `ctrlx-host` is the documented host header when needed. A token takes precedence over user/password. Do not put live credentials in tracked client settings. Environment variables such as `CTRLX_TOKEN` remain unchanged for standalone server processes; they are not the current HTTP header spellings. Underscore HTTP headers may be stripped by the ctrlX reverse proxy.

Use the transport supported by the installed version and client. The manual's VS Code example labels its connection `sse`, while the 0.5.0 changelog announces newer Streamable HTTP protocol support. Do not infer universal client compatibility or copy an old protocol date/handshake into a new deployment. Check current client documentation and server negotiation. The standalone executable is **`ctrlx-mcp-os`**, formerly `ctrlx-mcp-server`.

The server offers app management, Data Layer browse/read/metadata/subscriptions and gated mutations, logbook, AskRexroth, filesystem, HTTP, optional process execution and skills. App-management capabilities depend on the installed version; never infer installation tools or argument names from older tool tables.

## MCP server settings (`mcp/mcp.env`)

The file is still used in 0.5.0; do not confuse it with removed `agent.env`. Change only the required settings, preserving the existing file.

| Setting | Documented behavior |
|---|---|
| `CTRLX_MCP_RESPONSE_SCOPE` | `SLIM` or `VERBOSE`; verbose includes metadata |
| `CTRLX_MCP_DL_WRITE_ALLOWED` | Comma-separated write-path globs |
| `CTRLX_MCP_DL_DELETE_ALLOWED` | Comma-separated delete-path globs |
| `CTRLX_MCP_FILESYSTEM_FOLDERS` | Allowed filesystem roots; confirm effective roots with a tool |
| `CTRLX_MCP_PROCESS_ENABLED` | Default `false`; enables `execute_process` |
| `CTRLX_MCP_PROCESS_ALLOWED_COMMANDS` | Optional executable allow-list; unset means any command |
| `CTRLX_MCP_HTTP_ENABLED` | Default enabled |
| `CTRLX_MCP_HTTP_ALLOW_REMOTE` | Default empty = device only; external host patterns/IPs/CIDRs |
| `CTRLX_MCP_HTTP_COOKIES` | Default `true`; in-memory jar per MCP session |

Use narrow paths/hosts; avoid wildcard-wide permissions. The manual does not establish a hot-reload guarantee for `mcp.env`: verify the installed version's behavior instead of promising immediate application or restarting without confirmation.

## Separate the permission layers

1. The authenticated ctrlX user needs the relevant scopes. For solution files, 0.5.0 documents `rexroth-solutions.web.all.r` for reads and `rexroth-solutions.web.all.rw` for filesystem changes and `execute_process`.
2. Server configuration and hard-coded restrictions bound exposed operations.
3. The agent's approval gate and saved rules govern eligible calls.
4. The `ctrlx` skill additionally requires explicit confirmation before persistent real-device changes. An app auto-approval rule is not consent for an otherwise unapproved change in this conversation.

A denial at one layer is not fixed by disabling another. Diagnose user scopes, allowed roots/paths, exclusions, destructive-mode restrictions and approval decisions separately.

**Safety:** Data Layer paths under `safety` and `safety-plc` cannot be written, created or deleted, even if allow-listed. Do not use another interface to circumvent this. The manual associates this restriction with safety regulations; it is not evidence that an entire deployment is legally compliant.

## HTTP tool

Prefer discovered `http_request` over curl/process execution for REST tasks not covered by a typed tool. It supports GET/POST/PUT/PATCH/DELETE/HEAD, query/header/body variants (including JSON, text, file and multipart), bounded response sizes/timeouts, up to five redirects, response-to-file, SSE and WebSocket collection with limits. Read its schema before calling it.

### Authentication and destinations

- Relative URLs such as `/automation/api/v2/nodes/...` always target the connected ctrlX device. The server injects the connected user's token without exposing it to the AI, results or logs. Do not fetch a token manually just to use this tool.
- Token injection is restricted to that device over **HTTPS/WSS on port 443**, including checks on the address actually connected to, after redirects and for WebSocket handshakes. Other device ports or HTTP/WS receive no token.
- AI-provided `Authorization` and `Cookie` headers are ignored for the device. `Host` and `Proxy-*` headers are always ignored. Secrets are redacted from results; this is not permission to supply secrets unnecessarily.
- Only the device is reachable by default. `CTRLX_MCP_HTTP_ALLOW_REMOTE` can allow names, `*.domain`, IPs or CIDRs; prefer the smallest necessary set, not `*`. External connections use verified TLS and do not receive the ctrlX token. Link-local/cloud-metadata destinations remain blocked.
- Allowed remote hosts plus `body_file`/`multipart` can upload files from allowed filesystem folders. Show the destination, method and file to the user before an authorized upload. Do not bypass `.aiexclude` or other file protections.
- Device certificates are **not verified**. Remote-device standalone connections therefore carry interception/token-theft risk: use trusted networks; do not describe the connection as fully TLS-verified. External TLS verification remains enabled.
- System HTTP(S) proxies apply to external destinations, never to the device. Cookies live only in memory per MCP connection and are lost after reconnect/token changes.

`http_request` is classified as a destructive tool: **every call, including GET, passes the approval gate**, unless a matching saved rule or explicit bypass applies. Without destructive mode only GET/HEAD and listen-only streams work. A GET is not automatically exempt merely because ordinary read-only tools need no approval. Saving a response to disk can also change filesystem state.

## Process execution

`execute_process` is disabled by default, destructive and gated by approval. It launches an executable directly, with no shell interpretation, under a bounded timeout. Do not assume pipes, redirection or shell built-ins are interpreted.

The working directory is checked against `CTRLX_MCP_FILESYSTEM_FOLDERS`, but this is **not an OS-level sandbox**: the command can access whatever the app can access. Restrict executables using `CTRLX_MCP_PROCESS_ALLOWED_COMMANDS` if the tool is intentionally enabled. Allowing an interpreter such as Python or Node still permits broad actions through that interpreter. Do not enable the tool as a generic workaround for unavailable file/HTTP permissions or excluded secrets.

## Additional servers (`agent/mcp.yaml`)

```yaml
servers:
  remote-cell:
    description: "Additional automation cell"
    url: https://cell.example.com/mcp
    headers:
      ctrlx-username: !secret cell_username
      ctrlx-password: !secret cell_password
```

- Names accept only letters, digits and hyphens.
- The local ctrlX login token is **never forwarded**. Configure each additional server's own headers/credentials using `!secret`.
- `insecure_skip_verify: true` is available for self-signed certificates but should be a deliberate, explained exception on a trusted network, not the default example.
- Name collisions are prefixed, e.g. `remote-cell_datalayer_read`; discover actual client-visible names.
- Changes to this configuration / referenced credentials apply when **new conversations** connect. Test with a new conversation rather than restarting the app reflexively.

## Approval rules (`agent/approval-rules.json`)

Rules apply immediately; **first matching rule wins**. Approve/Decline affects one call; creating a rule persists future automatic decisions. No `arguments` constraint means every call of that tool.

```json
{
  "version": 1,
  "rules": [
    {"tool": "datalayer_delete", "effect": "deny"},
    {"tool": "http_request", "arguments": {"method": "GET", "url": "/automation/**"}, "effect": "allow"}
  ]
}
```

This example leaves Data Layer writes, mutating HTTP methods and unrelated HTTP destinations unmatched, unless another rule covers them. It does **not** constrain other HTTP arguments: a matching GET that saves its response to a file can still write. Use automatic approval only for known read-only calls without response-file output, or first verify additional argument restrictions supported by the actual schema. Do not promise that a method/URL rule alone guarantees zero side effects.

Use the actual tool name exposed by the target. Review existing order before inserting any rule; a preceding broad allow can defeat a later deny. Do not overwrite user rules with this example.

Pattern semantics are not interchangeable with model-discovery filters:

| Approval pattern | Matches |
|---|---|
| `*` alone | Any value, including values containing `/` |
| `a/*/c` | Exactly one intervening path segment |
| `a/**` | `a` and everything below it |

For device-only HTTP read approval, constrain **both** `method: GET` and a relative API prefix such as `url: /automation/**`. Do **not** use `url: /**`: the manual warns it also matches external URLs. Ordinary read-only tools do not prompt, but `http_request` retains its destructive-tool classification.
