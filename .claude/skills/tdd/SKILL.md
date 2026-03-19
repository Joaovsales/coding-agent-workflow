---
name: tdd
description: Execute TDD loop for tasks in tasks/todo.md with user checkpoints between steps.
---

# /tdd — TDD Workflow

Execute the TDD loop for tasks in `tasks/todo.md`.

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
