---
name: build
description: Execute the task plan from tasks/todo.md autonomously using TDD with sub-agent delegation. Use after /plan is confirmed.
argument-hint: ""
---

# /build — Autonomous Build Orchestrator

Execute the full plan from `tasks/todo.md` autonomously using TDD.
Bridges the gap between `/plan` (design) and `/wrap-up-session` (close).

## Pre-Flight Checks

1. Verify `tasks/todo.md` exists and has pending `[ ]` tasks
   - If empty or missing: **STOP** — run `/plan` first
2. Read the spec from `specs/` that matches the current plan
   - If no spec found: **STOP** — run `/plan` first
3. Load `tasks/lessons.md` and `tasks/memory.md` for context
4. Load `tasks/project-context.md` if it exists (architecture, protection list, conventions)
5. Identify the project's test runner (check `package.json`, `Makefile`, `pyproject.toml`, etc.)
6. Run the full test suite once to establish a **green baseline**
   - If tests fail before you start: fix or flag to user before proceeding
7. **Classify acceptance criteria** — for each AC in the spec, tag as `logic | integration | user-facing`:
   | AC type | Signals |
   |---------|---------|
   | `logic` | Pure functions, validators, transforms, utilities — no I/O |
   | `integration` | API endpoints, DB queries, service-to-service calls, background jobs |
   | `user-facing` | Auth flows, form submissions, navigation, UI state, anything a user sees or clicks |
   When an AC mixes types, classify by the highest tier (`user-facing` > `integration` > `logic`).

## Phase 1 — Task Execution (TDD Loop)

Process every `[ ]` task in `tasks/todo.md` without pausing for user confirmation between tasks.

### Parallel Dispatch Assessment

Before processing tasks sequentially, assess if any can run in parallel.

**Tasks are independent when**:
- They modify different files/modules
- They have no data dependencies on each other
- They don't share state or resources

**If 2+ independent tasks found**:
1. Group tasks by independence
2. Dispatch one sub-agent per independent group
3. Wait for all to return; check for file conflicts
4. Run full test suite to verify all changes integrate cleanly

**If tasks are sequential/dependent**: process one at a time (Steps 1–4 below).

### Step 1 — Implement the Task

Choose the agent or approach based on task type:

| Task Type | Agent |
|-----------|-------|
| API, database, auth, business logic | `backend-developer` |
| UI components, styling, client state | `frontend-developer` |
| Cross-cutting or unclear | Main context directly |

**Delegation prompt must include**:
- The exact task description from `tasks/todo.md`
- The relevant spec section from `specs/`
- Paths to related source files
- Instruction: "Follow TDD — write failing test first, then minimal implementation, then refactor"

**Role-based context injection from `tasks/project-context.md`** (if it exists):

| Agent | Sections to include |
|-------|---------------------|
| `backend-developer` | `[ARCHITECTURE]` + `[PROTECTION]` + relevant functional requirements |
| `frontend-developer` | `[ARCHITECTURE]` + `[PROTECTION]` + `[CONVENTIONS]` + relevant requirements |
| `code-debugger` | Failing test + relevant code only |

Do not pass the full project-context to every agent — extract only relevant sections.

### Step 2 — Per-Task Spec Compliance Check (inline, no agent)

After implementation, run this check inline in the main context:

1. Re-read the task's acceptance criteria from `specs/`
2. Run `git diff --cached` (or `git diff HEAD`) to see the actual changes
3. Report:
   - **PASS** if the change addresses the acceptance criteria
   - **MISMATCHES** — list each specific gap between spec and implementation

If mismatches found: send feedback to the implementing agent for fixes, then re-check.

### Step 3 — Run Tests

1. Run the new test — confirm it **passes**
2. Run the **full test suite** — confirm no regressions
3. If failures: fix with `code-debugger` agent and full failure context
4. Repeat until green

### Step 4 — Mark Complete and Continue

- Change `[ ]` to `[x]` in `tasks/todo.md`
- Log: `✓ [Test Name] — [one-line summary]`
- Move to the next `[ ]` task immediately (no user prompt)
- If a task is blocked by a previous failure, note it and skip to the next unblocked task

## Phase 2 — Full Suite Validation

After all tasks are `[x]`:

1. Run the **complete test suite**
2. Run linter / type checker if configured
3. Confirm all tests pass and no errors
4. If anything fails: fix with `code-debugger`, then re-run

## Phase 3 — Quality Gate

Invoke `/quality-gate` on all files changed during this build:

1. Identify changed files via `git diff --name-only` (against baseline before build started)
2. Run `/quality-gate` — this executes all 3 phases (structural, AI anti-patterns, APOSD design)
3. Re-run full test suite after quality gate completes to confirm no regressions

## Phase 4 — Spec Validation (Persistence Loop)

Compare what was built against the original spec. Loops up to 3 rounds.

```
max_rounds: 3
previous_failures: []
```

### Evidence Required by AC Type

| AC type | Evidence required |
|---------|-------------------|
| `logic` | Unit test passes (covers the function in isolation) |
| `integration` | Integration test passes (real API/DB/service interaction) |
| `user-facing` | E2E walkthrough via `/verify --scope e2e` — entry in `tasks/e2e-log.md` for current commit short-sha |

