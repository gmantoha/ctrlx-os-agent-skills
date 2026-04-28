# Install

This repository is an installable agent skill named `ctrlx`.

## OpenCode

Install with a symlink so repository edits are immediately visible to the agent:

```bash
ln -s /home/bea1fc/projects/ctrlx-os-agent-skills ~/.agents/skills/ctrlx
```

Verify:

```bash
test -f ~/.agents/skills/ctrlx/SKILL.md
```

## Claude Code

Optionally install the same skill for Claude Code:

```bash
ln -s /home/bea1fc/projects/ctrlx-os-agent-skills ~/.claude/skills/ctrlx
```

Verify:

```bash
test -f ~/.claude/skills/ctrlx/SKILL.md
```

## Expected Usage

After installation, prompts can be phrased naturally:

- `use ctrlx skill to debug this issue`
- `use ctrlx skill to configure my ctrlX CORE on <IP> so that the VPN routes through to the SPS`
- `use ctrlx skill to create a customer answer about Data Layer vs REST`

## Notes

- Do not copy this repository into the skill directory during active development; use symlinks to avoid stale installed copies.
- Real-device persistent changes still require explicit confirmation according to `SKILL.md`.
