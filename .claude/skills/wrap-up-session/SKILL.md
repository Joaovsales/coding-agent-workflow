---
name: wrap-up-session
description: Close session with parallel code review, testing, fixes, and a clean commit. Use at the end of any coding session.
disable-model-invocation: true
---

# /wrap-up-session — Session Wrap-Up

Close out the session by syncing learnings, updating registers, running a parallel code review, testing, and pushing changes.

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

## Step 4 — Parallel Code Review (4 agents)

Launch these four agents simultaneously using the Agent tool. Each agent should:
- Run `git diff --name-only main...HEAD` (or the base branch) to scope review to changed files only
- Check `git log --oneline -10` for recent commit context before recommending reversals
- Focus on issues **introduced** by this session, not pre-existing patterns

### Agent 1: Codebase Consistency
- Flag duplicated logic that already exists elsewhere in the codebase
- Identify inconsistencies where the same fix/pattern should be applied in similar locations
- Check for missed opportunities to reuse existing utilities or services

### Agent 2: Clean Code & SOLID
- Single Responsibility violations, long methods, deep nesting
- Open/Closed: conditionals that should be polymorphism/strategy
- Proper abstraction levels, meaningful names, small functions

### Agent 3: Defensive Code Audit
- Silent exception swallowing or overly broad catch blocks
- Fallback values that mask real errors
- Null-safe chains hiding broken assumptions
- Any pattern that makes production debugging harder

### Agent 4: Test Coverage Reviewer
- Identify changed code paths that lack test coverage
- Flag missing edge case tests, error path tests, boundary conditions
- Check that existing tests still align with the changed behavior
- Recommend specific tests to add (unit, integration, or e2e)

---

## Step 5 — Reconcile & Apply Fixes

When agents return their findings:

1. **Apply most recommendations** — if on the fence, do it
2. **Resolve conflicts** — prefer reusing existing code (Agent 1) over extracting new abstractions (Agent 2)
3. **Track skipped items** — only skip with strong justification; note the reason
4. **Aim for convergence** — on follow-up passes, if agents find only minor/stylistic issues, note this and recommend proceeding

---

## Step 6 — Run Tests

Determine the appropriate test scope based on what was changed this session:

| Scope | When to use |
|-------|-------------|
| **Unit** | Only isolated logic changed (utilities, helpers, pure functions) |
| **Integration** | API endpoints, database queries, or service interactions changed |
| **E2E** | UI flows, auth paths, or multi-service workflows changed |
| **All** | Core architecture changed or scope is unclear |

Discover test commands from `package.json`, `Makefile`, `pyproject.toml`, `TESTING.md`, or equivalent. Run in order: lint/typecheck, unit tests, integration tests, e2e tests.

**If tests fail**: Fix the root cause (not a workaround), re-run tests. Max 2 fix attempts; if still failing, report to user with details.

---

## Step 7 — Commit & Push

Once all tests pass:

1. **Branch check**: if on `main`/`master`, create a feature branch first
2. **Stage changes**: `git add -p` — stage only relevant changes, never blindly stage everything
3. **Review staged**: `git status` to confirm
4. **Commit**: `git commit -m "[type]: [concise description of session work]"`
5. **Push**: `git push -u origin <branch>`
6. **PR**: if no PR exists for this branch, create one with a summary; if one exists, push to it

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
- Code Review: [N issues found, N fixed, N skipped]
- Tests: [PASS — suite name] or [FAIL — see above]
- Pushed: [yes / no — reason]
```
