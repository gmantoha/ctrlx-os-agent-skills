# ctrlX AI / Agent iXi troubleshooting

Scope: supplied User Manual, **Changelog 0.5.0**, **Migration Guide: 0.3.0 to 0.5.0**, model troubleshooting and **Large text file generation fails**. See [sources](sources.md).

For upgrade work, follow [the migration recipe](../../../recipes/ctrlx-ai/migrate-0.3-to-0.5.md); configuration is not automatically converted. Use [the configuration workflow](../../../workflows/configure-ctrlx-ai.md) to inspect, propose, confirm and verify changes.

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
