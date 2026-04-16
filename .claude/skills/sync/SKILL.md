---
name: sync
description: Pull latest skills, hooks, agents, and config from the coding-agent-workflow template repo.
disable-model-invocation: false
---

# /sync — Sync Workflow Updates from Template Repo

Pull the latest skills, hooks, agents, and config from the `coding-agent-workflow` template repo into the current project.

## Layered Configuration Model

Claude Code config is split across layers so `/sync` can overwrite the template-managed layer safely without touching project-specific content:

| File | Scope | Committed? | Touched by /sync? |
|---|---|---|---|
| `CLAUDE.md` | Template rules only (imports the layers below) | Yes | **Yes — overwritten wholesale** |
| `.claude/project.md` | Team-shared, project-specific rules + Deployment Targets | Yes | **Never** |
| `CLAUDE.local.md` | Personal per-project overrides | No (gitignored) | **Never** |
| `~/.claude/CLAUDE.md` | Cross-project personal | N/A (global) | **Never** |

`CLAUDE.md` uses Claude Code's native `@.claude/project.md` and `@CLAUDE.local.md` import syntax to inline the lower layers into the session's system prompt, so rules added to any layer still take effect. The split exists purely to make `/sync` safe — nothing about how Claude reads rules changes.

## Source Repo

- **GitHub**: `Joaovsales/coding-agent-workflow`
- **Remote name convention**: `workflow`

## Automatic Drift Notification

The `session-start.sh` hook checks the `workflow` remote once per 24h and prints a
one-line `🔄 TEMPLATE DRIFT` notice at session start when syncable paths differ
from `workflow/<default-branch>`. It does **not** modify files — it only nudges
you to run `/sync`.

**Enable on a fresh project:**

```bash
git remote add workflow https://github.com/Joaovsales/coding-agent-workflow.git
```

Once the remote exists, the hook takes over automatically. Fetch is capped at a
5-second timeout (offline sessions stay silent). Cache lives at
`.claude/.sync-check-cache` (gitignored).

**Silence the notification:**

```bash
touch .claude/sync-check-dismissed
```

**Force a re-check now** (bypass the 24h cache):

```bash
rm .claude/.sync-check-cache
```

## Syncable Paths

These are the files/directories managed by the workflow template:

```
.claude/skills/       → Skills (slash commands)
.claude/agents/       → Subagent definitions
.claude/hooks/        → Lifecycle hooks
.claude/settings.json → Hook configuration
CLAUDE.md             → Project rules & workflow instructions
```

**Never sync** (project-specific state):
- `.claude/project.md` — project-specific rules, Deployment Targets, team conventions
- `.claude/memory.md` — project-specific learnings
- `CLAUDE.local.md` — personal per-project overrides (gitignored)
- `tasks/` — project-specific task state
- `specs/` — project-specific feature specs

## Procedure

### Step 1 — Detect Connection Method

Check if the `workflow` remote already exists:

```bash
git remote get-url workflow 2>/dev/null
```

- **If remote exists**: proceed to Step 2.
- **If no remote**: ask the user which connection method to use:

| Option | Action |
|--------|--------|
| **Add git remote** | `git remote add workflow https://github.com/Joaovsales/coding-agent-workflow.git` |
| **Manual diff** | Skip git, do a file-by-file comparison using a local clone in `/tmp` |

If user chooses manual diff, clone to `/tmp/coding-agent-workflow` (or reuse if already there with `git -C /tmp/coding-agent-workflow pull`).

### Step 2 — Detect Remote Default Branch & Fetch Latest

First, detect the remote's default branch (handles repos using `master` or `main`):

```bash
# Detect the remote HEAD branch
WORKFLOW_BRANCH=$(git ls-remote --symref workflow HEAD 2>/dev/null \
  | grep '^ref:' \
  | sed 's|^ref: refs/heads/||' \
  | awk '{print $1}')

# Fall back to 'main' if detection fails
WORKFLOW_BRANCH=${WORKFLOW_BRANCH:-main}

echo "Remote default branch: $WORKFLOW_BRANCH"
git fetch workflow "$WORKFLOW_BRANCH"
```

