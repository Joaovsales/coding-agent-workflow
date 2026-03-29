---
name: build
description: Execute the task plan from tasks/todo.md autonomously using TDD with sub-agent delegation. Use after /plan is confirmed.
disable-model-invocation: true
---

# /build — Autonomous Build Orchestrator

Execute the full plan from `tasks/todo.md` autonomously using TDD with sub-agent delegation.
Bridges the gap between `/plan` (design) and `/wrap-up-session` (close).

## Model Routing

**This command MUST use `model: sonnet` for all sub-agent delegations.**
- All coding agents (`backend-developer`, `frontend-developer`, `code-debugger`, `code-reviewer`) MUST be invoked with `model: "sonnet"`
- For codebase searches and file exploration, use `model: "haiku"` via the Explore agent
- Never use `opus` during build — it is reserved for planning and architecture

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

### Parallel Dispatch Assessment

Before processing tasks sequentially, assess if any can run in parallel:

**Identify independent tasks:** Tasks are independent when:
- They modify different files/modules
- They have no data dependencies on each other
- Fixing one doesn't affect the other
- They don't share state or resources

**If 2+ independent tasks found:**
1. Group tasks by independence (tasks that touch different subsystems)
2. Dispatch one sub-agent per independent group using the Agent tool
3. Each agent gets a focused, self-contained prompt with:
   - Specific scope: exact task(s) and files
   - Clear goal: what tests to write and pass
   - Constraints: "Do NOT modify files outside your scope"
   - Expected output: summary of changes and test results
4. Wait for all agents to return
5. Review results for conflicts (agents editing same files)
6. Run full test suite to verify all changes integrate cleanly
7. If conflicts: resolve manually, then re-run tests

**If tasks are sequential/dependent:** Process one at a time (Steps 1-4 below).

**Decision guide:**
| Situation | Approach |
|-----------|----------|
| Tasks touch different files/modules | Parallel dispatch |
| Tasks depend on each other's output | Sequential (Steps 1-4) |
| Shared state between tasks | Sequential (Steps 1-4) |
| Unclear dependencies | Sequential (safer) |

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

### Step 2 — Two-Stage Review

After the sub-agent returns, run two sequential reviews before proceeding:

#### Stage 1: Spec Compliance Review

Dispatch a `code-reviewer` agent (`model: "sonnet"`) with:
- The original task description from `tasks/todo.md`
- The relevant acceptance criteria from `specs/`
- The git diff of changes made by the sub-agent

**Review prompt:**
> "Review this implementation against the spec. Check:
> 1. Does it implement exactly what was specified? Nothing added, nothing missing.
> 2. Are all acceptance criteria addressed?
> 3. Are there deviations from the spec? If so, are they justified improvements or problematic departures?
> Report: APPROVED or CHANGES NEEDED with specific items."

**If CHANGES NEEDED:** Send feedback back to the original sub-agent for fixes, then re-review.

#### Stage 2: Code Quality Review

Dispatch a second `code-reviewer` agent (`model: "sonnet"`) with:
- The git diff of changes
- The project's coding standards from CLAUDE.md

**Review prompt:**
> "Review this implementation for code quality:
> 1. Clean Code: functions ≤20 LOC, ≤3 params, meaningful names, single abstraction level
> 2. SOLID principles adherence
> 3. Test quality: real assertions, no mock-testing, edge cases covered
> 4. Security: no injection vectors, proper input validation at boundaries
> 5. Performance: no N+1 patterns, unnecessary allocations, or redundant computations
> Report: APPROVED or CHANGES NEEDED with categorized issues (Critical / Important / Suggestion)."

**If Critical or Important issues found:** Fix before proceeding.
**If only Suggestions:** Note them and proceed.

#### Verification Gate

After both reviews pass:
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
