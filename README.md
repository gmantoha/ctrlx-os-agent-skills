# ctrlX OS Agent Skill

Installable AI agent skill for Bosch Rexroth employees working with ctrlX OS and ctrlX CORE.

Use it with prompts such as:

- `use ctrlx skill to debug this issue`
- `use ctrlx skill to configure my ctrlX CORE on <IP> so that the VPN routes through to the SPS`
- `use ctrlx skill to answer this customer question`
- `use ctrlx skill to build or package this ctrlX snap`

This repository is structured for three equal goals:

- build, deploy, and debug ctrlX apps
- configure and operate real or virtual ctrlX OS systems
- answer customer technical questions with evidence and examples

## Structure

- `SKILL.md`: root agent-skill manifest, routing table, and safety policy
- `workflows/`: workflow-oriented agent entry points
- `reference/`: common ctrlX platform knowledge, references, and best practices
- `reference/app-development/`: official-source-first guidance for ctrlX app builds, snap packaging, package assets, and Data Layer app integration
- `recipes/`: concrete task playbooks such as VPN routing, firewall, storage, PLC, and Data Layer patterns
- `templates/`: reusable answer, investigation, and demo templates
- `labs/`: virtual ctrlX operating environment guidance and helper scripts
- `cases/`: reusable sanitized investigations and solved examples
- `customers/`: local employee-specific workspaces, excluded from git

## What Is Tracked

- product PDFs
- workflow guidance
- examples and templates
- default credentials when they are public defaults
- scripts for repeatable local setup

## What Is Not Tracked

- customer-specific secrets
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

## Install Locally

For live development, install by symlinking this repository as the `ctrlx` skill:

```bash
ln -s /home/bea1fc/projects/ctrlx-os-agent-skills ~/.agents/skills/ctrlx
```

For Claude Code as well:

```bash
ln -s /home/bea1fc/projects/ctrlx-os-agent-skills ~/.claude/skills/ctrlx
```

See `INSTALL.md` for details and verification steps.
