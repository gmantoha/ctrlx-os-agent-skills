# Configure and Troubleshoot ctrlX AI / Agent iXi

Use this workflow for ctrlX AI / Agent iXi model/provider setup, AskRexroth limited mode, additional MCP servers, approval rules, custom prompts/skills, HTTP/process tools and migration from 0.3.0 to 0.5.0. It is part of the existing `ctrlx` skill, not a separately installed skill.

Read `reference/AGENTS.md` and [the app reference](../reference/apps/ctrlx-ai/README.md) first. Use `workflows/use-mcp.md` for general device interaction and `workflows/manage-apps.md` for app installation/update operations.

## Scope and evidence

These notes summarize the supplied **ctrlX AI - Automation Intelligence User Manual**, whose changelog describes **0.5.0** and migration from **0.3.0**. They are documentation-derived, not proof of behavior on a particular device. See [source provenance](../reference/apps/ctrlx-ai/sources.md).

Check the installed app version before applying version-dependent advice. For older or newer versions, verify the live tool schemas, shipped configuration templates and version-matched documentation rather than assuming these notes apply unchanged. Tool names can be prefixed by the client or additional server.

## Start here

1. Establish the task, app version and deployment: ctrlX OS snap or standalone. For device work, establish the target and whether it is real or virtual; do not infer a target from examples.
2. Discover connected ctrlX MCP tools first using the client's tool search/list facility. Prefer typed tools. For REST operations not exposed as typed tools, use the discovered `http_request` tool if available; do not invent its argument schema.
3. Inspect only the relevant non-secret configuration and logbook errors. Confirm the active configuration / allowed filesystem base at runtime. Paths such as `agent/models.yaml` below are relative to the app data in the **active configuration**, not to this repository or an assumed absolute solution path.
4. Load the relevant reference:

   | Task | Read |
   |---|---|
   | LLM provider, model selection, discovery, limits, caching, secrets or YAML errors | [Models and agent settings](../reference/apps/ctrlx-ai/models-and-agent.md) |
   | MCP authentication, additional servers, HTTP/process access, permissions or approval rules | [MCP and security](../reference/apps/ctrlx-ai/mcp-and-security.md) |
   | Custom prompts/skills, dashboard hosting, attachments or widget behavior | [Prompts and usage](../reference/apps/ctrlx-ai/prompts-and-usage.md) |
   | Upgrade from 0.3.0 or obsolete environment settings | [Migration recipe](../recipes/ctrlx-ai/migrate-0.3-to-0.5.md) |
   | Symptom-led diagnosis | [Troubleshooting](../reference/apps/ctrlx-ai/troubleshooting.md) |

5. Draft the smallest change that addresses the issue. For a real device, show the exact file/setting diff or action and its consequences, then wait for explicit confirmation before writing, installing, restarting or deleting anything. Approval rules in the application do not replace this conversation's confirmation policy.
6. Verify through read-back, the logbook and a new conversation where required. Report what was verified and what remains a proposal. A valid YAML parse alone does not establish that a provider or MCP connection works.

For documentation-only questions, answer from the references without requesting device access.

For new model configuration, start from [the sanitized model template](../templates/ctrlx-ai/models.yaml.example), not by overwriting an existing file. The app reference holds the configuration map and reload semantics.

## Non-negotiable boundaries

- Never write, create or delete Data Layer paths under `safety` or `safety-plc`. The MCP server blocks these even when allow-listed. Do not route around the block through REST, HTTP, process execution or another tool.
- Keep `approvals.skip: false`. Do not propose disabling approvals as a troubleshooting shortcut. Review rule ordering and scope instead of adding catch-all allow rules.
- Keep credentials out of tracked files, tool arguments, chat output and logs. Use `!secret` references and ask the user to provision values through a trusted channel. Do not bypass `.aiexclude`, including through a process or HTTP tool.
- Use only the filesystem scope, remote hosts, executable access and user permissions needed for the task. An allow-list or a process working-directory check is not an OS sandbox.
- Do not upload device data or attachments to an external service without the user's authorization. Messages, tool results and attachments reach the configured LLM provider; use one approved for the data.
- Custom prompts cannot disable application permissions or tool approval checks.

## High-value checks

- **AskRexroth warning / no tools:** establish whether `models.yaml` loaded successfully. Limited mode has no history, tools, skills or attachments and ignores `SystemPrompt.md`; prompt edits cannot fix this.
- **Saved model config appears ignored:** look for a reload error. Invalid configuration preserves the last valid catalog. Restarting is normally unnecessary for model or agent YAML changes.
- **Discovery exposes more models than expected:** explicit `models` entries are overrides/additions, not a discovery allow-list. Apply discovery filters or disable discovery and enumerate models.
- **Missing custom skill:** use `.agents/skills/custom/<name>/SKILL.md`, with the folder name equal to frontmatter `name`. Never edit `builtin/`.
- **Large generated file ends with EOF / “content is missing”:** inspect the active model's output limit. A supported `max_tokens: 16384` or higher may be needed; distinguish output budget from `context_window`.
- **Additional MCP credentials changed:** test with a new conversation. The local ctrlX login token is not forwarded to additional servers.

## Response shape

State the version assumption, diagnosis and evidence. Show the proposed paths and sanitized configuration/diff, any confirmation needed, and a short verification checklist. Distinguish documented behavior, observed behavior and unresolved assumptions. Do not claim a change was applied when only a draft was produced.
