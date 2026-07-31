---
name: wrap-up-session
description: Close session with code review, testing, fixes, and a clean commit. Use at the end of any coding session.
---

# /wrap-up-session — Session Wrap-Up

Close out the session by syncing learnings, updating registers, running code review, testing, and pushing changes.

---

## Step 0 — Pre-Flight Check

1. Run `git diff --name-only` and `git diff --name-only --cached` to check for uncommitted changes
2. Run `git log --oneline <base-branch>...HEAD` to check for commits on this branch

**If no changes exist** (no uncommitted changes AND no commits beyond base branch):

```
Session wrapped up (no changes).
- No code changes detected this session.
- Skipped: code review, tests, commit, push.
```
Then **STOP**.

**If changes exist**: proceed normally.

### Base Branch Detection

1. Check for `main`: `git show-ref --verify --quiet refs/heads/main`
2. If not found, check for `master`
3. If not found, check for `develop`
4. If none found: `git merge-base HEAD origin/HEAD`
5. If that also fails: warn the user and ask them to specify

Store the detected base branch as `<base-branch>` for all later steps.

---

## Step 0.5 — Project Context Staleness Check

If `tasks/project-context.md` exists:

1. Compare `package.json` / `pyproject.toml` / `go.mod` against `[ARCHITECTURE]` — new libraries added?
2. Check for new directories or modules not reflected in `[ARCHITECTURE]` or `[CONVENTIONS]`
3. Look for changed patterns via `git diff --name-only <base-branch>...HEAD`

**If divergence found**: auto-update `tasks/project-context.md`, then flag affected PRD sections to the user for optional review.

---

## Step 1 — Capture Learnings

Run `/learn` to extract patterns and append to `tasks/memory.md` and `tasks/lessons.md`.

If `/learn` produces no patterns: log "No patterns captured" and continue.
If `/learn` errors: log the error, continue. Learnings are valuable but not blocking.

---

## Step 1.5 — Memory Maintenance

Run `/memory-maintain` (it self-gates on the session count — runs every 5 sessions automatically).

---

## Step 2 — Update Task Register (`tasks/todo.md`)

- Mark completed items `[x]`
- Detect duplicate `## Plan:` headings, orphan unchecked tasks, stale plan blocks
- Append session summary with idempotency fingerprint (commit range short-SHAs)

```markdown
## Session Summary — [YYYY-MM-DD] [a1b2c3f..d4e5f6a]
- Completed: [X tasks]
- Pending: [Y tasks]
- Carry-forward: [brief description]
```

---

## Step 3 — Update Bug Register (`tasks/bugs.md`)

- Add new bugs discovered (status: `open`)
- Close bugs fixed this session (status: `fixed — [YYYY-MM-DD]`)
- Create file with header if it doesn't exist

---

## Step 3.5 — Security Scan

Run `/security-scan` on files changed this session (`git diff --name-only <base-branch>...HEAD`).
Address any MUST-FIX findings before proceeding to commit.

---

## Step 3.7 — Shortcut Ledger

`CLAUDE.md` § *Code Economy* marks deliberate shortcuts with `TODO(shortcut):`
naming a limit and an upgrade path. Collect them so a deferral cannot quietly
become permanent:

```bash
grep -rnE '(#|//|--) ?TODO\(shortcut\):' . \
  --exclude-dir={.git,node_modules,dist,build,vendor} 2>/dev/null || true
```

One line per marker: `<file>:<line> — <limit>. upgrade: <trigger>.` Tag any
marker naming no upgrade path `no-trigger` — those are the ones that rot. Close
with `<N> shortcuts, <M> without a trigger.`

No markers found: print nothing and move on (failure-only reporting, per
`CLAUDE.md` § *Observability Discipline*). This step reports only — it never
blocks the commit, and shortcuts are not bugs, so they do not go in
`tasks/bugs.md`.

---

## Step 4 — Code Review (4 passes)

Run 4 sequential self-review passes in the main context. For each pass:
- Use `git diff --name-only <base-branch>...HEAD` to scope to changed files
- Focus on issues **introduced** by this session, not pre-existing patterns
- Classify every finding with exactly one severity tag: `MUST-FIX`, `SHOULD-FIX`, or `NITPICK`

