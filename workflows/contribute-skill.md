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
manual git commands are needed.

### Repository rules

- `main` of `gmantoha/ctrlx-os-agent-skills` is protected: no direct pushes, no force-push,
  no deletion. Every change goes through a Pull Request with 1 approving review and all
  review conversations resolved.
- Only the maintainer (`gmantoha`) reviews and merges. Contributors never merge their own PRs.
- Pushing a branch **into this repository** requires write access (collaborator). GitHub has no
  setting that lets everyone push branches. Everyone else contributes through a **fork**;
  the resulting Pull Request looks the same to the reviewer.

### Sequence

1. Clone or pull the latest `main`:
   `git clone https://github.com/gmantoha/ctrlx-os-agent-skills.git` or `git checkout main && git pull`
2. Create a branch from `main`: `git checkout -b <short-topic-name>`
3. Add/update a file under `recipes/`, `cases/`, or `reference/` describing the learning.
   Remove customer names, credentials, keys, IDs and customer IPs before committing.
4. `git add` + `git commit` with a descriptive message
5. Check whether you can push to the repository:

   ```bash
   gh api repos/gmantoha/ctrlx-os-agent-skills --jq .permissions.push
   ```

   - `true` (collaborator) → push the branch into the repository and open the PR:

     ```bash
     git push -u origin <branch>
     gh pr create --base main --fill
     ```

   - `false` (everyone else) → push to your fork and open the PR against the original repository.
     `gh` creates the fork if it does not exist yet (non-interactive, suitable for agents):

     ```bash
     gh repo fork gmantoha/ctrlx-os-agent-skills --remote --remote-name fork
     git push -u fork <branch>
     gh pr create --repo gmantoha/ctrlx-os-agent-skills --base main \
       --head <your-github-user>:<branch> --fill
     ```

     Interactively, a plain `gh pr create` also offers to create the fork.
     Do not try `git push origin` without write access — it fails with HTTP 403.
6. Report the PR link to the user. The PR now waits for the maintainer's review.
   Address review comments with new commits on the same branch (`git push`); a new commit
   dismisses an existing approval, so the maintainer re-approves.
7. Merge (maintainer only):
   - PR from someone else, after approval: `gh pr merge <number> --merge --delete-branch`
   - Maintainer's own PR (GitHub does not allow approving your own PR; admins may bypass):
     `gh pr merge <number> --merge --delete-branch --admin`
   Never merge on behalf of the maintainer unless they explicitly ask for it in this session.
8. **After the merge, run Pull** (see above, including its fallback if `npx skills update`
   fails) so the change lands locally too. If the PR is still waiting for review, tell the user
   that Pull has to run after the merge.

Requires `gh auth login` once per machine (GitHub CLI authentication) before the push
step can open a PR.

Push is not considered complete until the merged change has also been pulled locally.
Merging the PR on GitHub does not, by itself, update anyone's local copy — Pull must run
after every merge, whether triggered by this same Push request or done later by other
team members on their own machines.
