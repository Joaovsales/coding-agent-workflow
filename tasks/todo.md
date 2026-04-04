# Task Plan

> Spec: specs/omc-practices-adoption.md
> Status: Pending user approval
> Note: These are config/doc tasks (skills, agents, hooks). No TDD format — each task creates or edits a markdown/shell file.

## Impact Legend
> **MAJOR** = changes workflow behavior or adds new review gates
> **MODERATE** = new skill or significant edit to existing behavior
> **INCREMENTAL** = small additive edit, no behavior change to existing flows

---

## Tier 1 — New Files (CREATE)

[ ] **MAJOR** — Create Critic agent `.claude/agents/critic.md`
    - 5-phase adversarial protocol: pre-commitment → verification → multi-perspective → gap analysis → synthesis
    - Verdicts: REJECT | REVISE | ACCEPT-WITH-RESERVATIONS | ACCEPT
    - Severity: CRITICAL | MAJOR | MINOR
    - Adversarial mode escalation (any CRITICAL or 3+ MAJOR)
    - READ-ONLY constraint (instruction-level)
    - Model: opus
    - ~120 lines

[ ] **MODERATE** — Create `/deslop` skill `.claude/skills/deslop/SKILL.md`
    - Iron law: "DELETION OVER REWRITING — REMOVE SLOP, DON'T REWORD IT"
    - Detection targets: hedge comments, obvious type annotations, over-documented functions, impossible-case error handling, filler abstractions, verbose logging, empty catch blocks, restating-the-code comments
    - Process: identify files → scan → delete → test → report
    - ~90 lines

[ ] **INCREMENTAL** — Create evidence hierarchy reference doc `.claude/skills/debug/evidence-hierarchy.md`
    - 6-level ranking: controlled reproduction → primary artifacts → converging sources → single inference → circumstantial → intuition
    - When to use each level, examples
    - ~40 lines

## Tier 2 — Edits to `/build` (the MAJOR workflow changes)

[ ] **MODERATE** — Add persistence loop to `/build` Phase 4
    - Replace single-pass spec validation with bounded loop (max 3 rounds)
    - Add repeated-failure detection: same criteria failing 2 rounds → HALT
    - Add round tracking and full status report on final halt
    - Affects lines ~172-183 of current SKILL.md

[ ] **MAJOR** — Add architectural circuit breaker to `/build` error handling
    - After 3 failed code-debugger attempts on same regression: spawn planner (opus) to analyze
    - Planner returns revised approach OR "architecture problem" → halt to user
    - Extends existing "Max 3 fix attempts per regression" block (~lines 218-223)

[ ] **MODERATE** — Integrate `/deslop` into `/build` Phase 3
    - After `/simplify` runs, invoke `/deslop` on same changed files
    - Re-run full test suite after deslop pass
    - Add to Phase 3 description (~lines 160-170)

## Tier 3 — Edits to Other Skills

[ ] **INCREMENTAL** — Add commit trailers to `/wrap-up-session` Step 7
    - Add trailer protocol section: Constraint, Rejected, Not-tested, Confidence
    - Add example commit message with trailers
    - All trailers optional — include only when relevant
    - Edit Step 7 commit section (~lines 262-272)

[ ] **INCREMENTAL** — Add evidence hierarchy to `/debug` Phase 1 prompt
    - Add 6-level evidence ranking to the code-debugger delegation prompt
    - Reference new evidence-hierarchy.md doc
    - Edit Phase 1 delegation prompt (~lines 35-64)

[ ] **INCREMENTAL** — Add pre-mortem step to `/brainstorm`
    - Insert Step 4.5 between "Propose approaches" (Step 4) and "Present design" (Step 5)
    - For each approach: "It's 3 months later and this failed because..." — 3-5 scenarios
    - Add failure scenarios to trade-off table
    - Edit ~lines 62-68

## Tier 4 — Agent Constraints & Hooks

[ ] **MODERATE** — Add READ-ONLY constraint to `code-reviewer.md` and `security-reviewer.md`
    - Add constraint block: "You MUST NOT use Write or Edit tools. Report findings only."
    - Prevents review agents from modifying code they should only evaluate
    - ~8 lines added to each file

[ ] **INCREMENTAL** — Add kill switch to both hooks
    - Add `DISABLE_WORKFLOW_HOOKS=1` early-exit check to top of:
      - `.claude/hooks/session-start.sh`
      - `.claude/hooks/auto-test-runner.sh`
    - 3 lines each

## Tier 5 — Documentation Updates

[ ] **INCREMENTAL** — Update `CLAUDE.md` tables
    - Add `critic` to agents table (model: opus, "Adversarial quality gate — plans, code, specs")
    - Add `/deslop` to skills table ("Detect and remove AI-generated anti-patterns")
    - Add `critic` to model routing rules under planning agents (opus)
    - Add `/deslop` integration note to `/build` description
