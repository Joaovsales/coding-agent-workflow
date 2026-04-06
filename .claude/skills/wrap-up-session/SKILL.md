---
name: wrap-up-session
description: Close session with parallel code review, testing, fixes, and a clean commit. Use at the end of any coding session.
disable-model-invocation: false
---

# /wrap-up-session — Session Wrap-Up

Close out the session by syncing learnings, updating registers, running a parallel code review, testing, and pushing changes.

---

## Step 0 — Pre-Flight Check

Before running the full wrap-up, determine if there is anything to wrap up.

1. Run `git diff --name-only` and `git diff --name-only --cached` to check for uncommitted changes
2. Run `git log --oneline <base-branch>...HEAD` to check for commits on this branch

**If no changes exist** (no uncommitted changes AND no commits beyond base branch):

Reply:
```
Session wrapped up (no changes).
- No code changes detected this session.
- Skipped: code review, tests, commit, push.
```
Then **STOP** — do not proceed to Step 1.

**If changes exist**: proceed normally.

### Base Branch Detection

Determine the base branch once and use it throughout all subsequent steps:

1. Check for `main`: `git show-ref --verify --quiet refs/heads/main`
2. If not found, check for `master`: `git show-ref --verify --quiet refs/heads/master`
3. If not found, check for `develop`: `git show-ref --verify --quiet refs/heads/develop`
4. If none found: use the merge-base of the current branch with `origin/HEAD` — `git merge-base HEAD origin/HEAD`
5. If that also fails: warn the user and ask them to specify the base branch

Store the detected base branch and reference it as `<base-branch>` in all later steps. Do not hardcode `main`.

---

## Step 0.5 — Project Context Staleness Check

If `tasks/project-context.md` exists, check for divergence between what was documented and what was actually built this session:

1. **Dependencies**: Compare `package.json` / `pyproject.toml` / `go.mod` against the `[ARCHITECTURE]` section — new libraries added?
2. **Structure**: Check for new directories or modules not reflected in `[ARCHITECTURE]` or `[CONVENTIONS]`
3. **Patterns**: Look for changed auth approaches, new middleware, database changes via `git diff --name-only <base-branch>...HEAD`

**If divergence found:**
- **Auto-update `tasks/project-context.md`** — it's an agent-facing file, no user approval needed
- **Flag PRD sections that may need updating** — show the user which sections are potentially stale and ask: _"These PRD sections may be outdated: [list]. Update them now? (y/n)"_
- If yes: update only the affected sections in `specs/prd-*.md` and append to the Revision History
- If no: proceed — the user can update later

**If no divergence or no project-context file:** skip to Step 1.

---

## Step 1 — Capture Learnings

Run the `/learn` skill to:
- Extract patterns from the session
- Append them to `.claude/memory.md` under "Patterns & Lessons"
- Append a session summary to `.claude/memory.md` under "Session History"
- Mirror patterns into `tasks/lessons.md`

**If `/learn` produces no patterns** (nothing notable happened): log "No patterns captured" and continue. Do not treat this as a failure.

**If `/learn` errors** (file not found, write failure): log the error, continue to Step 2. Learnings are valuable but not blocking.

---

## Step 2 — Update Task Register (`tasks/todo.md`)

Read `tasks/todo.md` and reconcile it against the actual state of the code:

- Mark any completed items `[x]` that aren't already marked
- Leave remaining items `[ ]`

### Idempotency Check

Generate a **session fingerprint** from the commit range: the short SHA of the first and last commit on this branch beyond `<base-branch>` (e.g., `a1b2c3f..d4e5f6a`). Include this fingerprint in the session summary header.

