---
name: debug
description: Systematically investigate, diagnose, and fix bugs using root cause analysis. Use when debugging errors, test failures, runtime issues, or when the user reports a bug. Integrates with bug register, lessons learned, and memory.
argument-hint: "[bug description or error message]"
---

# /debug — Bug Investigation & Fix

Systematically investigate and fix bugs using root cause analysis and the bug register. Iterates with `/loop` to run tests until all regressions are resolved.

## The Iron Law

```
NO FIXES WITHOUT THE ROOT-CAUSE PRELUDE (Phase 0.5) AND REPRODUCTION (Phase 1)
```

You cannot propose fixes until:
1. The **Root-Cause Prelude** (Phase 0.5) has listed 3 candidates and picked one based on disconfirming evidence, AND
2. Phase 1 has produced a minimal failing reproduction.

## Pre-Flight — Load Context

1. **Read memory and lessons**:
   - Read `tasks/memory.md` for known patterns and architectural context
   - Read `tasks/lessons.md` for past debugging patterns and gotchas
   - Check if the current bug matches any known pattern — apply the known fix first

2. **Read bug register**:
   - Read `tasks/bugs.md` (create from template if missing)
   - Check if this bug was previously reported or related to an existing entry

3. **Identify the bug**:
   - If `$ARGUMENTS` provided: use as the bug description
   - If no arguments: ask the user to describe the bug or point to the failing test

## Phase 0.5 — Root-Cause Prelude (MANDATORY before any Edit)

Before touching a single file, post this block:

### Required output — "Top-3 Candidates"

```
Root-Cause Prelude — [bug summary]

Reproduction confirmed: [YES — <how> | NO — need <screenshot/logs/steps>]

Top-3 candidate root causes (ranked by prior likelihood):

1. [hypothesis] — <component/file:line>
   Supporting: [observation + evidence level 1-6]
   Disconfirming test: [one cheap check that would rule this OUT]

2. [hypothesis] — <component/file:line>
   Supporting: [observation + evidence level]
   Disconfirming test: [cheap check]

3. [hypothesis] — <component/file:line>
   Supporting: [observation + evidence level]
   Disconfirming test: [cheap check]

Picked: #<N> because [disconfirming evidence for others is stronger than for this].
```

### Rules

- **Do not skip this block** even for "obvious" bugs.
- **Do not collapse to 1 candidate** until disconfirming checks have been run on the others.
- **If reproduction is `NO`**: STOP and ask the user for a screenshot, log excerpt, or exact repro steps.
- **If the user redirects**: re-run this prelude with their new information.

---

## Phase 1 — Reproduce & Isolate

Read all relevant source files. Find or write a minimal failing test.

Steps:
1. Reproduce the bug — find or write a minimal failing test
2. Read all relevant source files before forming hypotheses
3. Form 2-3 hypotheses ranked by likelihood
4. Rank evidence using the Evidence Strength Hierarchy:
   - Level 1 (strongest): Controlled reproduction
   - Level 2: Primary artifacts (timestamped logs, git history, metrics)
   - Level 3: Multiple independent sources converging on same explanation
   - Level 4: Single code-path inference
   - Level 5: Circumstantial clues
   - Level 6 (weakest): Intuition or analogy
5. Use binary search / state inspection to isolate the root cause
6. Document the root cause clearly

**If cannot reproduce**: ask the user for more context (logs, steps, environment). Do not guess.

---

## Phase 2 — Fix

Apply the fix in the main context, focusing on the root cause:

| Bug Location | Approach |
|-------------|----------|
| API, database, auth, business logic | Backend fix |
| UI components, styling, client state | Frontend fix |
| Cross-cutting or unclear | Direct fix in main context |

**Fix principles**:
- Fix the root cause, not the symptom
- Keep the change minimal
- Ensure the reproduction test passes after the fix

### Architecture Questioning — After 3 Failed Fixes