Store the detected branch name — use `workflow/$WORKFLOW_BRANCH` in all subsequent steps (Steps 3, 4, 5) instead of the hardcoded `workflow/main`.

If using manual diff mode, use the `/tmp/coding-agent-workflow` clone as the source.

### Step 2.5 — Legacy Directory Migration

Older versions of this workflow shipped slash commands under `.claude/commands/`. The current layout uses `.claude/skills/`. Projects synced before the rename retain a stale `.claude/commands/` directory whose entries can shadow or contradict the canonical skills.

Detect and resolve before showing diffs:

1. Check whether `.claude/commands/` exists in the target project (`ls .claude/commands/ 2>/dev/null`)
2. **If absent:** silent no-op — do not log anything, proceed to Step 3.
3. **If present:** list its entries, then check for **overlapping basenames** with `.claude/skills/`:
   - Build the set `commands_basenames = basename(file) without extension for file in .claude/commands/`
   - Build the set `skills_basenames = basename(dir) for dir in .claude/skills/`
   - Compute the intersection
4. **If overlapping basenames exist:** surface the conflict list and refuse to auto-resolve:
   ```
   ⛔ Conflict: the following entries exist in BOTH .claude/commands/ and .claude/skills/:
     - <basename1>
     - <basename2>
   These would shadow each other at runtime. Resolve manually before re-running /sync:
     - Decide which version is authoritative (usually the skills/ version)
     - Delete the obsolete copy
     - Re-run /sync
   ```
   Do NOT prompt for archive/delete in this case — the user must intervene.
5. **If no overlapping basenames:** prompt the user with three options:
   ```
   Legacy directory .claude/commands/ found with N entries.
   The current workflow uses .claude/skills/ exclusively.
   How should we handle the legacy directory?
     [archive]  Rename to .claude/commands.legacy/ (preserves contents)
     [delete]   Remove .claude/commands/ entirely
     [skip]     Leave it in place for now (re-prompted next /sync)
   Choose: archive / delete / skip
   ```
6. Apply the user's choice:
   - `archive`: `mv .claude/commands .claude/commands.legacy`
   - `delete`: `rm -rf .claude/commands` (confirm once more before running)
   - `skip`: log "Legacy migration skipped — will re-prompt next /sync" and proceed

### Step 2.6 — Legacy CLAUDE.md Migration

Earlier versions of this workflow wrote the `## Deployment Targets` routing table directly into `CLAUDE.md`. The current layout keeps project-specific content in `.claude/project.md` so `/sync` can overwrite `CLAUDE.md` safely.

Before showing the diff, detect and offer to auto-migrate:

1. **Detect** with the exact-match regex:
   ```bash
   grep -qE '^## Deployment Targets[[:space:]]*$' CLAUDE.md 2>/dev/null
   ```
2. **If absent**: silent no-op — do not log anything, proceed to Step 3.
3. **If present in `CLAUDE.md` AND also present in `.claude/project.md`**: ambiguous state. Refuse to auto-migrate:
   ```
   ⛔ Conflict: ## Deployment Targets exists in BOTH CLAUDE.md AND .claude/project.md.
   Manually consolidate before re-running /sync:
     - Decide which section is authoritative
     - Delete the other
     - Re-run /sync
   ```
   Do NOT prompt — user must intervene.
4. **If present only in `CLAUDE.md`**: prompt with default-no:
   ```
   Legacy Deployment Targets section found in CLAUDE.md.
   The current layout keeps this section in .claude/project.md so /sync can
   overwrite CLAUDE.md safely without wiping your deployment config.

   Migrate now? [y/N]:
   ```
