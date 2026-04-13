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

### Duplicate Plan Block Detection

Before generating the session summary, scan `tasks/todo.md` for stale or duplicated content:

1. **Duplicate `## Plan:` headings** — two or more headings with the same feature name. Merge them: promote any `[ ]` subtask that is unchecked in the older block but missing from the newer one, then remove the duplicate heading.
2. **Orphan unchecked subtasks** — a `[ ]` item under a plan whose siblings are all `[x]`. Flag these to the user:
   > _"Plan '<name>' has N unchecked subtasks while others are complete. Are these genuinely pending or should they be closed? (pending/close)"_
3. **Stale plan blocks** — `## Plan:` blocks whose referenced spec file (`> Spec: specs/...`) no longer exists on disk. Flag for archival:
   > _"Plan '<name>' references a missing spec '<path>'. Archive this plan block? (y/n)"_

Do not proceed to the Idempotency Check while duplicates remain. Resolving them keeps the task register honest before a session summary is appended.

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
- **Classify every finding** using the severity format below

### Severity Classification (required for all agents)

Every finding MUST use exactly one of these severity tags:

| Severity | Definition | Examples |
|----------|-----------|----------|
| `MUST-FIX` | Correctness, security, silent failures, data loss | Bugs, injection risks, swallowed exceptions, race conditions, missing auth checks |
| `SHOULD-FIX` | Quality, maintainability, coverage gaps | SRP violations, missing tests, code smells, broad catches, defensive gaps, performance issues |
| `NITPICK` | Purely cosmetic — zero logic/behavior impact | Naming style, whitespace, comment wording, import ordering |

**Classification rules:**
- `NITPICK` is ONLY for cosmetic issues. Any finding involving logic, architecture, correctness, error handling, or security MUST be `SHOULD-FIX` or higher.
- When in doubt between two levels, choose the higher severity.

**Output format for each finding:**
```
[MUST-FIX] file.py:42 — Description of the issue and its impact
[SHOULD-FIX] handler.py:120 — Description of the issue and its impact
[NITPICK] utils.py:30 — Description of the issue
```

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

When agents return their findings, process them by severity:

### 5.1 — Severity-Based Enforcement

| Severity | Action | Skip Rules |
|----------|--------|------------|
| `MUST-FIX` | **Apply immediately.** Cannot be skipped. | Skipping a MUST-FIX triggers a hard gate in Step 7. |
| `SHOULD-FIX` | **Apply by default.** May skip ≤3 total with justification. | Justification must reference a specific code-level reason (e.g., "intentional retry-all pattern per spec"). Generic dismissals ("not relevant", "out of scope", "refactoring suggestion") are NOT valid justifications. |
| `NITPICK` | **Auto-skip.** No action required. | No justification needed. |

**Conflict resolution:** When agents disagree on severity for the same file/issue, the highest severity wins. Prefer reusing existing code (Agent 1) over extracting new abstractions (Agent 2).

**Deduplication:** If two agents flag the same issue, merge into one finding using the highest severity.

### 5.2 — Review Reconciliation Table

After processing all findings, produce a reconciliation table. **Skip the table if total findings ≤ 3** (low-ceremony exception).

```markdown
### Review Reconciliation

| # | Agent | Severity | Finding | Action | Justification |
|---|-------|----------|---------|--------|---------------|
| 1 | Clean Code | MUST-FIX | Swallowed exception in api.py:45 | FIXED | Added explicit error propagation |
| 2 | Defensive | SHOULD-FIX | Broad catch in handler.py:120 | SKIPPED | Intentional retry-all pattern per spec |
| 3 | Consistency | NITPICK | Rename `tmp` to `buffer` in utils.py:30 | SKIPPED | — |
```

**Table rules:**
- Every finding from every agent must appear — no silent omissions
- `MUST-FIX` rows: Action must be `FIXED` (never `SKIPPED`)
- `SHOULD-FIX` + `SKIPPED` rows: Justification must be code-specific (not generic)
- `NITPICK` rows: Justification column shows `—`

### 5.3 — Review-Fix-Recheck Loop (max 2 iterations)

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

## Step 6.3 — E2E Coverage Gate

For every acceptance criterion in the specs touched this session (`git diff --name-only <base-branch>...HEAD -- specs/`):

