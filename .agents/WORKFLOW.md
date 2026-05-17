# Shared Workflow — Harness-Neutral

Applies to all sessions regardless of harness (Claude Code, Pi, or other).

---

## Session Start Checklist

1. Read `.claude/memory.md` for persistent patterns and lessons
2. Check `tasks/todo.md` for in-progress work
3. Check `tasks/lessons.md` for self-improvement notes

---

## Workflow: PRD → Plan → Build → Wrap Up

### 0. PRD (Greenfield Projects Only)
Run `/prd` to produce:
- `specs/prd-<name>.md` — Product Requirements Document
- `tasks/backlog.md` — ordered work items by phase
- `tasks/project-context.md` — compressed agent briefing (auto-updated)

### 1. Spec First
For every non-trivial feature, create a formal spec before writing code:
- Create `specs/[feature-name].md`: Behavior / Inputs / Outputs / Edge Cases / Acceptance Criteria
- Use `/plan` to run this interactively

### 2. Plan Before Code (Hard Gate)
- Write a step-by-step plan to `tasks/todo.md` before touching source code
- Each task format: `[ ] TDD: [Test Name] -> [Impl Detail]`
- Ask user: "Does this plan meet your requirements? Confirm with 'y' to begin."
- Do not proceed without user confirmation

### 3. Build (Autonomous Execution)
Run `/build` to execute the plan:
- Each task follows TDD: failing test → minimal impl → refactor → mark `[x]`
- Full test suite after every task (no regressions)
- Runs `/quality-gate` on all changed files when tasks are done
- Validates every acceptance criterion from the spec
- No user prompts between tasks

### 4. Wrap Up
After corrections: note root cause in `tasks/lessons.md`.
At session end: run `/wrap-up-session` to sync learnings, run tests, and push.

---

## Review Gate Taxonomy

```
Layer 1 — Per-task in /build       spec compliance check (inline) + tests pass
Layer 2 — Post-build quality-gate  Phase 1: structural quality (simplify)
                                   Phase 2: AI anti-patterns (deslop)
                                   Phase 3: design quality (APOSD)
Layer 3 — Pre-push in /wrap-up     codebase consistency, defensive audit,
                                   test coverage, adversarial critic
```

---

## Core Principles

**Never Guess — Verify**
Use Read tools before editing. Check file existence. Validate from actual content.

**Clean Code**
- Functions ≤20 LOC, ≤3 parameters
- Single abstraction level per function
- Meaningful names — no abbreviations, no `data`, `info`, `manager`
- DRY and KISS

**Minimal Impact**
Only touch what is necessary. No unsolicited refactors. No proactive documentation.

**No Silent Failures**
Explicit errors only. No `except: pass`. No fallback values hiding broken assumptions.

**File & Git Hygiene**
Prefer editing existing files. Never skip git hooks. Atomic, descriptive commits.

---

## Key Directories

```
.agents/skills/            → Canonical skills (harness-neutral)
.claude/agents/            → Sub-agents (Claude Code only)
.claude/skills/            → Backwards-compat copy (installed alongside .agents/)
.claude/hooks/             → Lifecycle automation scripts
specs/                     → Feature specifications
tasks/todo.md              → Active task plan
tasks/backlog.md           → Ordered work items (from /prd)
tasks/project-context.md   → Compressed agent briefing (auto-generated)
tasks/bugs.md              → Bug register
tasks/lessons.md           → Self-improvement patterns
tasks/checkpoint.md        → Session snapshots
```
