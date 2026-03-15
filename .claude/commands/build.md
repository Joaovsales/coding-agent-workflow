# /build — Autonomous Build Orchestrator

Execute the full plan from `tasks/todo.md` autonomously using TDD with sub-agent delegation.
Bridges the gap between `/plan` (design) and `/wrap-up-session` (close).

## Pre-Flight Checks

1. Verify `tasks/todo.md` exists and has pending `[ ]` tasks
   - If empty or missing: **STOP** — run `/plan` first
2. Read the spec from `specs/` that matches the current plan
   - If no spec found: **STOP** — run `/plan` first
3. Load `tasks/lessons.md` and `.claude/memory.md` for context
4. Identify the project's test runner and build tooling (check `package.json`, `Makefile`, `pyproject.toml`, etc.)
5. Run the full test suite once to establish a **green baseline**
   - If tests fail before you start: fix or flag to user before proceeding

## Phase 1 — Task Execution (TDD Loop)

Process every `[ ]` task in `tasks/todo.md` **without pausing for user confirmation between tasks**.

For each `[ ] TDD: [Test Name] -> [Impl Detail]`:

### Step 1 — Delegate to Sub-Agent

Choose the appropriate sub-agent based on the task:

| Task Type | Agent |
|-----------|-------|
| API, database, auth, business logic | `backend-developer` |
| UI components, styling, client state | `frontend-developer` |
| Cross-cutting or unclear | Use main context directly |

**Delegation prompt must include:**
- The exact task description from `tasks/todo.md`
- The relevant section of the spec from `specs/`
- Paths to related source files
- Instruction: "Follow TDD — write failing test first, then minimal implementation, then refactor"

### Step 2 — Verify Sub-Agent Output

After the sub-agent returns:
1. Run the new test — confirm it **passes**
2. Run the **full test suite** — confirm no regressions
3. If failures: delegate to `code-debugger` agent with failure output and context
4. Repeat until green

### Step 3 — Mark Complete
- Change `[ ]` to `[x]` in `tasks/todo.md`
- Log: `✓ [Test Name] — [one-line summary]`

### Step 4 — Continue
- Move to the next `[ ]` task immediately (no user prompt)
- If a task is blocked by a previous failure, note it and skip to the next unblocked task

## Phase 2 — Full Suite Validation

After all tasks are `[x]`:

1. Run the **complete test suite**
2. Run linter / type checker if configured
3. Confirm all tests pass and no errors
4. If anything fails: delegate to `code-debugger` to fix, then re-run

## Phase 3 — Simplify

Run `/simplify` on all changed files:
1. Identify changed files via `git diff --name-only` (against the baseline before build started)
2. Invoke the `/simplify` skill to review for:
   - Code reuse opportunities
   - Clean Code violations (functions >20 LOC, >3 params, poor naming)
   - SOLID principle violations
   - Unnecessary complexity or dead code
3. Apply suggested improvements
4. Re-run full test suite to confirm simplifications didn't break anything

## Phase 4 — Spec Validation

Compare what was built against the original spec:

1. Re-read `specs/[feature-name].md`
2. Walk through each **Acceptance Criterion**:
   - For each criterion: identify the test(s) that prove it
   - Mark: `✅ [criterion]` or `❌ [criterion] — [what's missing]`
3. If any criterion is `❌`:
   - Create new `[ ]` task in `tasks/todo.md` for the gap
   - Loop back to **Phase 1** for those tasks only
4. When all criteria are `✅`: proceed to report

## Phase 5 — Build Report

Output the final report to the user:

```
══════════════════════════════════════
  BUILD COMPLETE — [Feature Name]
══════════════════════════════════════

📋 Tasks: [X] completed, [Y] added during build
🧪 Tests: [N] total, [N] passing, [0] failing
📐 Spec Validation: [all criteria met / N gaps remain]
🧹 Simplify: [N improvements applied]

Files Changed:
  [git diff --stat summary]

Acceptance Criteria:
  ✅ [criterion 1]
  ✅ [criterion 2]
  ...

Ready for /wrap-up-session or manual QA.
══════════════════════════════════════
```

## Error Handling

- **Sub-agent failure**: Retry once with additional context. If still failing, surface the error to user and pause.
- **Test regression**: Delegate to `code-debugger` with full failure output. Max 3 fix attempts per regression before escalating to user.
- **Spec gap found late**: Add tasks dynamically and loop back. Do not silently skip criteria.
- **Build tool missing**: Ask user for the correct command rather than guessing.

## Key Principles

- **Autonomous**: No user prompts between tasks. Run to completion or until blocked.
- **Observable**: Log every task completion so progress is visible.
- **Safe**: Full test suite after every task. Never let regressions accumulate.
- **Spec-faithful**: The spec is the contract. Build is not done until every acceptance criterion has a passing test.