1. Re-classify each AC as `logic | integration | user-facing` using the same rules as `/build` Pre-Flight Step 7
2. For each user-facing AC, confirm a `/verify-e2e` walkthrough ran during the session by checking `tasks/e2e-log.md` for an entry whose Spec line and Commit short-sha match the current commit range
3. If any user-facing AC has no matching e2e log entry: **STOP** and ask:
   > _"AC [ID] is user-facing but has no e2e walkthrough recorded in tasks/e2e-log.md. Run /verify-e2e now, or acknowledge the gap? (run/acknowledge)"_
4. On `run`: invoke `/verify-e2e`, then re-check
5. On `acknowledge`: record the gap in `tasks/lessons.md` under "E2E Gaps" with the AC ID and reason, then proceed. Do not silently skip.

**If no specs were touched this session:** this gate is a silent no-op — proceed to Step 6.5.

The e2e coverage gate exists because unit and integration tests pass while a user-facing flow can still be broken. The `/verify-e2e` log is the only evidence that a real browser walked the real flow against the current commit.

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

Before committing, verify the code review from Step 4 completed with full coverage AND the severity enforcement from Step 5 was satisfied:

| Review Status | Action |
|---------------|--------|
| **All 4 agents returned results AND all MUST-FIX applied AND ≤3 SHOULD-FIX skipped** | Proceed to commit & push |
| **Any MUST-FIX finding was skipped** | **STOP** — present the skipped MUST-FIX finding(s) and ask the user: _"These MUST-FIX findings were not applied: [list]. Proceed anyway? (y/n)"_. Do not push without explicit user approval. |
| **More than 3 SHOULD-FIX findings were skipped** | **STOP** — present all skipped SHOULD-FIX items with their justifications and ask the user: _"[N] SHOULD-FIX findings were skipped (max 3 allowed): [list]. Approve these skips? (y/n)"_. Do not push without explicit user approval. |
| **Any agent failed** (status: `degraded`) | **STOP** — report which review dimensions were missed, show the manual spot-check findings, and ask the user: _"Code review was incomplete ([agent name] failed). Proceed with push anyway? (y/n)"_. Do not push without explicit user approval. |
| **Review-fix loop did not converge** (Step 5 hit max iterations with remaining issues) | **STOP** — list the unresolved issues and ask the user: _"[N] review issues remain unresolved after 2 fix iterations. Proceed with push anyway? (y/n)"_. Do not push without explicit user approval. |

### Commit & Push

Once the code review gate passes and all tests pass:

1. **Branch check**: if on `main`/`master`, create a feature branch first
2. **Stage changes**: `git add -p` — stage only relevant changes, never blindly stage everything
3. **Review staged**: `git status` to confirm
4. **Commit**: `git commit` with message following the format below
5. **Push**: `git push -u origin <branch>`
6. **PR**: if no PR exists for this branch, create one with a summary; if one exists, push to it

Commit message types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`

### Commit Trailer Protocol

Append structured trailers to commit messages to preserve decision context. All trailers are **optional** — include only when relevant to the changes being committed.

| Trailer | When to include |
|---------|-----------------|
| `Constraint:` | External limitations that shaped the implementation (backwards compat, API contracts, perf budgets) |
| `Rejected:` | Alternative approaches considered and why they were dismissed |
| `Not-tested:` | Known gaps in test coverage with reasoning (time, environment, flaky) |
| `Confidence:` | `HIGH` / `MEDIUM` / `LOW` — self-assessed certainty in the change |

**Example:**
```
feat: add token refresh rotation

Implement automatic refresh token rotation on use with 1-hour expiry.

Constraint: Must maintain backwards compat with v2 API clients
Rejected: Considered sliding window expiry, too complex for current auth model
Not-tested: Concurrent refresh race condition under load
Confidence: HIGH
```

**Rules:**
- One trailer per line, no blank lines between trailers
- Place trailers after the commit body, separated by a blank line
- Do not add trailers for trivial commits (typo fixes, formatting)
- `Rejected:` is most valuable — it prevents future engineers from re-exploring dead ends

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

## Step 8 — Deployment Verification

After a successful push, verify that any deployment service watching this branch actually builds the new commit. The session is not "wrapped up" if production is broken.

This step is **conditional** — it only runs when the project has opted in by adding a `## Deployment Targets` section to `CLAUDE.md`. For projects that don't deploy via PaaS, this step is a silent no-op.

