# Wrap Up Session

Close the current coding session with parallel quality checks, testing, fixes, and a clean commit.

## Step 1: Parallel Code Review (4 agents)

Launch these four agents simultaneously using the Task tool. Each agent should:
- Run `git diff --name-only main...HEAD` to scope review to changed files only
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

## Step 2: Run Tests

Detect the project's test stack and run all applicable test suites:

1. **Discover test commands** -- read `package.json`, `Makefile`, `pyproject.toml`, `TESTING.md`, or equivalent
2. **Run in order**: lint/typecheck, unit tests, integration tests, e2e tests
3. **Capture results** -- log pass/fail counts and any failures

If `TESTING.md` exists, follow its instructions for running the test suite.

## Step 3: Reconcile & Apply Fixes

When agents return their findings:

1. **Apply most recommendations** -- if on the fence, do it
2. **Resolve conflicts** -- prefer reusing existing code (Agent 1) over extracting new abstractions (Agent 2)
3. **Track skipped items** -- only skip with strong justification; note the reason
4. **Aim for convergence** -- on follow-up passes, if agents find only minor/stylistic issues, note this and recommend proceeding

## Step 4: Re-test After Fixes

Re-run the full test suite from Step 2. All tests must pass before proceeding.

If tests fail:
- Fix the root cause (not a workaround)
- Re-run tests
- Max 2 fix attempts; if still failing, report to user with details

## Step 5: Update Testing Documentation

If `TESTING.md` exists in the project:
- Add any new test commands or test files created
- Update coverage notes if test coverage changed significantly
- Document any new testing patterns introduced

## Step 6: Update Project Context Document

Find or create a brief context document at the project root (e.g., `PROJECT_CONTEXT.md` or equivalent):
- Keep it under 50 lines
- Summarize: tech stack, architecture, key directories, how to run/test
- Purpose: give future coding agents fast onboarding without context bloat
- Only update if the session introduced meaningful structural changes

## Step 7: Commit & Push

1. **Branch check**: if on `main`/`master`, create a feature branch first
2. **Stage all changes** including test and doc updates
3. **Commit** with a clear message summarizing the session's work
4. **Push** to remote
5. **PR**: if no PR exists for this branch, create one with a summary; if one exists, push to it

## Step 8: Session Summary

Provide a concise summary:

- **Changes Applied**: what each review agent found and what was fixed
- **Skipped Recommendations**: what was skipped and why
- **Test Results**: pass/fail counts, what was verified
- **Unable to Test**: anything that needs manual verification
- **Another Pass?**: if this pass made substantial changes, recommend re-running; if minor, recommend merging
