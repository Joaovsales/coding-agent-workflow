---
name: debug
description: Systematically investigate, diagnose, and fix bugs using root cause analysis. Use when debugging errors, test failures, runtime issues, or when the user reports a bug. Integrates with bug register, lessons learned, and memory.
argument-hint: "[bug description or error message]"
disable-model-invocation: false
---

# /debug — Bug Investigation & Fix

Systematically investigate and fix bugs using root cause analysis, the `code-debugger` agent, project memory, and the bug register. Iterates with `/loop` to run tests until all regressions are resolved.

## The Iron Law

```
NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST
```

If you haven't completed Phase 1 (Reproduce & Isolate), you cannot propose fixes. Symptom fixes are failure.

## Pre-Flight — Load Context

1. **Read memory and lessons**:
   - Read `.claude/memory.md` for known patterns and architectural context
   - Read `tasks/lessons.md` for past debugging patterns and gotchas
   - Check if the current bug matches any known pattern — apply the known fix first

2. **Read bug register**:
   - Read `tasks/bugs.md` (create from [template](templates/bug-register-template.md) if missing)
   - Check if this bug was previously reported or is related to an existing entry
   - If a match exists, reference the prior investigation to avoid duplicate work

3. **Identify the bug**:
   - If `$ARGUMENTS` provided: use as the bug description
   - If no arguments: ask the user to describe the bug, provide error output, or point to the failing test

## Phase 1 — Reproduce & Isolate

Delegate to the `code-debugger` agent (`model: "sonnet"`):

```
Prompt to code-debugger:
─────────────────────────
Bug report: [description from user or $ARGUMENTS]

Known patterns from memory:
[relevant entries from .claude/memory.md and tasks/lessons.md]

Related bugs from register:
[matching entries from tasks/bugs.md, if any]

Your task:
1. Reproduce the bug — find or write a minimal failing test
2. Read all relevant source files before forming hypotheses
3. Form 2-3 hypotheses ranked by likelihood
4. Rank evidence using the Evidence Strength Hierarchy (see .claude/skills/debug/evidence-hierarchy.md):
   - Level 1 (strongest): Controlled reproduction (test that isolates exact cause)
   - Level 2: Primary artifacts (timestamped logs, git history, metrics)
   - Level 3: Multiple independent sources converging on same explanation
   - Level 4: Single code-path inference (plausible but not uniquely discriminating)
   - Level 5: Circumstantial clues (naming, proximity, timing)
   - Level 6 (weakest): Intuition or analogy
   Label each piece of evidence with its level. Down-rank hypotheses supported only by Level 5-6 evidence.
5. Use binary search / state inspection to isolate the root cause
6. Document the root cause clearly

Return:
- Root cause (1-2 sentences)
- Evidence level supporting the conclusion (Level 1-6)
- Affected files and line numbers
- Minimal reproduction (test or steps)
- Recommended fix approach
```

**If the agent cannot reproduce**: ask the user for more context (logs, steps, environment). Do not guess.

## Phase 2 — Fix

Delegate the fix to the appropriate coding agent (`model: "sonnet"`):

| Bug Location | Agent |
|-------------|-------|
| API, database, auth, business logic | `backend-developer` |
| UI components, styling, client state | `frontend-developer` |
| Cross-cutting or unclear | `code-debugger` |

**Fix delegation prompt must include:**
- The root cause from Phase 1
- The affected files and line numbers
- The minimal reproduction test
- Instruction: "Fix the root cause, not the symptom. Keep the change minimal."
- Instruction: "Ensure the reproduction test now passes."

### Architecture Questioning — After 3 Failed Fixes

**If 3+ fix attempts have failed, STOP and question the architecture:**

Pattern indicating architectural problem:
- Each fix reveals new shared state/coupling/problem in a different place
- Fixes require "massive refactoring" to implement
- Each fix creates new symptoms elsewhere

**STOP and question fundamentals:**
- Is this pattern fundamentally sound?
- Are we "sticking with it through sheer inertia"?
- Should we refactor architecture vs. continue fixing symptoms?

