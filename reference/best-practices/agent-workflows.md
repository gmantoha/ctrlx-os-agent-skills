# Agent Workflows

Agents should work in this order:

1. identify the workflow in `workflows/`
2. read the matching `AGENTS.md`
3. pull shared platform context from `reference/`
4. verify on a lab or device if needed
5. produce commands, code, evidence, and a concise conclusion

## MCP-First Rule (when device is involved)

**Before using curl/PowerShell/REST for any device interaction:**

1. Call `tool_search_tool_regex` with pattern `datalayer|ctrlx|oscilloscope|motion|logbook` to discover available MCP tools.
2. If `ctrlx-datalayer_read`, `ctrlx-datalayer_write` etc. are available → use them directly. Never fall back to curl when MCP tools are loaded.
3. Only use `powershell` + curl if MCP tools are NOT available.

**Why this matters:**
- MCP tools save ~50% tokens vs. curl (no session handling, no JSON escaping, no SSE parsing)
- curl-based MCP calls are error-prone (wrong paths, async issues, missed session IDs)
- The `tool_search_tool_regex` call costs ~10 tokens — skipping it and using curl costs ~500+

## Efficiency Rules

- **Browse before writing**: use `ctrlx-datalayer_browse` to verify exact node paths before creating channels/configs. Never guess paths from documentation alone — ctrlX versions differ (e.g. `actual/vel` not `actual/actualVel`).
- **Parallel tool calls**: issue independent reads/browses in one response, not sequentially.
- **Check existing state first**: before creating an oscilloscope instance or motion config, browse `oscilloscope/instances` or `motion/axs` to see what already exists.
