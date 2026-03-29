---
name: tdd
description: Execute TDD loop for tasks in tasks/todo.md with user checkpoints between steps.
---

# /tdd — TDD Workflow

Execute the TDD loop for tasks in `tasks/todo.md`.

## The Iron Law

```
NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
```

Write code before the test? Delete it. Start over.

**No exceptions:**
- Don't keep it as "reference"
- Don't "adapt" it while writing tests
- Don't look at it
- Delete means delete

Implement fresh from tests. Period.

## Pre-Flight Checks

1. Verify `tasks/todo.md` exists and has a populated plan
   - If not: run `/plan` first
2. Read the spec in `specs/` if available
3. Identify the next unchecked `[ ]` item
4. Read the relevant source files to understand existing code

## TDD Loop (repeat for each task)

For each `[ ] TDD: [Test Name] -> [Impl Detail]`:

### Step 1 — Write the Failing Test
- Place the test in the correct test directory
- The test must be specific: it tests exactly the behavior described in the task
- Do not write the implementation yet

### Step 2 — Show the Failure
- Run the test
- **Confirm it fails with the expected error** (not a setup error or import error)
- If it passes immediately: the test is wrong, or the behavior already exists — investigate before proceeding

### Step 3 — Write Minimal Implementation
- Write the **minimum** code to make the test pass
- No extra features, no optimizations, no "while I'm here" changes

### Step 4 — Show the Pass
- Run the test again
- Confirm it passes
- If it fails: fix only the specific issue; don't restructure

### Step 5 — Refactor
Apply Clean Code principles **without changing behavior**:
- Functions ≤20 LOC, ≤3 parameters
- Meaningful names
- Single abstraction level
- Remove any duplication
- Re-run tests to confirm still passing

### Step 6 — Mark Complete
- Change `[ ]` to `[x]` in `tasks/todo.md`
- Report: "✓ [Test Name] — [one-line description of what was implemented]"

### Step 7 — Check In
- Ask: "Ready for the next task? (y/n)"
- Wait for user confirmation before proceeding

## Red Flags — STOP and Start Over

These signals mean TDD is being violated. Stop immediately and start over with a failing test.

- Code written before test
- Test written after implementation
- Test passes immediately without implementation
- Can't explain why test failed
- Tests added "later"
- Rationalizing "just this once"
- "I already manually tested it"
- "Keep as reference" or "adapt existing code"

**All of these mean: Delete code. Start over with TDD.**

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "Too simple to test" | Simple code breaks. Test takes 30 seconds. |
| "I'll test after" | Tests passing immediately prove nothing. |
| "Need to explore first" | Fine. Throw away exploration, start with TDD. |
| "Test hard = design unclear" | Listen to the test. Hard to test = hard to use. |
| "TDD will slow me down" | TDD is faster than debugging. |
| "Manual test faster" | Manual doesn't prove edge cases. |
| "Existing code has no tests" | You're improving it. Add tests. |
| "Just this once" | That's rationalization. |
| "It's about spirit not ritual" | Tests-after ≠ TDD. You get coverage, lose proof. |
| "Deleting X hours is wasteful" | Sunk cost fallacy. Keeping unverified code is debt. |

## When Stuck

| Problem | Solution |
|---------|---------|
| Don't know how to test | Write the wished-for API. Write the assertion first. Ask the user. |
| Test too complicated | Design too complicated. Simplify the interface. |
| Must mock everything | Code too coupled. Use dependency injection. |
| Test setup is huge | Extract helpers. Still complex? Simplify the design. |

## Testing Anti-Patterns

See `testing-anti-patterns.md` in this directory for common pitfalls with mocks and test utilities.

## Done Criteria

All tasks complete when:
- All `[ ]` items in `tasks/todo.md` are `[x]`
- All tests pass (run the full suite)
- No linting or type errors
- Coverage ≥80% on new code
- Quality gate from `CLAUDE.md` satisfied

## After Completion

Run `/wrap-up-session` or at minimum:
- Run `/learn` to capture any session insights
- Commit with a clear message
