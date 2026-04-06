# Task Plan

> Spec: specs/enforce-code-review.md
> Status: Pending confirmation
> Note: These are skill/agent doc edits — no TDD format. Each task modifies a markdown file.

---

## Task 1 — Add severity classification output format to code-reviewer agent

Edit `.claude/agents/code-reviewer.md`:
- Add the `[MUST-FIX]` / `[SHOULD-FIX]` / `[NITPICK]` output format requirement
- Add classification rules (NITPICK = cosmetic only, logic/behavior must be SHOULD-FIX+)
- Update the existing output format section to include severity tags on each finding

## Task 2 — Add severity classification to wrap-up review agent prompts (Step 4)

Edit `.claude/skills/wrap-up-session/SKILL.md` Step 4:
- Add severity classification instructions to the shared preamble for all 4 agents
- Add the structured output format (`[SEVERITY] file:line — description`)
- Add classification rules and the "highest severity wins" dedup rule

## Task 3 — Replace Step 5 reconciliation logic with enforcement tiers

Edit `.claude/skills/wrap-up-session/SKILL.md` Step 5:
- Replace the current "apply most recommendations" soft rule with severity-based enforcement:
  - MUST-FIX: apply, no exceptions
  - SHOULD-FIX: apply by default, ≤3 skips allowed with specific justification
  - NITPICK: auto-skip
- Add the reconciliation table format and rules (when to produce it, what each column must contain)
- Add the "low-ceremony exception" (skip table if ≤3 total findings)
- Add justification quality rule: must reference specific code reason, not generic dismissal

## Task 4 — Add enforcement gates to Step 7

Edit `.claude/skills/wrap-up-session/SKILL.md` Step 7:
- Add two new gate conditions to the Code Review Gate table:
  - Any MUST-FIX skipped → STOP + user prompt
  - >3 SHOULD-FIX skipped → STOP + user prompt
- Update the session summary format to show severity breakdown

## Task 5 — Verify consistency across all changes

Read both modified files end-to-end and verify:
- No contradictions between agent format and skill expectations
- Existing behavior preserved (degraded status, review-fix loop, convergence rule)
- Severity terminology is consistent everywhere
