# ctrlX AI — Automation Intelligence / Agent iXi

ctrlX AI (snap `ctrlx-ai`) provides a device MCP server, the built-in Agent iXi and a header chat widget. Configuration, migration and diagnosis are part of the existing **`ctrlx` skill**. There is no second skill to install.

Start with [the configuration workflow](../../../workflows/configure-ctrlx-ai.md). The notes below are derived from the supplied User Manual with changelog **0.5.0**, not from a live device test. Check the installed version before applying them; see [source provenance and limits](sources.md).

## Reference map

| Topic | File |
|---|---|
| Provider/model schema, autodiscovery, YAML includes/secrets, limits and caching | [Models and agent settings](models-and-agent.md) |
| MCP auth, additional servers, permissions, HTTP/process tools and approvals | [MCP and security](mcp-and-security.md) |
| System prompt, custom skills, attachments, hosted web apps and widget | [Prompts and usage](prompts-and-usage.md) |
| Symptom-led diagnosis | [Troubleshooting](troubleshooting.md) |
| Concrete upgrade procedure | [Migration 0.3.0 → 0.5.0](../../../recipes/ctrlx-ai/migrate-0.3-to-0.5.md) |
| Starting point for a model configuration | [Sanitized YAML template](../../../templates/ctrlx-ai/models.yaml.example) |

## Configuration map (0.5.0)

Paths are relative to the app data in the **active configuration**, not to this repository. Confirm the effective allowed filesystem base at runtime rather than assuming an absolute solution path.

```text
mcp/
  mcp.env                 MCP server configuration; still used
agent/
  models.yaml             LLM providers, models, roles and defaults
  secrets.yaml            Secret scalar values; do not read with AI tools
  agent.yaml              Approval and logging settings
  mcp.yaml                Additional MCP servers
  approval-rules.json     Saved tool-call decisions
  .gitignore              Excludes secrets.yaml from Git
  .aiexclude              Blocks AI access to secrets.yaml and itself
.agents/
  SystemPrompt.md         Additions to the built-in prompt
  skills/builtin/         Shipped skills; replaced on every app start
  skills/custom/          User skills: <name>/SKILL.md plus resources
  attachments/            Non-image uploads available to file tools
  www/                    Hosted web content
```

The MCP endpoint is `https://<device-hostname>/mcp`. Installation is through **Settings → Apps → Install App**; installation on a real device requires confirmation. Configuration templates are provisioned on first load. Do not overwrite an existing configuration with an example.

## Related platform guidance

- [General MCP workflow](../../../workflows/use-mcp.md)
- [MCP server reference and historical connection examples](../mcp-server/README.md)
- [App lifecycle workflow](../../../workflows/manage-apps.md)
- [Platform rules and credential policy](../../AGENTS.md)
