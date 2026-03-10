# /wrap-up-session — Session Wrap-Up

Close out the session by syncing learnings, updating task and bug registers, running tests, and pushing changes.

---

## Step 1 — Capture Learnings

Run the `/learn` skill to:
- Extract patterns from the session
- Append them to `.claude/memory.md` under "Patterns & Lessons"
- Append a session summary to `.claude/memory.md` under "Session History"
- Mirror patterns into `tasks/lessons.md`

---

## Step 2 — Update Task Register (`tasks/todo.md`)

Read `tasks/todo.md` and reconcile it against the actual state of the code:

- Mark any completed items `[x]` that aren't already marked
- Leave remaining items `[ ]`
- Append a summary block at the bottom:

```markdown
## Session Summary — [YYYY-MM-DD]
- Completed: [X tasks]
- Pending: [Y tasks]
- Carry-forward: [brief description of what remains]
```

---

## Step 3 — Update Bug Register (`tasks/bugs.md`)

If `tasks/bugs.md` does not exist, create it with this header:

```markdown
# Bug Register

| ID | Date | Description | Status | Notes |
|----|------|-------------|--------|-------|
```

Then:
- Add any new bugs discovered during the session (status: `open`)
- Close bugs that were fixed this session (status: `fixed — [YYYY-MM-DD]`)
- Skip if no bugs were found or fixed

---

## Step 4 — Run Tests via Testing Subagent

Determine the appropriate test scope based on what was changed this session:

| Scope | When to use |
|-------|-------------|
| **Unit** | Only isolated logic changed (utilities, helpers, pure functions) |
| **Integration** | API endpoints, database queries, or service interactions changed |
| **E2E** | UI flows, auth paths, or multi-service workflows changed |
| **All** | Core architecture changed or scope is unclear |

Delegate to a subagent using the Agent tool:

```
subagent_type: code-debugger
task: Run [unit/integration/E2E/all] tests for the changes made this session.
      Files changed: [list from git diff --name-only HEAD].
      Confirm all tests pass and report any failures with the error message and file location.
```

**If tests fail**: Fix the failures before proceeding. Do not push broken code.

---

## Step 5 — Push to Main

Once all tests pass:

```bash
git add -p   # stage only relevant changes — never blindly stage everything
git status   # confirm what's staged
git commit -m "[type]: [concise description of what this session accomplished]"
git push -u origin main
```

Commit message types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`

**Do not push if**:
- Any test is failing
- There are uncommitted changes you haven't reviewed
- The security scan (if run) has unresolved HIGH/MEDIUM issues

---

## Done

Reply:
```
Session wrapped up.
- Learnings: [N patterns captured / none]
- Tasks: [X completed, Y pending]
- Bugs: [N opened, N closed / no changes]
- Tests: [PASS — suite name] or [FAIL — see above]
- Pushed: [yes / no — reason]
```
