# Task Plan

> Spec: specs/omc-practices-adoption.md
> Status: Complete
> Note: These are config/doc tasks (skills, agents, hooks). No TDD format — each task creates or edits a markdown/shell file.

## Impact Legend
> **MAJOR** = changes workflow behavior or adds new review gates
> **MODERATE** = new skill or significant edit to existing behavior
> **INCREMENTAL** = small additive edit, no behavior change to existing flows

---

## Tier 1 — New Files (CREATE)

[x] **MAJOR** — Create Critic agent `.claude/agents/critic.md`
[x] **MODERATE** — Create `/deslop` skill `.claude/skills/deslop/SKILL.md`
[x] **INCREMENTAL** — Create evidence hierarchy reference doc `.claude/skills/debug/evidence-hierarchy.md`

## Tier 2 — Edits to `/build` (the MAJOR workflow changes)

[x] **MODERATE** — Add persistence loop to `/build` Phase 4
[x] **MAJOR** — Add architectural circuit breaker to `/build` error handling
[x] **MODERATE** — Integrate `/deslop` into `/build` Phase 3

## Tier 3 — Edits to Other Skills

[x] **INCREMENTAL** — Add commit trailers to `/wrap-up-session` Step 7
[x] **INCREMENTAL** — Add evidence hierarchy to `/debug` Phase 1 prompt
[x] **INCREMENTAL** — Add pre-mortem step to `/brainstorm`

## Tier 4 — Agent Constraints & Hooks

[x] **MODERATE** — Add READ-ONLY constraint to `code-reviewer.md` and `security-reviewer.md`
[x] **INCREMENTAL** — Add kill switch to both hooks

## Tier 5 — Documentation Updates

[x] **INCREMENTAL** — Update `CLAUDE.md` tables
