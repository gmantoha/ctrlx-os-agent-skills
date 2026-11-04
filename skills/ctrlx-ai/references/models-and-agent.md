# Models and agent settings

Scope: supplied User Manual, **AI Agent Configuration → LLM Provider & Model Setup**, **Agent Settings**, and **Bosch Employees Only**. See [sources](sources.md). Examples are illustrative, not claims about available models or current provider limits/prices.

## Files and reload behavior

- Use `agent/models.yaml` for providers/models, `agent/secrets.yaml` for secret values and `agent/agent.yaml` for agent settings.
- `models.yaml` reloads a few seconds after saving, including changes to its includes and referenced secrets. A malformed candidate logs an error and leaves the last valid configuration active.
- `agent.yaml` also applies without restarting. Unknown keys and invalid values are errors; retain the last valid settings, or defaults at startup.
- With no valid initial model configuration, the agent falls back to AskRexroth limited mode. Do not mistake that fallback for a working full-featured provider setup.

## Minimal model configuration

Start from [the bundled example](../assets/models.yaml.example), replace the illustrative URL/model ID/limits with confirmed values, and have the user provision `llm_api_key` in `agent/secrets.yaml`. Do not read or print that secret file.

```yaml
version: 1
default_model: proxy/my-chat-model
roles:
  fast: proxy/my-chat-model
providers:
  proxy:
    type: openai
    base_url: https://llm.example.com/v1
    api_key: !secret llm_api_key
    models:
      my-chat-model:
        context_window: 32768  # example only; use the actual model limit
        max_tokens: 4096
```

### Schema essentials

| Field | Meaning / default |
|---|---|
| `version` | Required; `1` |
| `default_model` | Recommended; `provider/model` or a role name; discovery does not select it |
| `roles` | Optional user-defined aliases; role-selected conversations follow changes to the role |
| `providers` | Required provider mapping |
| Provider `type` | Required: `openai` (including compatible servers) or `anthropic` |
| Provider `base_url` | Shared API URL; may be omitted only if each manual model has its own URL |
| Provider `api_key` | Required; prefer `!secret`; unauthenticated local servers may use `"none"` |
| `api_version` | Optional `api-version` query parameter for Azure |
| `compat` | `vertex-rawpredict` for an Anthropic Vertex `rawPredict` proxy |
| `headers`, `query_params` | Additional per-request headers/query values |
| `timeout_secs` | Default `90` |
| `insecure_skip_verify` | Default `false`; testing only, not a general TLS-error remedy |
| `disabled` | Default `false`; hides the provider and all its models |
| `auto_discover` | Default `false`; boolean or filter mapping (below) |
| `models` | Required unless discovery enabled; model IDs are sent to the API |
| Provider/model `extra_params` | Additional request fields; model keys override provider keys |
| Model `base_url` | Overrides provider URL, e.g. one Azure deployment URL per model |
| Model `context_window` | Input window; use a documented value or supported server discovery |
| Model `max_tokens` | Positive integer output budget, including reasoning/thinking |
| Model `pricing` | Optional cost estimates; never invent prices |

### Endpoint selection

- **OpenAI-compatible / LiteLLM / local servers:** URL before `/chat/completions`, e.g. `http://127.0.0.1:4000/v1` for a proxy actually reachable there. On a device, loopback means that device, not the user's workstation.
- **Anthropic native:** server root, e.g. `https://api.anthropic.com`; trailing `/v1` also accepted.
- **Anthropic via Vertex proxy:** URL ending in `/publishers/anthropic/models`, with `compat: vertex-rawpredict`. The model key is appended automatically; do not duplicate the model suffix in the base URL.
- **Azure deployment:** per-model `base_url` plus the provider's `api_version` when needed. Do not guess a management endpoint.
- If a proxy expects a different wire model name, set `extra_params.model` explicitly.

## Model autodiscovery

`auto_discover: true` opts in per provider. OpenAI-compatible discovery uses `GET /models` relative to the provider base URL; native Anthropic uses paginated `GET /v1/models`. Discovery requires an absolute HTTP(S) **provider-level** base URL and uses inference credentials, headers, query parameters, API version and TLS settings.

Important semantics:

1. Manual `models` entries override discovered metadata and add models missing from the advertised list. They do **not** disable discovery or restrict it to those entries. `models` may be missing, null or empty with discovery enabled.
2. Omitted/null `context_window` preserves discovered metadata; explicit `0` uses the agent's automatic context-window behavior. Unknown limits/prices are not invented. An advertised model may still lack chat or tool support.
3. Discovery runs at startup and when model configuration, includes or referenced secrets change. It is not periodic and is not triggered by selecting a model. Results stay in memory; files are not rewritten.
4. Each listing has a **five-second total deadline**, shortened by a smaller positive `timeout_secs`. No retries or redirects. Authentication failures, unsupported endpoints, incomplete/empty usable lists and unresolved defaults/roles reject the whole candidate catalog. Manual entries do not hide a discovery failure.
5. On reload, rejection preserves the previous catalog. Initial failure uses AskRexroth fallback.
6. Vertex `rawPredict` and deployment-only Azure endpoints require `auto_discover: false` and manual models. Do not probe inference endpoints to guess a catalog.
7. Valid advertised IDs contain only letters, digits, `.`, `_`, `@`, `:`, or `-`; invalid IDs are excluded with a diagnostic, not renamed.