5. **On `y`** — apply the migration:
   a. Extract the block from the `^## Deployment Targets[[:space:]]*$` heading through the end of the `**Config:**` bullet list (or end-of-file / next `^## ` heading, whichever comes first)
   b. If `.claude/project.md` does not exist, create it from this stub:
      ```markdown
      # Project-Specific Configuration

      > Imported by CLAUDE.md. Safe to edit — /sync never touches this file.
      ```
   c. Append the extracted block to `.claude/project.md` (separated by a blank line from any existing content)
   d. Remove the same block from `CLAUDE.md`
   e. Ensure `.gitignore` contains `CLAUDE.local.md`; add it if missing with a comment header
   f. Stage all three files (`CLAUDE.md`, `.claude/project.md`, `.gitignore`) for the user to review
   g. Log: `✓ Migrated Deployment Targets from CLAUDE.md → .claude/project.md`
6. **On `n` (or default)** — **abort the entire sync**:
   ```
   Sync aborted — CLAUDE.md cannot be safely overwritten while Deployment Targets
   still lives in it. Re-run /sync and choose 'y' to migrate, or manually move the
   section to .claude/project.md.
   ```
   Do NOT partially apply. The whole sync stops here.

**Idempotency**: running `/sync` a second time after a successful migration finds no matching section in `CLAUDE.md`, takes the silent no-op path in step 2, and proceeds normally. Re-runs are safe.

### Step 3 — Show What Changed

Compare the syncable paths between the current project and the template source.

**If git remote mode:**
```bash
# Show changed files in syncable paths only
# Note: use two-dot diff (not three-dot) — template and project have unrelated histories,
# so HEAD...workflow/$WORKFLOW_BRANCH fails with "no merge base"
git diff workflow/$WORKFLOW_BRANCH --stat -- .claude/skills/ .claude/agents/ .claude/hooks/ .claude/settings.json CLAUDE.md
```

Then show the full diff:
```bash
git diff workflow/$WORKFLOW_BRANCH -- .claude/skills/ .claude/agents/ .claude/hooks/ .claude/settings.json CLAUDE.md
```

**If manual diff mode:**
For each syncable path, compare using `diff -rq` between the project and `/tmp/coding-agent-workflow`.

### Step 4 — Present Changes to User

Summarize the changes in a clear table:

```
| File                          | Status   | Summary                    |
|-------------------------------|----------|----------------------------|
| .claude/skills/sync/SKILL.md  | NEW      | New sync skill              |
| .claude/agents/planner.md     | MODIFIED | Updated planning prompts    |
| CLAUDE.md                     | MODIFIED | Added new workflow section  |
```

Then ask the user:

> **What would you like to sync?**
> 1. **All changes** — apply everything
> 2. **Pick files** — choose specific files to sync
> 3. **Preview only** — just show the diffs, don't apply anything
> 4. **Abort** — cancel sync

### Step 5 — Apply Changes

**If git remote mode (recommended for "all changes"):**
```bash
git checkout workflow/$WORKFLOW_BRANCH -- <selected-files>
```

**If manual diff mode or selective sync:**
Copy files from the source to the project, overwriting existing files.

For each applied file, briefly note what changed.

### Step 6 — Post-Sync

1. Run `git diff --stat` to confirm what was updated
2. Ask the user if they want to commit the sync:
   - Suggested message: `chore: sync workflow updates from coding-agent-workflow`
3. Remind the user to review `CLAUDE.md` if it was updated — they may need to merge project-specific customizations back in

## Edge Cases

- **CLAUDE.md is safe to overwrite**: thanks to the layered config model, `CLAUDE.md` contains only template rules + imports of `.claude/project.md` and `CLAUDE.local.md`. Project-specific content lives in those imported files, which `/sync` never touches. Legacy projects with content inlined into `CLAUDE.md` are handled by the Step 2.6 migration step above.
- **settings.json merge**: If the project has custom hooks in `.claude/settings.json`, show both versions and help the user merge rather than overwrite.
- **New files**: Files that exist in the template but not the project are shown as NEW and can be added.
- **Deleted files**: Files that exist in the project's `.claude/` but NOT in the template are flagged — they may be project-specific additions (don't remove them).
- **`.claude/project.md` missing in the target project**: expected for fresh projects that haven't run `/setup-deployment` yet. `/sync` does not create it — that happens lazily on first write by `/setup-deployment` or the migration step above.