### Severity Classification

| Severity | Definition |
|----------|-----------|
| `MUST-FIX` | Correctness, security, silent failures, data loss |
| `SHOULD-FIX` | Quality, maintainability, coverage gaps |
| `NITPICK` | Purely cosmetic — zero logic/behavior impact |

`NITPICK` is ONLY for cosmetic issues. Any logic, architecture, or security finding is `SHOULD-FIX` or higher.

**Output format for each finding**:
```
[MUST-FIX] file.py:42 — Description and impact
[SHOULD-FIX] handler.py:120 — Description and impact
[NITPICK] utils.py:30 — Description
```

### Pass 1: Codebase Consistency
- Duplicated logic that already exists elsewhere in the codebase
- Inconsistencies where the same fix should be applied in similar locations
- Missed opportunities to reuse existing utilities

### Pass 2: Defensive Code Audit
- Silent exception swallowing or overly broad catch blocks
- Fallback values that mask real errors
- Null-safe chains hiding broken assumptions
- Patterns that make production debugging harder

### Pass 3: Test Coverage
- Changed code paths that lack test coverage
- Missing edge case tests, error path tests, boundary conditions
- Existing tests that no longer align with changed behavior

### Pass 4: Adversarial Critic
- Read the specs touched this session and every AC
- Ask "what AC is this missing?" and "what user-facing behavior would break?"
- Hunt for: response-shape mismatches, declared-done-without-e2e patterns, duplicate todo blocks
- Check API contract changes against any clients (frontend, tests, docs)

---

## Step 5 — Reconcile & Apply Fixes

### 5.1 — Severity-Based Enforcement

| Severity | Action |
|----------|--------|
| `MUST-FIX` | Apply immediately. Cannot be skipped. |
| `SHOULD-FIX` | Apply by default. May skip ≤3 total with code-specific justification. |
| `NITPICK` | Auto-skip. |

### 5.2 — Review Reconciliation Table

After processing all findings (skip if total findings ≤ 3):

```markdown
### Review Reconciliation

| # | Pass | Severity | Finding | Action | Justification |
|---|------|----------|---------|--------|---------------|
```

### 5.3 — Review-Fix-Recheck Loop (max 2 iterations)

After applying fixes, re-check only modified files. If new issues found: apply fixes (iteration 2). Stop after iteration 2.

---

## Step 5.5 — Verification Gate

Before tests, verify all claims have direct evidence:
- No premature satisfaction — no "Great!" or "Done!" before verification
- Every code state claim must reference actual command output
- Check that review results are genuinely clean (spot-check with `git diff`)

---

## Step 6 — Run Tests

Discover test commands from `package.json`, `Makefile`, `pyproject.toml`, or `TESTING.md`.

Run in order: lint/typecheck, unit, integration, e2e.

If tests fail: fix root cause (not workaround), re-run. Max 2 fix attempts; if still failing, report and do not push.

---

## Step 6.3 — E2E Coverage Gate

For every user-facing AC in specs touched this session:

1. Confirm a `/verify --scope e2e` walkthrough ran by checking `tasks/e2e-log.md` for an entry matching the spec and current commit short-sha
2. If missing: ask:
   > "AC [ID] is user-facing but has no e2e walkthrough. Run /verify --scope e2e now, or acknowledge the gap? (run/acknowledge)"
3. On `run`: invoke `/verify --scope e2e`, then re-check
4. On `acknowledge`: record the gap in `tasks/lessons.md` under "E2E Gaps"

If no specs were touched: skip this gate silently.

---

## Step 7 — Commit & Push

### Code Review Gate

| Review Status | Action |
|---------------|--------|
| All MUST-FIX applied AND ≤3 SHOULD-FIX skipped | Proceed |
| Any MUST-FIX skipped | STOP — ask user for explicit approval |
| More than 3 SHOULD-FIX skipped | STOP — present skipped items, ask for approval |

### Commit & Push

