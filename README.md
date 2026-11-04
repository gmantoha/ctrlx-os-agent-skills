# ctrlX OS Agent Skills

Installable AI agent skills for everyone working with ctrlX OS and ctrlX CORE.

| Skill | Focus |
|---|---|
| `ctrlx` | General ctrlX OS/CORE operation, development, diagnostics and customer answers |
| [`ctrlx-ai`](skills/ctrlx-ai/SKILL.md) | ctrlX AI / Agent iXi configuration, models, MCP/security, custom prompts/skills and 0.3.0 → 0.5.0 migration |

Use it with prompts such as:

- `use ctrlx skill to debug this issue`
- `use ctrlx skill to configure my ctrlX CORE on <IP> so that the VPN routes through to the SPS`
- `use ctrlx skill to answer this customer question`
- `use ctrlx skill to build or package this ctrlX snap`
- `use ctrlx skill to create or apply a Device Portal template`

This repository is structured for three equal goals:

- build, deploy, and debug ctrlX apps
- configure and operate real or virtual ctrlX OS systems
- answer customer technical questions with evidence and examples

## Structure

- `SKILL.md`: root agent-skill manifest, routing table, and safety policy
- `skills/ctrlx-ai/`: self-contained additional skill with curated manual references, a sanitized model-config example and test prompts
- `workflows/`: workflow-oriented agent entry points
- `reference/`: common ctrlX platform knowledge, references, and best practices
- `reference/app-development/`: official-source-first guidance for ctrlX app builds, snap packaging, package assets, and Data Layer app integration
- `reference/apps/device-portal/`: API-only Device Portal template integration and PLC artifact verification
- `recipes/`: concrete task playbooks such as VPN routing, firewall, storage, PLC, and Data Layer patterns
- `templates/`: reusable answer, investigation, and demo templates
- `labs/`: virtual ctrlX operating environment guidance and helper scripts
- `cases/`: reusable sanitized investigations and solved examples
- `customers/`: local employee-specific workspaces, excluded from git

## What Is Tracked

- product PDFs
- workflow guidance
- examples and templates
- documented public defaults only when they are intentionally required for a lab
- scripts for repeatable local setup

## What Is Not Tracked

- customer-specific secrets and service-account credentials
- downloaded app packages
- virtual machine images
- local logs, exports, caches, and scratch data

## Recommended Usage

1. Start with `SKILL.md`.
2. Read `reference/AGENTS.md` for platform-wide rules.
3. Enter the relevant workflow in `workflows/`.
4. Use a concrete playbook from `recipes/` when available.
5. Use `labs/ctrlx-os-virtual/` when testing against a local virtual ctrlX OS.
6. Store private customer work only in `customers/`.

For Device Portal template or serial-commissioning work, start with
`workflows/device-portal-templates.md`. It distinguishes complete-device
templates from true modular deployment and requires target-side verification.
Concrete request sequences and the recovery procedure are in `recipes/device-portal/`.

## Install

This repository is compatible with the open agent skills CLI used by Vercel.

Install directly from GitHub:

```bash
npx skills add gmantoha/ctrlx-os-agent-skills \
  --skill ctrlx \
  --agent opencode \
  --global \
  --copy \
  --yes
```

Use `--copy` instead of a symlink so the agent can read bundled skill files without resolving paths outside the installed skill directory.

Install the additional `ctrlx-ai` skill (the root manifest otherwise limits nested discovery):

```bash
npx skills add gmantoha/ctrlx-os-agent-skills \
  --full-depth --skill ctrlx-ai --agent opencode --global --copy --yes
```

For a local-only install from this checkout, use
`npx skills add ./skills/ctrlx-ai --agent opencode --global --copy --yes`.
These commands install a workstation-agent skill, not an app or skill on a ctrlX device.

For local development, work in this Git repository and install the current checkout:

```bash
npm run skill:install
```

Update from Git and reinstall the copied skill:

```bash
npm run skill:update
```

Set `CTRLX_SKILL_AGENT` to install for another supported agent, for example:

```bash
CTRLX_SKILL_AGENT=claude-code npm run skill:install
```

See `INSTALL.md` for details and verification steps.