Before appending a session summary:
1. Scan existing summaries in `tasks/todo.md` for one matching the same commit-range fingerprint
2. **If a matching fingerprint exists**: update it in place rather than appending a duplicate
3. **If no match**: append a new summary (even if another summary exists for today's date — multiple sessions per day are valid)

```markdown
## Session Summary — [YYYY-MM-DD] [a1b2c3f..d4e5f6a]
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
- Use `git diff --name-only <base-branch>...HEAD` (the detected base branch from Step 0) to scope review to changed files only
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

### Agent Failure Handling

If any agent errors out (timeout, crash, empty response):

1. **Log the failure**: note which agent failed and the error
2. **Do NOT retry automatically** — the remaining agents' results are still valid
3. **Cover the gap manually**: spot-check the failed agent's scope using `git diff` in the main context
4. **Set the review status to `degraded`** — this affects Step 7 (see Code Review Gate below)

---

## Step 5 — Reconcile & Apply Fixes

When agents return their findings:

1. **Apply most recommendations** — if on the fence, do it
2. **Resolve conflicts** — prefer reusing existing code (Agent 1) over extracting new abstractions (Agent 2)
3. **Track skipped items** — only skip with strong justification; note the reason

### Review-Fix-Recheck Loop (max 2 iterations)

After applying fixes from the initial review:

1. Run a **lightweight verification pass**: re-check only the files that were modified during fix application using `git diff --name-only` (unstaged changes since the review)
2. If the verification pass finds **new issues introduced by the fixes**: apply those fixes too (iteration 2)
3. If iteration 2 still finds issues: **stop the loop**, note remaining issues, and proceed. Do not iterate indefinitely.
4. If a pass finds **zero issues or only minor/stylistic issues**: the loop converges — proceed to Step 5.5

**Convergence rule**: if a pass finds ≤2 minor issues, note them and proceed rather than re-reviewing.

---

## Step 5.5 — Verification Gate

Before running tests, apply the `/verify` pattern to all claims:

1. **No premature satisfaction** — Do not say "Great!", "Perfect!", or "Done!" until verification evidence exists
2. **Evidence before claims** — Every statement about code state must reference actual command output
3. **Check agent results independently** — If sub-agents from Step 4 reported "no issues", verify by spot-checking their scope with `git diff`

**Gate check:**
- Can you point to specific command output proving each claim? If not, run the command first.
- Did you actually read the full test output, or just check the exit code?
- Are there any "should work" or "probably fine" assumptions? Replace with evidence.

---

## Step 6 — Run Tests

### Test Discovery

Discover test commands from `package.json`, `Makefile`, `pyproject.toml`, `TESTING.md`, or equivalent.

**If no test suite is found**:
1. Check for common test files: `**/*.test.*`, `**/*.spec.*`, `**/test_*.py`, `tests/`, `__tests__/`
2. If test files exist but no runner is configured: warn the user ("Tests exist but no runner found — skipping test step")
3. If no test files exist at all: note "No test suite configured" and **skip to Step 6.5**. Do not fabricate test commands.

### Test Scope

Determine the appropriate test scope based on what was changed this session:

| Scope | When to use |
|-------|-------------|
| **Unit** | Only isolated logic changed (utilities, helpers, pure functions) |
| **Integration** | API endpoints, database queries, or service interactions changed |
| **E2E** | UI flows, auth paths, or multi-service workflows changed |
| **All** | Core architecture changed or scope is unclear |

Run in order: lint/typecheck, unit tests, integration tests, e2e tests.

**If tests fail**: Fix the root cause (not a workaround), re-run tests. Max 2 fix attempts; if still failing, report to user with details and **do not push**.

---

## Step 6.5 — Worktree Integration (if applicable)

If working in a git worktree (check with `git worktree list`):

### Merge to Main
The goal of worktree development is always to merge back to main:

1. **Verify clean state**: All tests pass, no uncommitted changes
2. **Switch to main worktree**: `cd` to the main worktree path
3. **Pull latest**: `git pull origin main`
4. **Merge feature branch**: `git merge <feature-branch>`
5. **Run tests on merged result**: Full test suite must pass after merge
6. **If merge conflicts**: Resolve conflicts, run tests again
7. **If tests fail after merge**: Fix issues, run tests again. Max 2 attempts before escalating to user.

### Cleanup
After successful merge:
1. Remove the worktree: `git worktree remove <worktree-path>`
2. Delete the feature branch: `git branch -d <feature-branch>`
3. Report: "Worktree merged to main and cleaned up."

### If NOT in a worktree
Skip this step entirely — proceed to Step 7.

---

## Step 7 — Commit & Push

### Code Review Gate

Before committing, verify the code review from Step 4 completed with full coverage:

| Review Status | Action |
|---------------|--------|
| **All 4 agents returned results** | Proceed to commit & push |
| **Any agent failed** (status: `degraded`) | **STOP** — report which review dimensions were missed, show the manual spot-check findings, and ask the user: _"Code review was incomplete ([agent name] failed). Proceed with push anyway? (y/n)"_. Do not push without explicit user approval. |
| **Review-fix loop did not converge** (Step 5 hit max iterations with remaining issues) | **STOP** — list the unresolved issues and ask the user: _"[N] review issues remain unresolved after 2 fix iterations. Proceed with push anyway? (y/n)"_. Do not push without explicit user approval. |

### Commit & Push

Once the code review gate passes and all tests pass:

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
- The code review gate has not been satisfied (all agents passed OR user explicitly approved)

### Push Failure Handling

If `git push` fails:

| Failure | Action |
|---------|--------|
| **Network error** | Retry up to 4 times with exponential backoff (2s, 4s, 8s, 16s) |
| **Rejected (non-fast-forward)** | Run `git pull --rebase origin <branch>`, resolve any conflicts, re-run tests, then push again |
| **Permission denied** | Do not retry. Report to user: "Push failed — permission denied on `<branch>`" |
| **Branch protection** | Do not retry. Report to user: "Push blocked by branch protection rules" |
| **Still failing after retries** | Report the error to user. Do not force-push. |

---

## Done

Reply:
```
Session wrapped up.
- Learnings: [N patterns captured / none]
- Tasks: [X completed, Y pending]
- Bugs: [N opened, N closed / no changes]
- Code Review: [PASS / DEGRADED — <agent name> failed / INCOMPLETE — N unresolved issues]
  - Issues: [N found, N fixed, N skipped]
- Tests: [PASS — suite name] or [FAIL — see above] or [SKIPPED — no test suite]
- Pushed: [yes / no — reason] [user-approved if review gate was overridden]
```
