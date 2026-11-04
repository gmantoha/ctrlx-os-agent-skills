# Install

This repository contains the root skill `ctrlx` and the self-contained additional
skill `ctrlx-ai` under `skills/ctrlx-ai/`.

## Recommended: Skills CLI

Install from GitHub with the same CLI pattern used by Vercel's skills ecosystem:

```bash
npx skills add gmantoha/ctrlx-os-agent-skills \
  --skill ctrlx \
  --agent opencode \
  --global \
  --copy \
  --yes
```

The important flag is `--copy`. Do not install this skill as a symlink when the agent enforces workspace or skill-directory read permissions, because symlink targets can resolve outside the installed skill folder.

List skills available in this repository:

```bash
npx skills add gmantoha/ctrlx-os-agent-skills --full-depth --list
```

`--full-depth` is needed to discover nested skills while a root `SKILL.md` exists.
Install just the ctrlX AI / Agent iXi skill:

```bash
npx skills add gmantoha/ctrlx-os-agent-skills \
  --full-depth --skill ctrlx-ai --agent opencode --global --copy --yes
```

From a local checkout, the equivalent is:

```bash
npx skills add ./skills/ctrlx-ai --agent opencode --global --copy --yes
```

`ctrlx-ai` bundles its own references/example and does not require the separate
`ctrlx` installation. The root `ctrlx` skill also routes to the new material.
`npm run skill:install` / `skill:update` continue to target `ctrlx` only.
Neither installation method deploys anything to a ctrlX device.

Update an installed skill:

```bash
npx skills update ctrlx --global --yes
```

## Local Development

Develop in a normal Git checkout:

```bash
git clone https://github.com/gmantoha/ctrlx-os-agent-skills.git
cd ctrlx-os-agent-skills
```

Install the current checkout as a copied skill:

```bash
npm run skill:install
```

Pull the latest Git changes and reinstall:

```bash
npm run skill:update
```

Install for a different supported agent:

```bash
CTRLX_SKILL_AGENT=claude-code npm run skill:install
```

Install into the current project instead of the global skill location:

```bash
CTRLX_SKILL_SCOPE=project npm run skill:install
```

## Expected Usage

After installation, prompts can be phrased naturally:

- `use ctrlx skill to debug this issue`
- `use ctrlx skill to configure my ctrlX CORE on <IP> so that the VPN routes through to the SPS`
- `use ctrlx skill to create a customer answer about Data Layer vs REST`
- `use ctrlx-ai to migrate Agent iXi from 0.3.0 to 0.5.0`
- `use ctrlx-ai to configure LiteLLM model discovery and diagnose limited mode`

## Notes

- Keep Git development in the repository checkout, not in the installed skill directory.
- Re-run `npm run skill:install` after local edits, or `npm run skill:update` to pull and reinstall.
- Use copy mode, not symlinks, to avoid permission prompts caused by symlink targets outside the installed skill directory.
- Real-device persistent changes still require explicit confirmation according to `SKILL.md`.
