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

### If `npx skills update` fails

On some networks (corporate proxy, GitHub API rate-limiting, broken custom CA certs via
`NODE_EXTRA_CA_CERTS`) this command fails with an error like `Failed to fetch tree for
<repo>` even though the update actually exists on `main`. Do not assume the update
doesn't exist — verify and fall back to a manual copy:

1. Confirm the change is really merged: check `main` on GitHub directly.
2. Clone (or `git pull` an existing local clone of) `gmantoha/ctrlx-os-agent-skills`.
3. Copy the changed file(s) directly into the installed skill folder, e.g.
   `~/.agents/skills/ctrlx/workflows/<file>.md` and `~/.agents/skills/ctrlx/SKILL.md`.
4. Confirm with `Test-Path`/`ls` that the file now exists locally.

This reaches the same end state as `npx skills update` and should be used whenever that
command reports a fetch failure instead of assuming Pull is impossible.

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
7. If the user has merge rights and asks to merge now, merge the PR
   (`gh pr merge <branch> --merge --delete-branch`)
8. **Immediately run Pull** (see above, including its fallback if `npx skills update`
   fails) so the change lands locally too — do this automatically as the last step of
   Push, without waiting to be asked separately

Requires `gh auth login` once per machine (GitHub CLI authentication) before the push
step can open a PR.

Push is not considered complete until the merged change has also been pulled locally.
Merging the PR on GitHub does not, by itself, update anyone's local copy — Pull must run
after every merge, whether triggered by this same Push request or done later by other
team members on their own machines.