**Discuss with the user before attempting more fixes.**

This is NOT a failed hypothesis — this is a wrong architecture. Do NOT attempt fix #4 without the user's explicit direction.

## Phase 3 — Verify with Loop

After the fix is applied, use `/loop` to run all relevant tests iteratively until clean:

```
/loop 30s Run the test suite relevant to the bug fix.
  Files changed: [list from git diff --name-only].
  1. Run the reproduction test — confirm it PASSES
  2. Run the full test suite — check for regressions
  3. If ALL tests pass: report SUCCESS and stop the loop
  4. If any test FAILS: delegate to code-debugger agent (model: sonnet) with:
     - The failing test output
     - The files changed so far
     - The original root cause context
     Then re-run tests after the fix
  Loop exits when: all tests pass OR 5 iterations reached
```

**If 5 iterations pass without all tests green**: stop and escalate to the user with:
- What was fixed
- What still fails
- Hypotheses for remaining failures

## Phase 4 — Register & Learn

### Update Bug Register (`tasks/bugs.md`)

Add or update the entry using the [bug report template](templates/bug-report-template.md):

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

## User Signals You're Doing It Wrong

Watch for these redirections from the user — they indicate your debugging approach has gone off track:

| User Signal | What It Means |
|-------------|---------------|
| "Is that not happening?" | You assumed without verifying |
| "Will it show us...?" | You should have added evidence gathering |
| "Stop guessing" | You're proposing fixes without understanding root cause |
| "We're stuck?" (frustrated) | Your approach isn't working — change strategy |
| "Try something different" | You're repeating failed approaches |
| "Did you actually check?" | You claimed something without evidence |

**When you see these signals:** STOP. Return to Phase 1 (Reproduce & Isolate). Re-read error messages. Gather fresh evidence.

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "Issue is simple, don't need process" | Simple issues have root causes too. Process is fast for simple bugs. |
| "Emergency, no time for process" | Systematic debugging is FASTER than guess-and-check thrashing. |
| "Just try this first, then investigate" | First fix sets the pattern. Do it right from the start. |
| "I see the problem, let me fix it" | Seeing symptoms ≠ understanding root cause. |
| "One more fix attempt" (after 2+ failures) | 3+ failures = architectural problem. Question pattern, don't fix again. |
| "I'll write test after confirming fix works" | Untested fixes don't stick. Test first proves it. |
| "Multiple fixes at once saves time" | Can't isolate what worked. Causes new bugs. |

## Phase 5 — Report

```
══════════════════════════════════════
  DEBUG COMPLETE — [Bug Summary]
══════════════════════════════════════

🔍 Root Cause: [1-2 sentence explanation]
🛠️  Fix: [what was changed]
📁 Files Changed:
  [git diff --stat summary]

🧪 Tests:
  - Reproduction test: [PASS]
  - Full suite: [N passing, 0 failing]
  - Loop iterations: [N]

📋 Bug Register: [BUG-XXX added/updated in tasks/bugs.md]
📝 Lesson: [captured / skipped — trivial bug]

Ready for /wrap-up-session or continued work.
══════════════════════════════════════
```

## Error Handling

- **Cannot reproduce**: Ask user for more context. Do not proceed without reproduction.
- **Fix introduces new failures**: Revert and try alternative approach. Max 3 alternative approaches before escalating.
- **Loop timeout (5 iterations)**: Escalate to user with full context of what was tried.
- **Multiple root causes**: Fix one at a time. Each gets its own bug register entry and loop verification cycle.

## Key Principles

- **Root cause, not symptoms**: Never patch around the bug. Find and fix the actual cause.
- **Reproduce first**: No fix without a failing test that proves the bug exists.
- **Memory-informed**: Always check lessons and memory before investigating from scratch.
- **Register everything**: Every bug gets tracked. Every non-trivial fix generates a lesson.
- **Loop until clean**: Use `/loop` to iterate on test runs — no manual re-running.
