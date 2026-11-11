# Source provenance and limits

## Imported source

- **Title:** ctrlX AI - Automation Intelligence — User Manual
- **Provided file:** `User-Manual 2.html`
- **Version evidence:** changelog heading `0.5.0`, “Changes since 0.3.0”, and “Migration Guide: 0.3.0 to 0.5.0”. No separate build/release date was established.
- **Imported:** 2026-11-04
- **SHA-256 of the supplied HTML:** `395bc0ec30301b8b19ce9c14830727da5a11ca6f00572d6be7df9f83d2cd79ab`
- **Attribution:** source footer, Copyright © 2026 Bosch Rexroth AG | ctrlX AUTOMATION.

These are curated operational notes from the user-provided manual, not a verbatim copy or independently verified implementation specification. The source HTML is not required at runtime and was not copied into the repository. No device was contacted during extraction.

## Repository map

| Repository file | Source sections |
|---|---|
| `workflows/configure-ctrlx-ai.md`, `reference/apps/ctrlx-ai/README.md` | Overview; Installation; MCP Server; AI Agent; safety and migration notes |
| `models-and-agent.md` | AI Agent Configuration → LLM Provider & Model Setup, Agent Settings; Selecting a Model; Bosch Employees Only → provider/caching concepts |
| `mcp-and-security.md` | MCP Server → Tools, Configuration, Usage; Additional MCP Servers; Tool Approvals; Changelog 0.5.0 |
| `prompts-and-usage.md` | AI Agent Usage; Header Widget; Context usage |
| `troubleshooting.md` | Changelog; model troubleshooting; Large text file generation fails |
| `recipes/ctrlx-ai/migrate-0.3-to-0.5.md` | Migration Guide: 0.3.0 to 0.5.0; Changelog |
| `templates/ctrlx-ai/models.yaml.example` | LLM Provider & Model Setup; sanitized illustrative model/URL |

Workflow, recipe and template paths above are relative to the repository root; reference filenames are relative to this directory. These files are all included in the existing `ctrlx` skill installation.

## Deliberate limits

- Omit private device addresses, employee-specific paths, credentials and internal endpoint/documentation URLs. Generic examples use reserved `example.com` names. The Bosch AI Farm notes retain configuration concepts, not private deployment details.
- Treat named model versions, limits, reasoning modes and prices in the manual as examples, not current provider guarantees. Verify against the selected provider before recommending values.
- The manual includes an older-looking VS Code `sse` example alongside newer Streamable HTTP support in the changelog. This skill deliberately does not assert a universal client configuration or protocol version.
- The manual's stated safety-related legal rationale is not a compliance assessment. Preserve the technical block without promising regulatory compliance.
- Runtime tool catalogs, installed-version documentation and shipped schemas/templates can refine version-specific details. Do not silently overwrite observed facts with these notes or bypass a safety restriction to test it.
- Confirmation, least-privilege and secret-protection instructions in this skill additionally reflect this repository's safety policy. They intentionally remain stricter than an application's optional approval bypass.
