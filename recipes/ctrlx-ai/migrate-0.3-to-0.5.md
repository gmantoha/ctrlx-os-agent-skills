# Migrate ctrlX AI / Agent iXi from 0.3.0 to 0.5.0

Use this recipe through [the ctrlX AI configuration workflow](../../workflows/configure-ctrlx-ai.md). Read [the app reference](../../reference/apps/ctrlx-ai/README.md) and its [source limits](../../reference/apps/ctrlx-ai/sources.md) before applying version-dependent advice.

Configuration is **not automatically converted**. Confirm source/target versions. Draft a per-file plan and obtain confirmation before changes on a real device. Back up the active configuration, custom skills, prompt and credentials through an approved method; do not copy secrets into this repository or tool output. All app paths below are relative to the active app-data configuration.

## 1. Split configuration from context

| Existing item | 0.5.0 action |
|---|---|
| `mcp/mcp.env` | Keep; still configures the MCP server |
| `mcp/agent.env` / agent environment config | Replace with `agent/models.yaml`, `agent/secrets.yaml`, `agent/agent.yaml` |
| `.agents/mcp.yaml` | Copy to `agent/mcp.yaml` if used |
| `.agents/approval-rules.json` | Copy to `agent/approval-rules.json`; review order and wildcard scope |
| `.agents/SystemPrompt.md` | Keep machine-specific additions; now supplements built-ins |
| Customized flat skill files | Move with resources to `.agents/skills/custom/<name>/SKILL.md` |

The app provisions templates on startup. Fill them from the approved existing configuration rather than overwriting with defaults. Preserve generated `agent/.gitignore` and `.aiexclude`; if an existing exclusion file has a `.new` template, merge the relevant protections so `secrets.yaml` stays excluded. This does **not** mean `.new` system prompts are loaded.

## 2. Convert provider/settings fields

Old suffixes below refer to `CTRLX_AGENT_LLM_*`:

| Old suffix | New YAML field |
|---|---|
| `PROVIDER` | `providers.<id>.type`: `openai` or `anthropic` |
| `API_KEY` | `providers.<id>.api_key: !secret <name>`; value in protected `secrets.yaml` |
| `BASE_URL` | Provider or per-model `base_url` |
| `OPENAI_API_VERSION` | Provider `api_version` |
| `MODEL` | Key in `providers.<id>.models`; select with `default_model: <id>/<model>` |
| `MAX_TOKENS` | Model `max_tokens` |
| `CONTEXT_WINDOW_SIZE` | Model `context_window` |
| `REQUEST_TIMEOUT_SECS` | Provider `timeout_secs` |

Set `version: 1`. OpenAI-compatible base URLs stop before `/chat/completions`. Anthropic Vertex proxy URLs stop at `/publishers/anthropic/models`: remove the old model suffix, set `compat: vertex-rawpredict`, and let the model key supply that suffix. Use manual model configuration for deployment-only Azure and Vertex.

Set a confirmed context window for providers that do not report it, including OpenAI and Bosch AI Farm. Omit it or use `0` only for supported automatic behavior. Omit `max_tokens` when previously unset or `0`; an explicit value must be positive. Replace `${VAR}` references with concrete non-secret values or `!secret`; YAML does not expand environment variables.

Convert `CTRLX_AGENT_SKIP_APPROVALS` to `approvals.skip` in `agent/agent.yaml`, preserving the safe default `false` rather than blindly retaining a bypass. Convert `DEBUG=true` to `log.level: debug` if needed. Unknown keys are errors, not ignored compatibility settings. For a new draft, use [the sanitized model template](../../templates/ctrlx-ai/models.yaml.example) with confirmed provider/model values; it is not a migration converter.

## 3. Preserve custom behavior safely

- Remove duplicated stock instructions from the new **additive** prompt only after reviewing the user's custom content. Keep a backup of the old full replacement prompt for rollback/downgrade.
- Custom skills need matching folder/frontmatter names. Copy supporting scripts/references, not just `SKILL.md`. Never edit `builtin/`, which is replaced on app start.
- Remove obsolete duplicate flat skill files only after verifying the migrated version and obtaining approval for the deletion. Legacy files have lower priority but can still cause confusion.

## 4. Update clients and standalone launchers

- HTTP headers: use `ctrlx-host`, `ctrlx-username`, `ctrlx-password`, `ctrlx-token`, not uppercase underscore names. MCP server **environment variable names stay unchanged**.
- Rename standalone executable `ctrlx-mcp-server` → `ctrlx-mcp-os`.
- Remove agent `--env` / `-e`; `agent.env` and `CTRLX_AGENT_LLM_*` are no longer supported.
- Replace `CTRLX_AGENT_DATA_DIR` with `CTRLX_AGENT_CONFIG_DIR`, pointing to the YAML / approval-rule folder (standalone default `data`).
- Replace `CTRLX_AGENT_SYSTEM_PROMPT` with `CTRLX_AGENT_CONTEXT_DIR`, pointing to the **folder** containing `SystemPrompt.md` (default `.agents`).
- If previously supplied through `agent.env`, set `CTRLX_AGENT_MCP_TRANSPORT` and `CTRLX_AGENT_MCP_SERVER_URL` in the process environment. The ctrlX OS app sets these automatically.

## 5. Verify, then clean up

1. Inspect the logbook for configuration/include/secret/catalog errors, without exposing values.
2. Open a new conversation; confirm the intended provider/model with `/model` and that the limited-mode warning is gone.
3. Test a read-only local MCP operation, then an additional server using its own configured credentials. Confirm user file scopes when file access is needed.
4. Test custom skill discovery and prompt additions; verify no content was unintentionally overwritten.
5. Review migrated rules: **first match wins**, and a bare `*` now includes values containing `/`. Validate narrow HTTP read rules without performing unauthorized writes.
6. Confirm `safety` / `safety-plc` writes remain blocked from documentation/configuration; do not perform a real safety write as a test.
7. Read back changed non-secret files and report verified results, remaining risks and rollback locations. Keep backups private.
