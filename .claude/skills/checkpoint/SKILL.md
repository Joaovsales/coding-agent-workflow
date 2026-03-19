---
name: checkpoint
description: Snapshot current session progress to tasks/checkpoint.md for handoff or pause.
---

# /checkpoint — Session Checkpoint

Save a snapshot of current progress for handoff, pause, or context compaction.

## Steps

### 1. Gather Current State

Run these to understand where things stand:
```bash
git status
git diff --stat
git log --oneline -5
```

Read `tasks/todo.md` to enumerate completed vs. remaining items.

### 2. Write Checkpoint

Create or overwrite `tasks/checkpoint.md`:

```markdown
# Checkpoint — [YYYY-MM-DD HH:MM]

## Overall Status
- Completed tasks: [X of Y]
- Blockers: [none / describe]

## Completed This Session
- [x] [task description]
- [x] [task description]

## Remaining Tasks
- [ ] [task description]
- [ ] [task description]

## Open Questions / Blockers
- [Any question or blocker that needs resolution]

## Files Modified
[paste git diff --stat output here]

## How to Resume
1. Read this file and `tasks/todo.md`
2. Read `.claude/memory.md` for project context
3. Continue from the first `[ ]` item in `tasks/todo.md`
```

### 3. Optional — Commit the Checkpoint

Ask the user: "Commit the checkpoint now? (y/n)"

If yes:
```bash
git add tasks/checkpoint.md tasks/todo.md
git commit -m "checkpoint: [brief description of progress]"
```

### 4. Confirm

Reply: "Checkpoint saved to `tasks/checkpoint.md`."