1. Stage changes: `git add -p` — stage only relevant changes
2. Commit with type prefix: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`
3. Append optional trailers: `Constraint:`, `Rejected:`, `Not-tested:`, `Confidence:`
4. Push: `git push -u origin <branch>`
5. Create PR if none exists for this branch

**Do not push if**: any test is failing, uncommitted changes unreviewed, MUST-FIX skipped.

### Push Failure Handling

| Failure | Action |
|---------|--------|
| Network error | Retry up to 4 times with backoff (2s, 4s, 8s, 16s) |
| Non-fast-forward | `git pull --rebase`, resolve conflicts, push again |
| Permission denied | Report to user — do not retry |
| Branch protection | Report to user — do not retry |

---

## Step 7.5 — Worktree Integration (if applicable)

Runs **after** Step 7, not before it. Merging can only follow committing — the
previous version of this step ran before the commit, so it either found a dirty
tree or merged a branch that did not yet contain the session's work.

If NOT in a git worktree: skip. Otherwise check which flow this repo uses.

**If the work goes through a pull request (default when `origin` exists):**

1. Confirm Step 7 pushed the branch: `git status -sb` shows no `ahead`
2. Open the PR (`gh pr create`) or confirm one is already open
3. **Stop here. Do not merge locally and do not delete the branch** — an open PR
   whose source branch is gone is a dead PR, and a local merge to `main` bypasses
   the review the PR exists to get
4. Removing the *worktree directory* is fine once pushed
   (`git worktree remove <path>`); the branch must survive until the PR lands

**If the repo merges locally (no remote, or the user asked for a direct merge):**

1. Verify clean: `git status --porcelain` empty
2. Switch to the parent worktree, `git pull --ff-only`
3. `git merge --no-ff <branch>`
4. Run the **full** suite on the merged result — this is the first time these two
   lines of history have coexisted, so a green run on either side proves nothing
   about the merge
5. Green → `git worktree remove <path>` and delete the branch
6. Red → keep both, report the failures, change nothing else

**Conflicts.** Expect them in `tasks/*.md` — the append-only registers are
touched by nearly every session and are a bigger conflict source than source
code. A `.gitattributes` with `merge=union` on those files removes the mechanical
conflict but not the semantic one: two sessions that each allocate the next
`BUG-NNN` produce duplicate IDs with no marker to catch it. After merging, scan
the register for repeated IDs before trusting it.

---

## Step 8 — Deployment Verification

After push, verify deployment services if `## Deployment Targets` section exists in `.claude/project.md` (Claude Code only).

Use `/verify --scope deployment` to poll, fetch logs on failure, and loop a `code-debugger` fix cycle up to 3 iterations.

If `--skip-deploy` flag was passed: skip this step entirely.

If no `## Deployment Targets` section: scan `tasks/deployments/*.md` for signal files. If found, nudge user to run `/setup-deployment`. If not found: skip silently.

---

## Done

```
Session wrapped up.
- Learnings: [N patterns / none]
- Tasks: [X completed, Y pending]
- Bugs: [N opened, N closed / no changes]
- Code Review: [PASS / INCOMPLETE — N unresolved issues]
  - MUST-FIX: [N found, N fixed]
  - SHOULD-FIX: [N found, N fixed, N skipped]
  - NITPICK: [N found, skipped]
- Security Scan: [PASS / N issues addressed]
- Tests: [PASS — suite name] or [FAIL] or [SKIPPED — no suite]
- E2E coverage: [N user-facing ACs verified / NONE / GAP — N acknowledged]
- Pushed: [yes / no — reason]
- Deployments: [results or SKIPPED / NONE]
```

## Claude Code Enhancements

### Step 4 — Parallel Code Review
Launch all 4 review passes as parallel agents in a SINGLE message with multiple Agent tool calls.
Each agent uses model: sonnet.

Agent assignments:
- Agent 1: `code-reviewer` — Codebase Consistency (Pass 1)
- Agent 2: `code-reviewer` — Defensive Code Audit (Pass 2)
- Agent 3: `code-reviewer` — Test Coverage (Pass 3)
- Agent 4: `critic` — Adversarial Critic (Pass 4)
