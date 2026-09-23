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

- `main` of `gmantoha/ctrlx-os-agent-skills` is protected by the repository ruleset
  **"Protect main"**: no direct pushes, no force-push, no deletion. Every change goes through
  a Pull Request with 1 approving review and all review conversations resolved. Repository
  admins may bypass only when merging a PR (`--admin`), never for direct or force pushes.
- Only the maintainer (`gmantoha`) reviews and merges. Contributors never merge their own PRs.
- Pushing a branch **into this repository** requires write access (collaborator). GitHub has no
  setting that lets everyone push branches. Everyone else contributes through a **fork**;
  the resulting Pull Request looks the same to the reviewer.

### Sequence

1. Clone or pull the latest `main`:
   `git clone https://github.com/gmantoha/ctrlx-os-agent-skills.git` or `git checkout main && git pull`
2. Create a branch from `main`: `git checkout -b <short-topic-name>`
3. Add/update a file under `recipes/`, `cases/`, or `reference/` describing the learning.
   Anonymize before committing — see [Anonymization checklist](#anonymization-checklist).
4. `git add` + `git commit` with a descriptive message (no customer names in the message
   or the branch name either)
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

### Anonymization checklist

This repository is shared. Customer data must never reach it — not in the current files
and not in the git history. Check **everything** that gets committed:

- **Where:** file contents *and* file/directory names, raw logs and exports (`raw/`),
  HTML/e-mail drafts, generated scripts, commit messages, branch names, PR titles/bodies.
- **What:** company and customer names — including inside snap names, service names,
  paths, MQTT topics, API routes, Python package names (e.g. `ctrlx-<customer>-<app>`,
  `/snap/<customer>-...`) — person names and department codes, e-mail addresses,
  hostnames, serial numbers, asset/device IDs, customer IPs, credentials, tokens, keys.
- **How:** replace consistently with a neutral, greppable placeholder that does not
  collide with existing words (e.g. `vendorx`, `VendorX`, `ACME-DE-001`, `[anonymisiert]`);
  keep case variants consistent so logs stay readable.
- **Check before committing** (replace `<name>` with each customer term):

  ```bash
  git grep -n -i "<name>"                  # file contents
  git ls-files | grep -i "<name>"           # file and directory names
  git diff --cached | grep -i "<name>"      # what is about to be committed
  ```

Customer workspaces belong in `customers/` (git-ignored), never in `cases/`.

#### If customer data was already pushed

A follow-up commit does **not** remove it — it stays in the history and on GitHub.
Tell the maintainer; do not try to fix it yourself. Only the maintainer rewrites history:

1. Fresh clone of all branches, then `git filter-repo --replace-text <rules>
   --replace-message <rules> --filename-callback ...` (rules file: `name==>placeholder`
   per line, one line per case variant).
2. Verify: `git log --all -p | grep -i -c "<name>"` returns `0`, and the new `main` tree equals
   the old tree with the replacement applied.
3. Temporarily disable the ruleset "Protect main" (set to *Disabled*, do not delete it),
   push with `git push --force-with-lease=<branch>:<old-sha> ...`, re-enable the ruleset.
4. Everyone re-clones or runs `git fetch && git reset --hard origin/main`; old local
   objects: `git reflog expire --expire=now --all && git gc --prune=now`.
5. Old PR diffs (`refs/pull/*`) still show the data — only GitHub Support can purge them.

Requires `gh auth login` once per machine (GitHub CLI authentication) before the push
step can open a PR.

Push is not considered complete until the merged change has also been pulled locally.
Merging the PR on GitHub does not, by itself, update anyone's local copy — Pull must run
after every merge, whether triggered by this same Push request or done later by other
team members on their own machines.
