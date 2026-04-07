# Task Plan

> Spec: specs/enforce-code-review.md
> Status: Complete

---

## Task 1 — Add severity classification output format to code-reviewer agent

[x] Edit `.claude/agents/code-reviewer.md`: added `MUST-FIX` / `SHOULD-FIX` / `NITPICK` severity tags, classification rules, and structured output format

## Task 2 — Add severity classification to wrap-up review agent prompts (Step 4)

[x] Edit `.claude/skills/wrap-up-session/SKILL.md` Step 4: added severity classification section with tags, rules, and output format for all 4 agents

## Task 3 — Replace Step 5 reconciliation logic with enforcement tiers

[x] Edit `.claude/skills/wrap-up-session/SKILL.md` Step 5: replaced soft rules with severity-based enforcement (5.1), reconciliation table (5.2), and renumbered review-fix loop (5.3)

## Task 4 — Add enforcement gates to Step 7 + update summary format

[x] Edit `.claude/skills/wrap-up-session/SKILL.md` Step 7: added MUST-FIX and SHOULD-FIX gate conditions; updated session summary to show severity breakdown

## Task 5 — Verify consistency across all changes

[x] Read both files end-to-end: severity terminology consistent, output format aligned, existing behavior preserved, no contradictions