If 3+ fix attempts have failed, STOP and question the architecture:

Patterns indicating architectural problem:
- Each fix reveals new shared state/coupling in a different place
- Fixes require massive refactoring
- Each fix creates new symptoms elsewhere

**STOP and discuss with the user before attempting more fixes.**

---

## Phase 3 — Verify with Loop

After the fix is applied, use `/loop` to run all relevant tests iteratively until clean:

```
/loop 30s Run the test suite relevant to the bug fix.
  1. Run the reproduction test — confirm it PASSES
  2. Run the full test suite — check for regressions
  3. If ALL tests pass: report SUCCESS and stop the loop
  4. If any test FAILS: fix with code-debugger context, then re-run
  Loop exits when: all tests pass OR 5 iterations reached
```

**If 5 iterations pass without all tests green**: escalate to the user with what was fixed, what still fails, and hypotheses for remaining failures.

---

## Phase 4 — Register & Learn

### Update Bug Register (`tasks/bugs.md`)

| Field | Value |
|-------|-------|
| ID | Next sequential ID (e.g., BUG-007) |
| Date | Today's date |
| Description | One-line summary |
| Root Cause | What actually caused it |
| Fix | What was changed |
| Files | Affected files |
| Status | `fixed — [YYYY-MM-DD]` |
| Regression Test | Name/path of the test that guards against recurrence |

### Capture Lesson

If this bug reveals a new pattern, append to `tasks/lessons.md`:

```markdown
### [Short title of the debugging lesson]
**Context**: [When this pattern applies]
**Pattern**: [What to do or avoid]
**Evidence**: [This bug — BUG-XXX]
```

Skip if the bug was trivial (typo, missing import, etc.).

---

## User Signals You're Doing It Wrong

| User Signal | What It Means |
|-------------|---------------|
| "Is that not happening?" | You assumed without verifying |
| "Stop guessing" | You're proposing fixes without understanding root cause |
| "We're stuck?" | Your approach isn't working — change strategy |
| "Did you actually check?" | You claimed something without evidence |

**When you see these signals**: STOP. Return to Phase 1. Re-read error messages. Gather fresh evidence.

---

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "Issue is simple" | Simple issues have root causes too. Process is fast for simple bugs. |
| "Emergency" | Systematic debugging is faster than guess-and-check. |
| "I see the problem" | Seeing symptoms is not understanding root cause. |
| "One more fix attempt" (after 2+) | 3+ failures = architectural problem. Question pattern. |

---

## Phase 5 — Report

```
══════════════════════════════════════
  DEBUG COMPLETE — [Bug Summary]
══════════════════════════════════════

Root Cause: [1-2 sentence explanation]
Fix: [what was changed]
Files Changed: [git diff --stat summary]

Tests:
  - Reproduction test: [PASS]
  - Full suite: [N passing, 0 failing]
  - Loop iterations: [N]

Bug Register: [BUG-XXX added/updated in tasks/bugs.md]
Lesson: [captured / skipped — trivial bug]

Ready for /wrap-up-session or continued work.
══════════════════════════════════════
```

## Error Handling

- **Cannot reproduce**: Ask user for more context. Do not proceed without reproduction.
- **Fix introduces new failures**: Revert and try alternative approach. Max 3 alternatives before escalating.
- **Loop timeout (5 iterations)**: Escalate to user with full context of what was tried.
- **Multiple root causes**: Fix one at a time. Each gets its own bug register entry and loop verification.

## Claude Code Enhancements

Delegate Phase 1 (Reproduce & Isolate) to `code-debugger` agent (model: sonnet).
Delegate Phase 2 (Fix) to the appropriate coding agent (`backend-developer` or `frontend-developer`, model: sonnet).
Main context handles: Pre-Flight, Phase 0.5 Root-Cause Prelude, Phase 3 loop orchestration, Phase 4 register & learn, Phase 5 report.
