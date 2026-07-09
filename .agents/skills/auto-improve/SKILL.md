---
name: auto-improve
description: Autonomous discover-then-fix loop. Surveys backlog, technical debt, test results, performance, and design, ranks the highest-value improvement, implements exactly one with TDD, and opens a PR. Built for daily unattended cloud runs.
argument-hint: "[optional focus area, e.g. 'router' or 'perf']"
harness: universal
---

# /auto-improve — Discover the Work, Ship One Improvement

An unattended cousin of `/auto-push`. Nobody hands you a plan. You **survey the codebase's health**, pick the single highest-value improvement, implement it with TDD, verify no regressions, and open a PR — all in one run, no user prompts.

Designed to run daily on the cloud. It must be conservative: one focused, reviewable change per run beats a sprawling risky diff.

---

## The Iron Law

```
ONE RUN → ONE PR → EXACTLY ONE IMPROVEMENT.
NEVER PUSH TO main/master. PR ONLY.
NO PR IF THE FULL TEST SUITE IS NOT GREEN.
IF NO SAFE IMPROVEMENT EXISTS, LOG FINDINGS TO backlog.md AND OPEN A DOCS-ONLY PR — DO NOT FORCE A CHANGE.
```

The moment you are tempted to bundle a second unrelated fix "while you're here" — stop. Log it to the backlog for the next run.

---

## Pre-Flight — Load Context & Guard Rails

1. **Read the working memory**: `tasks/memory.md`, `tasks/lessons.md`, `tasks/todo.md`, `tasks/bugs.md`, `tasks/backlog.md`. Skip any that don't exist.
2. **Branch safety**: `git rev-parse --abbrev-ref HEAD`. Create a fresh working branch `claude/auto-improve-<date>`; never work on `main`/`master`/`develop`.
3. **Clean tree**: `git status --short`. If unrelated uncommitted changes exist, stash-or-surface but do not silently include them in the PR.
4. **Green baseline**: run the full test suite (see `tasks/memory.md` for the exact runner — this project uses `/home/joaosouto/venv/bin/pytest tests/`). If the baseline is RED, that failing test *becomes* the improvement to fix. Do not build on top of a broken baseline.

If a guard cannot be satisfied and it is not itself the thing to fix, STOP and report — do not proceed.

---

## Phase 1 — DISCOVER (parallel survey)

Dispatch independent read-only sub-agents **in parallel** (one message, multiple Agent calls) to build a candidate list. Each returns findings with `{title, category, file:line, severity, est. effort, risk}`:

| Sub-agent | Model | Charter |
|---|---|---|
| Test health | sonnet | Run full suite + coverage. Report failing tests, flaky tests, coverage gaps < 80%, slowest tests. |
| Design review | sonnet | Run `/software-design-expert-review` on recently changed + core files. Report MUST-FIX / SHOULD-FIX APOSD red flags. |
| Performance | sonnet | Scan hot paths (pipeline stages, router, encoders) for obvious inefficiencies — redundant work, N+1 subprocess calls, unbounded loops. |
| Backlog & bugs | haiku | Read `backlog.md` + `bugs.md`. Surface the highest-priority already-triaged items with enough context to act. |

Do **not** fix anything in this phase. Discovery is read-only.

---

## Phase 2 — SELECT (rank, pick one)

Merge all findings into a single ranked table scored on **value ÷ (effort × risk)**:

- **Value**: user-facing bug > flaky test > perf win > design/maintainability > cosmetic.
- **Effort**: prefer changes shippable within one run as a small, reviewable diff.
- **Risk**: prefer changes with existing test coverage or an easy new test. Deprioritize anything touching public interfaces or lacking a safety net.

Pick **exactly one** item (respect `$ARGUMENTS` as a focus filter if given). Write the ranked list to `tasks/backlog.md` so unpicked candidates persist for future runs. State the pick and the one-line rationale in your output.

If the top candidate's risk is high and coverage is thin → drop to the next safe one. If **nothing** is safely actionable → skip to Phase 5 in "findings-only" mode.

---

## Phase 3 — IMPLEMENT (TDD, delegated)

Route the chosen item to the right existing skill — do not reinvent their logic:

- **Bug / test failure / flaky** → `/debug` (root-cause prelude → reproduction → minimal fix).
- **Refactor / design fix / perf** → `/tdd` (characterization test first if none exists, then the change).
- **Small triaged backlog feature** → `/build` scoped to just that one task.

Follow TDD strictly: failing/characterization test → minimal change → refactor. Keep the diff minimal and on-topic (Minimal Impact rule).

---

## Phase 4 — VERIFY (no regressions)

1. Run the **full** test suite. It must be green. If red and you cannot make it green safely in this run → `git reset` your change, revert to findings-only mode (Phase 5), and log why.
2. Run `/quality-gate` on the changed files (structural quality → anti-patterns → APOSD).
3. Confirm coverage on new/changed code ≥ 80%.

No green suite → no PR. This is non-negotiable.

---

## Phase 5 — SHIP

**Normal mode (a change was made):**
1. Update `tasks/bugs.md` / `tasks/backlog.md` / `tasks/memory.md` to reflect what was fixed and what remains.
2. Run `/wrap-up-session` (commit with a conventional message → push branch → open PR).
3. PR body: what was changed, why it was the highest-value pick, the ranked runner-ups deferred to backlog, and the test/coverage evidence.

**Findings-only mode (nothing safe to change):**
1. Commit the enriched `backlog.md` / `bugs.md` with newly discovered issues (each with enough context to be fixed cold in a later run).
2. Open a docs-only PR titled `chore(backlog): triage from auto-improve <date>`.
3. Never leave the run with zero output — a triaged backlog is a valid, honest result.

---

## Failure & Honesty Rules

- Report outcomes faithfully: if tests fail, say so with the output; if you reverted, say what and why.
- Never mark an improvement "done" on a red suite or a partial implementation.
- One PR per run. If you discover a second urgent issue mid-run, log it — the next scheduled run will pick it up.
