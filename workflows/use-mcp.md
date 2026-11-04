# Use MCP Server

Preferred interaction layer when ctrlX AI app is installed. Use MCP tools instead of REST/SSH/curl.

For ctrlX AI / Agent iXi **0.5.0 configuration, authentication and migration**, read
`skills/ctrlx-ai/SKILL.md` and its bundled references. Check the installed version;
client-visible tool names and capabilities vary. Current HTTP authentication headers
are hyphenated (`ctrlx-token` or `ctrlx-username` / `ctrlx-password`), not the legacy
uppercase underscore names. Server environment-variable names remain unchanged.

## Step 1 — Are MCP Tools Available?

**In Copilot CLI:** call `tool_search_tool_regex("datalayer|ctrlx")`.
- Tools found (`ctrlx-datalayer_read` etc.) → **use them directly, go to Step 2**
- Not found → set up Copilot CLI integration → `reference/apps/mcp-server/README.md`

**On a new device:** check if `ctrlx-ai` snap is installed:
```powershell
$token = (Invoke-WebRequest -Uri "https://<IP>/identity-manager/api/v1/auth/token" `
  -SkipCertificateCheck -Method POST -ContentType "application/json" `
  -Body '{"name":"boschrexroth","password":"boschrexroth"}' -UseBasicParsing |
  ConvertFrom-Json).access_token

Invoke-WebRequest -Uri "https://<IP>/package-manager/api/v1/packages/ctrlx-ai" `
  -SkipCertificateCheck -Headers @{Authorization="Bearer $token"} -UseBasicParsing |
  ConvertFrom-Json | Select-Object name, installed
```
- `installed: true` → MCP available at `https://<IP>/mcp`
- 404 → not installed → use `workflows/use-rest-api.md` or `workflows/use-datalayer.md`

## Step 2 — Use MCP Tools

| Task | Tool |
|---|---|
| Read Data Layer node | `ctrlx-datalayer_read` |
| Write Data Layer node | `ctrlx-datalayer_write` |
| Browse node tree | `ctrlx-datalayer_browse` |
| Create node / call method | `ctrlx-datalayer_create` |
| Delete node | `ctrlx-datalayer_delete` |
| Read metadata / type info | `ctrlx-datalayer_metadata` |
| Subscribe to changes | `ctrlx-datalayer_subscribe` |
| List installed apps | `ctrlx-apps_list_installed` |
| Read logbook | `ctrlx-logbook_list_entries` |
| Motion guidance | `ctrlx-skill_motion` |
| Oscilloscope guidance | `ctrlx-skill_oscilloscope` |
| PLC info | `ctrlx-skill_plc` |
| Rexroth docs search | `ctrlx-askrexroth_documentation_search` |

> **Before writing:** always browse the node path first to verify it exists and get the correct schema.

## Step 3 — Missing skill_* Tools?

First discover the installed version's skill tools and allowed filesystem roots.
In **0.5.0**, create custom skills relative to the active app-data configuration:

```text
.agents/skills/custom/<name>/SKILL.md
```

The folder name must match the skill's frontmatter `name`. Copy any supporting
resources too. Never edit `skills/builtin/`: it is replaced on each app start.
Legacy flat Markdown files have lower priority and should not be used for new
0.5.0 skills. See `skills/ctrlx-ai/references/prompts-and-usage.md`.

Discover any skill-creation guidance tool rather than assuming an old `skill_*`
name exists. Show the exact proposed file changes and obtain confirmation before
writing to a real device. Do not assume an absolute `DefaultSolution` path.

## Safety

MCP write calls on real devices = persistent changes. Same rules as REST/SSH:
- Inspect first, propose, wait for confirmation, then execute, then verify.

## Setup / Troubleshooting

→ `reference/apps/mcp-server/README.md`
