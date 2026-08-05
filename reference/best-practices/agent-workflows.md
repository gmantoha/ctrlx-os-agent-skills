# Agent Workflows

## Standard Order

1. Pick workflow from `workflows/` matching the task
2. Read `reference/AGENTS.md` for platform rules
3. Use recipe from `recipes/` when available
4. Verify on device if needed
5. Produce commands, code, evidence, conclusion

## MCP-First Rule

**Before any device interaction — check for MCP tools first:**

```
tool_search_tool_regex("datalayer|ctrlx")
```

- Tools found → **use `ctrlx-datalayer_*` directly** — no curl, no REST
- Not found → fall back to REST/SSH/curl
- Cost: ~10 tokens to check. Skipping and using curl costs ~500+ tokens.

See `workflows/use-mcp.md` and `reference/apps/mcp-server/README.md` for setup.

## Efficiency Rules

| Rule | Why |
|---|---|
| Browse before write/create | Paths vary between ctrlX versions — never guess |
| Parallel tool calls | Issue independent reads in one response |
| Check existing state first | Avoid creating duplicates (instances, axes, channels) |
| `actual/vel` not `actual/actualVel` | Verified path on ctrlX OS 4.6 |