If ANY AC is classified `user-facing`, invoke `/verify --scope e2e` before declaring Phase 4 complete.

**For each round**:

1. Re-read `specs/[feature-name].md`
2. For every `user-facing` AC, invoke `/verify --scope e2e` (skip if already run this round with PASS entry for current commit)
3. Walk through each AC:
   - Mark: `✅` (unit/integration test), `✅✅` (e2e walkthrough), `❌` (missing)
4. **If all criteria are `✅` or `✅✅`**: proceed to Phase 5
5. **If any criterion is `❌`**:
   - Compare against `previous_failures`
   - **Same failures as last round** → HALT with circular-fix message, escalate to user
   - **Different failures** → record in `previous_failures`, add tasks, loop to Phase 1
6. **After round 3 with remaining `❌`**: HALT with full status report, escalate to user

## Phase 4.5 — Ambiguity Batch Review

Per `.claude/project.md` § *Ambiguity Protocol*, sub-agents emit a single line
when they hit a question whose answer changes the implementation:

```
[AMBIGUITY] <description> | options: A) ... B) ... | picked: <letter> | reason: ...
```

After Phase 4 passes:

1. **Grep every agent output captured this build** for lines starting with `[AMBIGUITY]`.
2. If zero hits: skip this phase silently.
3. If one or more hits: surface them to the user as a single batch in this format:

   ```
   ⚠ Ambiguities resolved during build (please confirm):

   1. <description>
      Picked: <letter> (<reason>)
      Alternatives: <other options>
      Touched: <file paths>
   2. ...
   ```

4. **Do not block** on user response — proceed to Phase 5. The batch is informational;
   the user can request changes in a follow-up turn if a pick was wrong.

## Phase 5 — Backlog Update

If `tasks/backlog.md` exists:
1. Identify which backlog item this build corresponds to
2. Mark the item as `[x]` in `tasks/backlog.md`
3. Update `tasks/project-context.md` `[CURRENT-PHASE]` if the phase is now complete

## Phase 6 — Build Report

End your turn with this report populated from **real command output**:

### Required persistence proofs (run these, paste their output)

1. `git status --short`
2. `git log --oneline <base>..HEAD`
3. `ls specs/ | grep <feature>`
4. `grep -c '^\[x\]' tasks/todo.md` vs `grep -c '^\[ \]' tasks/todo.md`

```
══════════════════════════════════════
  BUILD COMPLETE — [Feature Name]
══════════════════════════════════════

Tasks: [X] completed, [Y] added during build
Tests: [N] total, [N] passing, [0] failing
Spec Validation: [all criteria met / N gaps remain]
Quality Gate: [N improvements applied]

Files on disk (persistence proof):
  Spec: /absolute/path/to/specs/<feature-name>.md
  Plan: /absolute/path/to/tasks/todo.md
  Source changes: [git diff --stat summary]

Git state:
  Branch: <branch>
  Commits this build: [N]
  Uncommitted changes: [Y/N]
  Pushed: [NOT YET — /build does not push. /wrap-up-session handles push.]

Acceptance Criteria:
  ✅✅ [user-facing criterion — e2e log entry @ <short-sha>]
  ✅   [logic/integration criterion — test: <test-name>]

Next: /wrap-up-session
══════════════════════════════════════
```

### Forbidden completion patterns

- Claiming "build complete" without the persistence proof block
- Stating a file was "created" or "updated" without showing its absolute path
- Omitting the `Pushed:` line

## Error Handling

- **Implementation failure**: Retry once with additional context. If still failing, surface to user and pause.
- **Test regression**: Fix with `code-debugger`. Max 3 fix attempts per regression (see circuit breaker).
- **Spec gap found late**: Add tasks dynamically and loop back. Do not silently skip criteria.
- **Build tool missing**: Ask user for the correct command rather than guessing.

### Architectural Circuit Breaker

When `code-debugger` fails **3 times on the same regression**:

1. **STOP** fixing symptoms.
2. **HALT and escalate to user** with:
   - The failing test output (all 3 attempts)
   - The files changed across all attempts
   - The original spec and task description
3. Do NOT attempt fix #4 without explicit user direction.

```
⛔ HALTED — Architectural circuit breaker triggered
Regression: [test name]
3 fix attempts failed. User input required before proceeding.
```

## Key Principles

- **Autonomous**: No user prompts between tasks. Run to completion or until blocked.
- **Observable**: Log every task completion so progress is visible.
- **Safe**: Full test suite after every task. Never let regressions accumulate.
- **Spec-faithful**: The spec is the contract. Build is not done until every AC has evidence.

## Claude Code Enhancements

### Task Dispatch
Dispatch sub-agents (`backend-developer` or `frontend-developer`, model: sonnet) for each task in Phase 1.
For 2+ independent tasks: dispatch in parallel (multiple Agent tool calls in a single message).

### Per-Task Review
Phase 1 Step 2 remains inline (no agent). Spec compliance check is a read + compare, not a coding task.

### Quality Gate
In Phase 3, invoke `/quality-gate` normally. The quality-gate skill dispatches `software-design-expert-review` for Phase 3 on Claude Code.
