# ctrlX OS Agent Repository

## Purpose

This repository is a workflow-oriented ctrlX OS workspace for Bosch Rexroth employees using coding agents such as OpenCode or Claude Code.

Use it for:

- building ctrlX apps and iterating on them
- configuring and operating ctrlX OS devices
- debugging issues on real or virtual systems
- answering customer technical questions with verified evidence

## Folder Intent

- `skills/`: agent workflows such as build, configure, debug, and answer
- `shared/`: common ctrlX knowledge, references, and best practices
- `labs/`: local virtual ctrlX usage guides and helper scripts
- `cases/`: sanitized reusable investigations and solved examples
- `customers/`: private local workspaces excluded from git

## Global Rules

1. Read `shared/AGENTS.md` before making technical assumptions.
2. Prefer the workflow under `skills/` that matches the task.
3. Treat real-device changes as sensitive.
4. Ask for confirmation before persistent changes on a real device.
5. Never store customer-specific secrets in tracked files.
6. Default public credentials may be documented when intentionally required for labs or defaults.

## Safe vs Confirmed Actions

Safe without confirmation:

- reading docs and local files
- analyzing logs and cases
- drafting code, examples, and customer answers
- preparing commands for SSH, REST, WebDAV, or UI automation

Require confirmation on a real device:

- installing, removing, or updating apps
- changing network, firewall, certificates, users, or storage settings
- restarting services that may affect running systems
- rebooting the device
- writing configuration through Web UI, REST, WebDAV, or SSH

## Operating Principle

Prefer evidence over assumptions:

- docs and PDFs first
- existing reusable cases second
- direct verification on a virtual or real ctrlX system third

When possible, provide example code, commands, or reproducible steps.
