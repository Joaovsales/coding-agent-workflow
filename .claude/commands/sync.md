# /sync — Sync Workflow Updates from Template Repo

Pull the latest skills, commands, hooks, agents, and config from the `coding-agent-workflow` template repo into the current project.

## Source Repo

- **GitHub**: `Joaovsales/coding-agent-workflow`
- **Remote name convention**: `workflow`

## Syncable Paths

These are the files/directories managed by the workflow template:

```
.claude/commands/     → Skills (slash commands)
.claude/agents/       → Subagent definitions
.claude/hooks/        → Lifecycle hooks
.claude/settings.json → Hook configuration
CLAUDE.md             → Project rules & workflow instructions
conductor/            → Workflow docs, styleguides, product docs
```

**Never sync** (project-specific state):
- `.claude/memory.md` — project-specific learnings
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

### Step 2 — Fetch Latest

```bash
git fetch workflow main
```

If using manual diff mode, use the `/tmp/coding-agent-workflow` clone as the source.

### Step 3 — Show What Changed

Compare the syncable paths between the current project and the template source.

**If git remote mode:**
```bash
# Show changed files in syncable paths only
git diff HEAD...workflow/main --stat -- .claude/commands/ .claude/agents/ .claude/hooks/ .claude/settings.json CLAUDE.md conductor/
```

Then show the full diff:
```bash
git diff HEAD...workflow/main -- .claude/commands/ .claude/agents/ .claude/hooks/ .claude/settings.json CLAUDE.md conductor/
```

**If manual diff mode:**
For each syncable path, compare using `diff -rq` between the project and `/tmp/coding-agent-workflow`.

### Step 4 — Present Changes to User

Summarize the changes in a clear table:

```
| File                          | Status   | Summary                    |
|-------------------------------|----------|----------------------------|
| .claude/commands/sync.md      | NEW      | New sync command            |
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
git checkout workflow/main -- <selected-files>
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

- **CLAUDE.md conflicts**: If the project has customized CLAUDE.md, warn the user that syncing will overwrite their changes. Suggest they diff manually and merge sections.
- **settings.json merge**: If the project has custom hooks in `.claude/settings.json`, show both versions and help the user merge rather than overwrite.
- **New files**: Files that exist in the template but not the project are shown as NEW and can be added.
- **Deleted files**: Files that exist in the project's `.claude/` but NOT in the template are flagged — they may be project-specific additions (don't remove them).
