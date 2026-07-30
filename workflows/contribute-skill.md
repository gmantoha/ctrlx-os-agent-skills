# Contribute to This Skill (Pull / Teach / Push)

Use this workflow when the task is about the skill repository itself — installing it,
capturing something newly learned, or sharing an improvement back with the team —
rather than a ctrlX OS task.

This keeps the skill a single shared source of truth: everyone installs the same
repository, and improvements flow back into it instead of living only on one person's
machine.

## Pull — install or update the skill locally

One-time install:

```bash
npx skills add gmantoha/ctrlx-os-agent-skills --skill ctrlx --agent opencode --global --copy --yes
```

Get the latest merged changes:

```bash
npx skills update ctrlx --global --yes
```

## Teach — capture something newly learned

Triggered automatically whenever the agent (or user) discovers something during a task
that isn't yet covered by `recipes/`, `cases/`, or `reference/` — a fix, a workaround, a
gotcha, a correct API payload, etc. Ask the user whether it's worth saving before moving
on. If yes, draft it as a short recipe/case file and hand off to **Push** below.

## Push — contribute the learning back to the shared repo

Say **"push this skill: <what you learned>"**. The agent runs the full sequence so no
manual git commands are needed:

1. Clone or pull the latest `main` of `gmantoha/ctrlx-os-agent-skills`
2. Create a branch: `git checkout -b <short-topic-name>`
3. Add/update a file under `recipes/`, `cases/`, or `reference/` describing the learning
4. `git add` + `git commit` with a descriptive message
5. `git push origin <branch>`
6. `gh pr create --fill` to open a Pull Request for review

Requires `gh auth login` once per machine (GitHub CLI authentication) before the push
step can open a PR.

After the PR is merged, run **Pull** again (`npx skills update ctrlx --global --yes`) to
receive the change locally — pushing to the repo does not update your local copy
automatically.
