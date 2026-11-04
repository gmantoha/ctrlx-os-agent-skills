# Migration and troubleshooting

Scope: supplied User Manual, **Changelog 0.5.0**, **Migration Guide: 0.3.0 to 0.5.0**, model troubleshooting and **Large text file generation fails**. See [sources](sources.md).

## Migration: 0.3.0 → 0.5.0

Configuration is **not automatically converted**. Confirm source/target versions. Draft a per-file plan and obtain confirmation before changes on a real device. Back up the active configuration, custom skills, prompt and credentials through an approved method; do not copy secrets into this repository or tool output.

### 1. Split configuration from context

| Existing item | 0.5.0 action |
|---|---|
| `mcp/mcp.env` | Keep; still configures the MCP server |
| `mcp/agent.env` / agent environment config | Replace with `agent/models.yaml`, `agent/secrets.yaml`, `agent/agent.yaml` |
| `.agents/mcp.yaml` | Copy to `agent/mcp.yaml` if used |
| `.agents/approval-rules.json` | Copy to `agent/approval-rules.json`; review order and wildcard scope |
| `.agents/SystemPrompt.md` | Keep machine-specific additions; now supplements built-ins |
| Customized flat skill files | Move with resources to `.agents/skills/custom/<name>/SKILL.md` |

The app provisions templates on startup. Fill them from the approved existing configuration rather than overwriting with defaults. Preserve generated `agent/.gitignore` and `.aiexclude`; if an existing exclusion file has a `.new` template, merge the relevant protections so `secrets.yaml` stays excluded. This does **not** mean `.new` system prompts are loaded.

### 2. Convert provider/settings fields

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

Convert `CTRLX_AGENT_SKIP_APPROVALS` to `approvals.skip` in `agent/agent.yaml`, preserving the safe default `false` rather than blindly retaining a bypass. Convert `DEBUG=true` to `log.level: debug` if needed. Unknown keys are errors, not ignored compatibility settings.

### 3. Preserve custom behavior safely

- Remove duplicated stock instructions from the new **additive** prompt only after reviewing the user's custom content. Keep a backup of the old full replacement prompt for rollback/downgrade.
- Custom skills need matching folder/frontmatter names. Copy supporting scripts/references, not just `SKILL.md`. Never edit `builtin/`, which is replaced on app start.
- Remove obsolete duplicate flat skill files only after verifying the migrated version and obtaining approval for the deletion. Legacy files have lower priority but can still cause confusion.

### 4. Update clients and standalone launchers

- HTTP headers: use `ctrlx-host`, `ctrlx-username`, `ctrlx-password`, `ctrlx-token`, not uppercase underscore names. MCP server **environment variable names stay unchanged**.
- Rename standalone executable `ctrlx-mcp-server` → `ctrlx-mcp-os`.
- Remove agent `--env` / `-e`; `agent.env` and `CTRLX_AGENT_LLM_*` are no longer supported.
- Replace `CTRLX_AGENT_DATA_DIR` with `CTRLX_AGENT_CONFIG_DIR`, pointing to the YAML / approval-rule folder (standalone default `data`).
- Replace `CTRLX_AGENT_SYSTEM_PROMPT` with `CTRLX_AGENT_CONTEXT_DIR`, pointing to the **folder** containing `SystemPrompt.md` (default `.agents`).
- If previously supplied through `agent.env`, set `CTRLX_AGENT_MCP_TRANSPORT` and `CTRLX_AGENT_MCP_SERVER_URL` in the process environment. The ctrlX OS app sets these automatically.

### 5. Verify, then clean up

1. Inspect the logbook for configuration/include/secret/catalog errors, without exposing values.
2. Open a new conversation; confirm the intended provider/model with `/model` and that the limited-mode warning is gone.
3. Test a read-only local MCP operation, then an additional server using its own configured credentials. Confirm user file scopes when file access is needed.
4. Test custom skill discovery and prompt additions; verify no content was unintentionally overwritten.
5. Review migrated rules: **first match wins**, and a bare `*` now includes values containing `/`. Validate narrow HTTP read rules without performing unauthorized writes.
6. Confirm `safety` / `safety-plc` writes remain blocked from documentation/configuration; do not perform a real safety write as a test.
7. Read back changed non-secret files and report verified results, remaining risks and rollback locations. Keep backups private.

## Symptom-led diagnosis

| Symptom | Inspect / propose |
|---|---|
| AskRexroth warning, no history/tools/skills/attachments | Model configuration failed or is absent; inspect `loaded models.yaml` / errors, fix provider setup. Prompt changes cannot fix limited mode. |
| Saved changes appear ignored | Invalid YAML/catalog/include/secret; last valid config is retained. Check exact error, not repeated restarts. |
| Provider/model absent in `/model` | Indentation/spelling, `disabled`, discovery filters, rejected candidate, unresolved default/role. Inspect load diagnostics. |
| Discovery failed although manual models are listed | Manual overrides do not mask listing failures. Check actual provider listing endpoint, auth, deadline, complete pages and IDs; use manual mode if unsupported. |
| Discovery includes unexpected models | Explicit models add/override; they are not a filter. Set discovery include/exclude rules or disable discovery. |
| `context window unknown` | Supply the model's confirmed `context_window`; raising output tokens alone does not set it. |
| Secret undefined / file not found | Have the user add the named scalar beside the referencing file or correct the name; do not read excluded secrets. Includes have their own relative secret resolution. |
| `!include …: file not found` / include loop | Resolve relative to the containing file; fix the path/loop and check reload. |
| Additional MCP server still uses old config | Open a new conversation; validate server name and explicit hyphenated credential headers. The local token is not forwarded. |
| MCP auth fails behind reverse proxy | Check `ctrlx-*` hyphenated HTTP headers, client transport and scopes. Do not “fix” by weakening approvals. |
| Filesystem permission denied | Check allowed roots, exclusions and `rexroth-solutions.web.all.r` vs `.rw`; do not bypass protections with process execution. |
| Custom skill is missing or reverts on restart | Check `custom/<name>/SKILL.md`, matching name and resources; builtin is overwritten. Also rule out limited mode. |
| Prompt change not seen / request fails after prompt edit | Additive semantics, next-request reload, comment stripping/unclosed comment, wrong context folder or limited mode. Fix atomically and retry. |
| Large generated text ends with EOF / “content is missing” | Check active model `max_tokens`; propose `16384` or higher only if supported, including reasoning budget and cost. |
| HTTP call prompts even for GET | Expected destructive-tool classification. Use one-shot approval or an explicitly approved narrow method+relative-prefix rule. |
| Other device port returns unauthorized | HTTP tool injects token only for device HTTPS/WSS port 443; do not assume 8443 or plain HTTP gets credentials. |
| Cache writes but few reads | Check multi-backend routing. Use supported sticky routing or `extra_params.cache_control: null`; review rate-limit/cost trade-offs. |
| Red `!` persists after Read all | Read state is not approval state. Review the pending call; do not blanket-approve it. |

## Reporting a diagnosis

Include app/deployment version, the relevant sanitized configuration paths and exact non-secret error text, evidence source, smallest proposed fix, confirmation status, reload/new-conversation requirements, and observed verification. If the installed version differs from 0.5.0, explicitly label which manual facts still need checking.