### Opt-out

If `/wrap-up-session` was invoked with `--skip-deploy` (for WIP pushes that aren't expected to build cleanly), skip this step entirely and proceed to Done. Note in the Done banner: `Deployments: [SKIPPED — --skip-deploy flag]`.

### Conditional dispatch

1. Read `CLAUDE.md` and check for a section header line matching **exactly** the regex `^## Deployment Targets[[:space:]]*$`. Headings like `## Deployment Verification — Schema Reference (Inactive Example)` are intentionally not matched, so the template repo can document the schema without activating verification.

2. **If the strict-match section exists**: invoke the `/verify-deployment` skill. That skill handles all polling, log fetching, fix iteration, and escalation per its own contract (`.claude/skills/verify-deployment/SKILL.md`). Wait for it to return a per-target outcome.

3. **If the section is missing**: read every runbook in `.claude/deployments/*.md`, collect every entry from each runbook's `detect_files` field, then scan the project root for any matching file or directory. (No service names are hardcoded here — the list of signals is whatever the shipped runbooks declare.)
   - **If a signal file is found**: print a one-line nudge and proceed to Done (do not block):
     ```
     Deploy signals detected (<file>). Run /setup-deployment to enable automatic build verification.
     ```
   - **If no signal file is found**: skip silently and proceed to Done. The project does not deploy via a recognized service.

### Outcome handling

The `/verify-deployment` skill returns one of these overall outcomes. Map each to a Done/STOP action:

| `/verify-deployment` outcome | Action |
|---|---|
| `ALL_GREEN` | Proceed to Done. Record per-target attempt counts in the Done banner. |
| `SKIPPED` (no targets matched current branch, or no `Deployment Targets` section) | Proceed to Done. Banner shows `Deployments: [SKIPPED — reason]`. |
| `AUTH_FAILED` | **STOP** — credentials are missing for one or more targets. Report which `auth_check_command` failed and ask: _"Resolve credentials and re-run /verify-deployment manually, or proceed without verification? (retry/proceed)"_. Do not claim session success on `proceed` without explicit user override. |
| `TIMEOUT` | **STOP** — one or more builds did not resolve within the configured timeout. Report the dashboard URL(s) and ask: _"Check the deployment dashboard manually. Mark as wrapped up anyway? (y/n)"_. Do not claim success on `n`. |
| `CANCELLED` | **STOP** — a build was cancelled (after the user already declined to retry inside `/verify-deployment`). Report and ask: _"A deployment was cancelled. Proceed with wrap-up anyway? (y/n)"_. |
| `FAILED_MAX_ITERATIONS` | **STOP** — `/verify-deployment` exhausted its 3-iteration fix loop. Point the user to `tasks/deploy-report.md` and DO NOT claim session success. The session is not wrapped up while production is failing. |

### Why this lives in wrap-up-session

`/build` does not push, so the deployment service never sees its commits. Verification is strictly a wrap-up concern — the only place in the workflow where code reaches the remote and triggers a real build.

---

## Done

Reply:
```
Session wrapped up.
- Learnings: [N patterns captured / none]
- Tasks: [X completed, Y pending]
- Bugs: [N opened, N closed / no changes]
- Code Review: [PASS / DEGRADED — <agent name> failed / INCOMPLETE — N unresolved issues]
  - MUST-FIX: [N found, N fixed]
  - SHOULD-FIX: [N found, N fixed, N skipped]
  - NITPICK: [N found, skipped]
- Tests: [PASS — suite name] or [FAIL — see above] or [SKIPPED — no test suite]
- E2E coverage: [N user-facing ACs verified via /verify-e2e / NONE — no specs touched / GAP — N user-facing ACs acknowledged without e2e]
- Pushed: [yes / no — reason] [user-approved if review gate was overridden]
- Deployments: [<service> ✓ (N attempts), <service> ✓ (N attempts)] or [<service> ✗ FAILED after 3 attempts — see tasks/deploy-report.md, <service> ✓] or [SKIPPED — reason] or [NONE — no Deployment Targets configured]
```
