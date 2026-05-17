---
name: software-design-expert-review
description: Run a focused APOSD design review on recently changed files. Scans for the 10 red flags from 'A Philosophy of Software Design', maps severities to MUST-FIX / SHOULD-FIX / NITPICK, and produces a GO / HOLD / STOP verdict. Can be invoked manually or called by /build Phase 3.5.
compatibility: >
  Requires a git repository. Works with any language. No external dependencies.
  When invoked manually: scopes to uncommitted / recently touched files by default.
  Supports --file and --scope flags for narrowing.
---

# /software-design-expert-review — APOSD Design Quality Gate

Run a focused structural review based on *A Philosophy of Software Design* by John Ousterhout. This skill is **not** a general code review — it hunts specifically for depth, abstraction, coupling, and hidden-complexity red flags.

**When to run:**
- Manually: `/skill:software-design-expert-review` after you want a design-only sanity check
- Automatically: `/build` Phase 3.5 invokes this gate on every changed file before declaring the build complete
- After refactors: when you've restructured modules and want to verify you didn't create shallow abstractions

**How to run:**
```
/skill:software-design-expert-review              # Review all changed files in current branch
/skill:software-design-expert-review --file path  # Scope to one file
/skill:software-design-expert-review --scope auth # Scope to functional area (grep + diff)
```

---

## Phase 1 — Gather Evidence

1. Determine changed files:
   - If `--file` provided: use that file only.
   - If `--scope` provided: `git diff --name-only <base>..HEAD | grep -i <scope>`.
   - Default: `git diff --name-only <base>..HEAD`.
2. For each file, capture approximate size and nature (new / modified / deleted).
3. Note any new file with **no public interface tests** — flag as `SHOULD-FIX` immediately.

**Base branch detection** (same rules as `/wrap-up-session`):
- `main` → `master` → `develop` → `git merge-base HEAD origin/HEAD`
- Store as `<base-branch>` for all subsequent steps.

---

## Phase 2 — Dispatch APOSD Reviewer Agent

For each changed file (or grouped batch if <5 files), dispatch the `software-design-expert-review` agent (`model: sonnet`) in a single tool call. Pass:
- The git diff for the file(s)
- Absolute paths of the files
- The instruction: "Review ONLY these changed files. Output findings in [MUST-FIX] / [SHOULD-FIX] / [NITPICK] format only."

### Agent Failure Handling
- If the agent errors or returns unparseable output: log the failure, label review status `degraded`, and proceed to Phase 3 with a warning.

---

## Phase 3 — Severity Reconciliation

Parse agent output. Every finding must have:
- **Tag**: `[MUST-FIX]`, `[SHOULD-FIX]`, or `[NITPICK]`
- **Location**: `file:line`
- **Red Flag ID**: `R1`–`R10`
- **Impact**: one sentence

Deduplicate identical findings (same file:line + same root cause). Keep the highest severity.

---

## Phase 4 — Verdict & Gate Logic

```
🟢 GO   — Zero MUST-FIX, zero SHOULD-FIX, or only NITPICKs.
🟡 HOLD — No MUST-FIX, but >0 and ≤3 SHOULD-FIX found. Log them as design debt and proceed.
🔴 STOP — Any MUST-FIX found, or >3 SHOULD-FIX found.
```

**STOP behavior (when invoked by /build):**
- Halt the build immediately. Do NOT proceed to Phase 4 (Spec Validation).
- Present the user with a terse table of MUST-FIX findings and ask:
  > _"Build halted: [N] MUST-FIX APOSD findings detected. Fix them now and retry, or acknowledge and proceed? (fix/acknowledge)"_
- On `acknowledge`: log all findings in `tasks/design-debt.md` (create if absent) with date + commit short-sha, then downgrade verdict to `HOLD` and proceed.
- On `fix`: convert findings into `[ ]` tasks appended to `tasks/todo.md`, return to /build Phase 1 for those tasks only. After fixes, the build must re-run **only this Phase 3.5** (not full Phase 1–3).

**STOP behavior (when invoked manually):**
- Print the findings table and STOP. User decides whether to fix or proceed independently.

**HOLD behavior:**
- Print all SHOULD-FIX items under a `Design Debt:` section.
- Proceed to the next phase. No user prompt for ≤3 SHOULD-FIX.

---

## Output Format

When invoked manually, produce:

```markdown
# APOSD Design Review — <scope>

## Evidence
| File | Δ | Nature |
|------|---|--------|

## Findings
| # | Tag | Flag | Location | Impact | Suggestion |
|---|-----|------|----------|--------|------------|

## Verdict
🟢 GO / 🟡 HOLD / 🔴 STOP

## Design Debt (if HOLD or acknowledged STOP)
| File:Line | Flag | Issue |
|-----------|------|-------|
```

When invoked by `/build`, emit only:
```
APOSD GATE: [PASS / HOLD / STOP]
Findings: [N MUST-FIX, N SHOULD-FIX, N NITPICK]
```

---

## References

- `.claude/skills/software-design-expert-learn/references/principles.md` — Full APOSD principles catalog
- `.claude/agents/software-design-expert-review.md` — The agent prompt and red flag definitions

## Confidence Note for Builders

> "The best module is one where the interface is so simple that the implementation could be completely rewritten without callers noticing."

This skill enforces that standard before a build is declared structurally sound.
