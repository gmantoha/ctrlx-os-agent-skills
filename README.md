# ctrlX OS Agent Skills

AI-ready workspace for Bosch Rexroth employees working with ctrlX OS.

This repository is structured for three equal goals:

- build, deploy, and debug ctrlX apps
- configure and operate real or virtual ctrlX OS systems
- answer customer technical questions with evidence and examples

## Structure

- `skills/`: workflow-oriented agent entry points
- `shared/`: common ctrlX platform knowledge used by all skills
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

1. Start with the root `AGENTS.md`.
2. Read `shared/AGENTS.md` for platform-wide rules.
3. Enter the relevant workflow in `skills/`.
4. Use `labs/ctrlx-os-virtual/` when testing against a local virtual ctrlX OS.
5. Store private customer work only in `customers/`.
