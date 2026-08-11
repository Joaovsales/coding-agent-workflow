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
- Classify every finding on all four axes below

### Finding Model (four axes)

Every finding carries four orthogonal fields. One axis cannot answer another's
question: an urgent finding may be a guess, and a certain finding may be cosmetic.

| Field | Answers | Values |
|-------|---------|--------|
| `severity` | how urgent | `MUST-FIX` / `SHOULD-FIX` / `NITPICK` |
| `confidence` | how sure | `50` / `75` / `100` |
| `autofix_class` | what shape the fix is | `gated_auto` / `manual` / `advisory` |
| `owner` | who acts | `agent` / `human` / `release` |

| Severity | Definition |
|----------|-----------|
| `MUST-FIX` | Correctness, security, silent failures, data loss |
| `SHOULD-FIX` | Quality, maintainability, coverage gaps |
| `NITPICK` | Purely cosmetic — zero logic/behavior impact |

`NITPICK` is ONLY for cosmetic issues. Any logic, architecture, or security finding is `SHOULD-FIX` or higher.

**Confidence anchors** — pick by the behavioral criterion, never by feel:

| Anchor | Criterion |
|--------|-----------|
| `100` | The failure is reproduced, or the defect is visible in the quoted line without inference. |
| `75` | A concrete failing input or state is named and the quoted line plainly permits it, but it was not run. |
| `50` | Pattern-matched, inferred from naming, or dependent on caller behavior that was not read. |

**`owner` values**: `agent` — in this diff's scope, an agent applies it. `human` —
needs a decision or an access an agent does not have. `release` — real but not
blocking this branch.

**Evidence gate**: anchors `75` and `100` require `evidence` — the verbatim motivating
line with `file:line`. A finding at 75+ with no evidence is **demoted to 50**, never
discarded.

**Old-format degrade**: a finding arriving with no `confidence` is handled as anchor
`50` / `autofix_class: manual` — reported, never auto-applied and never discarded.

**Output format for each finding**:
```
[MUST-FIX] conf=100 fix=gated_auto owner=agent file.py:42 — Description and impact
  evidence: `except Exception: pass` (file.py:42)
[SHOULD-FIX] conf=75 fix=manual owner=agent handler.py:120 — Description and impact
  evidence: `return cache.get(k) or {}` (handler.py:120)
[NITPICK] conf=50 fix=advisory owner=release utils.py:30 — Description
```

### Independence disclosure (required)

State in the Step 4 output which mode the four passes ran in — inline and dispatched
runs are otherwise indistinguishable downstream:

- **Dispatched** — each pass ran as a separately dispatched agent (see § *Claude Code
  Enhancements*). Two passes agreeing is independent corroboration and promotes
  `confidence` by exactly one anchor.
- **Inline** — the four passes ran sequentially in this context. Two passes agreeing is
  same-context agreement and **never** promotes, however many passes agree. Name the
  corroboration that was unavailable.

Per `CLAUDE.md` § *Independence Accounting*. Inline is the correct floor, not a failure.

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

### 5.1 — Enforcement (keyed on severity × apply gate)

**Apply gate**: auto-apply a finding only when `autofix_class: gated_auto` **and**
`confidence >= 75`. A finding that fails the gate is reported, not applied — including
a `MUST-FIX`. Severity says how much it matters; the gate says whether an agent is
entitled to change code unattended. They are different questions.

| Severity | Clears the apply gate | Fails the apply gate |
|----------|----------------------|----------------------|
| `MUST-FIX` | Apply immediately. Cannot be skipped. | At `conf >= 75`: **blocking** — do not push, escalate to `owner`. At `conf 50`: report only, does not block. |
| `SHOULD-FIX` | Apply by default. May skip ≤3 total with code-specific justification. | Report. Does not block the push. |
| `NITPICK` | Auto-skip. | Auto-skip. |

A `MUST-FIX` at `conf 50` is a suspicion, not a defect — blocking a push on it would
stall an unattended loop on noise. A `MUST-FIX` at `conf >= 75` that an agent is not
entitled to auto-fix is exactly the case a human must see, so it blocks.

**On disagreement** between passes, synthesis takes the **more conservative**
`autofix_class` — `advisory` is more conservative than `manual`, which is more
conservative than `gated_auto`. Synthesis never widens.

Same-context agreement between passes never promotes `confidence` (§ *Independence
disclosure* in Step 4).

### 5.2 — Review Reconciliation Table

After processing all findings (skip if total findings ≤ 3):

```markdown
### Review Reconciliation

Review mode: DISPATCHED / INLINE — [when inline: corroboration unavailable, no promotion]

| # | Pass | Severity | Conf | Fix | Owner | Finding | Action | Justification |
|---|------|----------|------|-----|-------|---------|--------|---------------|
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
- Code Review: [PASS / INCOMPLETE — N unresolved issues] — mode: [DISPATCHED / INLINE]
  - MUST-FIX: [N found, N fixed, N reported below the apply gate]
  - SHOULD-FIX: [N found, N fixed, N skipped]
  - NITPICK: [N found, skipped]
  - Demoted: [N at 75+ with no file:line evidence → anchor 50]
  - Promotions: [N on independent corroboration / none — inline run]
- Security Scan: [PASS / N issues addressed]
- Tests: [PASS — suite name] or [FAIL] or [SKIPPED — no suite]
- E2E coverage: [N user-facing ACs verified / NONE / GAP — N acknowledged]
- Pushed: [yes / no — reason]
- Deployments: [results or SKIPPED / NONE]
```

## Claude Code Enhancements

### Step 4 — Parallel Code Review
Launch all 4 review passes as parallel agents in a SINGLE message with multiple Agent tool calls.
`code-reviewer` and `critic` are **ceiling**-tier: pass no `model` override, so they
inherit the session model (`CLAUDE.md` § *Model Routing*).

This is the **dispatched** mode for the Step 4 independence disclosure: four separately
dispatched contexts, so agreement between them is independent corroboration.

Agent assignments:
- Agent 1: `code-reviewer` — Codebase Consistency (Pass 1)
- Agent 2: `code-reviewer` — Defensive Code Audit (Pass 2)
- Agent 3: `code-reviewer` — Test Coverage (Pass 3)
- Agent 4: `critic` — Adversarial Critic (Pass 4)