### Discovery filters

```yaml
auto_discover:
  enabled: true
  include_models:
    - "chat-*"
  exclude_models:
    - "*-legacy"
```

- Case-sensitive globs match the **entire model ID**, not `provider/model`. `*` matches any sequence, `?` one character; exact IDs work too.
- Missing/empty includes retain all discovered IDs; otherwise one inclusion must match. Exclusions then win. Empty patterns or invalid glob syntax are errors before listing.
- Filters affect only discovered entries. Explicit `models` entries are merged afterward and remain available even if filtered out.
- Empty results with no manual model, or a now-unresolved default/role, reject the candidate.
- Mapping-form `enabled` defaults to `false`; set it explicitly. With discovery disabled, valid filters do not affect manual entries.
- For a strictly enumerated catalog, disable discovery and list the allowed models manually.

## Secrets and shared YAML

Use `!secret <name>` for individual scalar values; it works in `models.yaml`, `mcp.yaml` and `agent.yaml`, including URL/header/query/extra-parameter and numeric values. Scalars keep their type (`300` differs from `"300"`); nested objects and lists are not secret values. `secrets.yaml` is optional only when nothing references it.

Have the user populate secrets through a trusted editor/channel. The application provisions `agent/.gitignore` and `.aiexclude`; the latter excludes `secrets.yaml` and itself from AI file access. Preserve both, including when copying configuration. Do not bypass exclusions to diagnose a missing key: the log reports the secret **name and line**, not its value.

`!include <path>` replaces a value with another YAML file's contents. Resolve the path relative to the file containing the include, not the process directory. `<<:` merges a mapping or list of mappings: explicit local entries win; earlier merge sources win over later ones. A `!secret` in an included file resolves against the `secrets.yaml` **beside that included file**.

Shared secret configuration may use `<<: !include ../secrets.yaml` in `agent/secrets.yaml`; preserve access protections for the shared location too. Missing includes, loops and missing secret names are logged; changes to included files are detected automatically. YAML does **not** expand `${VAR}` environment references.

## Output budget, context and request parameters

- Model `max_tokens` is sent as `max_completion_tokens` to OpenAI-compatible APIs and `max_tokens` to Anthropic. If omitted, OpenAI receives no limit and Anthropic uses `4096`.
- For legacy OpenAI-compatible servers that require exactly `max_tokens`, put it in `extra_params.max_tokens` instead. Do not set both `extra_params.max_tokens` and `extra_params.max_completion_tokens`.
- `context_window` controls input shortening, not output length. If omitted, the agent asks the server once after startup/reload. OpenAI and many proxies do not report it; supply a confirmed value. Unknown window sizes produce a warning and send conversations without shortening.
- `extra_params` overrides generated request fields. Nested objects such as `thinking` are replaced as a whole, not deep-merged. Do not set temperature unless the chosen model supports it; it is unset by default.
- OpenAI reasoning effort can be supplied as `extra_params.reasoning_effort` if supported by that model.
- For supported Anthropic budget-based thinking, keep `thinking.budget_tokens < max_tokens`; for models supporting adaptive thinking use their documented `thinking`/`output_config` fields. Confirm model-specific support rather than inferring it from a name. Do not set temperature with thinking enabled.
- “content is missing” / EOF while generating large files can indicate exhausted output budget. Consider `max_tokens: 16384` or higher **only if supported**; account for reasoning tokens and increased cost.

## Caching and prices

Anthropic prompt caching is enabled by default for tools, system prompt and conversation. Disable with:

```yaml
extra_params:
  cache_control: null
```

Multi-backend proxies without a shared cache may incur cache writes with few cache reads. Use supported sticky routing or disable caching. The manual's Bosch AI Farm note documents Anthropic-only `x-bmf-sticky-session-instance: "01"` or `"02"`; quoted values matter, other values are ignored, and pinning increases HTTP 429 risk. Confirm current internal guidance before relying on this. Do not publish internal endpoint URLs or credentials; obtain approved endpoints from the user.

`pricing` requires `input` and `output`, per million tokens. Optional `cache_read`/`cache_write` default to input price; `currency` defaults to `USD`. Provider token counts drive estimates, not billing guarantees. If some session requests lack pricing, displayed session cost is a lower bound (`≥`). Use current authorized provider price data, not example prices from a manual.

## Agent settings and model selection

```yaml
approvals:
  skip: false
log:
  level: info
```

Every `agent.yaml` key is optional. `log.level` accepts `debug`, `info`, `warn`, `error`; `approvals.skip` defaults to `false` and bypassing prompts is dangerous. `agent.env` is no longer read in 0.5.0.

Use `/model` to list models and `/model <provider/model-or-role>` to switch; a switch takes effect with the next message. The header picker is hidden with a single configured model. Role-selected conversations follow role changes; removing the selected model falls back to `default_model`. Inspect the logbook's `loaded models.yaml` entry and resolve catalog errors before treating the model picker as authoritative evidence of a newly saved configuration.
