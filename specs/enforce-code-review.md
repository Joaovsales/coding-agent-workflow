# Spec: Enforce Code Review in Wrap-Up Session

## Problem

During `/wrap-up-session`, the 4 parallel code review agents return findings, but the main agent can silently skip most of them by labeling them "refactoring suggestions." In one observed session, 11 of 12 findings were skipped with no user approval required. The current rules say "apply most recommendations" and "only skip with strong justification," but these are too subjective — the agent decides what counts as "strong."

## Behavior

Introduce a **Structured Review Contract** with three mechanisms:

1. **Severity Classification** — Every review finding gets a severity level
2. **Reconciliation Table** — A structured audit trail of what was fixed vs skipped
3. **Enforcement Gates** — Hard stops that prevent pushing when too many findings are skipped

## Design

### Severity Tiers

| Severity | Definition | Examples | Action |
|----------|-----------|----------|--------|
| `MUST-FIX` | Correctness, security, silent failures | Bugs, injection risks, swallowed exceptions, data loss paths | Must be fixed. Cannot be skipped. |
| `SHOULD-FIX` | Quality, maintainability, coverage gaps | SRP violations, missing tests, code smells, broad catches, defensive gaps | Fix by default. ≤3 can be skipped with specific justification. |
| `NITPICK` | Purely cosmetic | Naming style, whitespace, comment wording | Auto-skipped. No justification needed. |

**Classification rules:**
- `NITPICK` must be purely cosmetic (naming, whitespace, formatting). Any finding involving logic, architecture, correctness, or behavior must be `SHOULD-FIX` or higher.
- When two agents flag the same file/issue at different severities, the highest severity wins.

### Reconciliation Table

After applying or skipping all findings, produce a table:

```
### Review Reconciliation

| # | Agent | Severity | Finding | Action | Justification |
|---|-------|----------|---------|--------|---------------|
| 1 | Clean Code | MUST-FIX | Swallowed exception in api.py:45 | FIXED | Added explicit error propagation |
| 2 | Defensive | SHOULD-FIX | Broad catch in handler.py:120 | SKIPPED | Intentional retry-all pattern per spec |
| 3 | Consistency | NITPICK | Rename `tmp` to `buffer` in utils.py:30 | SKIPPED | — |
```

**Table rules:**
- Every finding from every agent must appear (no silent omissions)
- `MUST-FIX` rows: Action must be `FIXED` (never `SKIPPED`)
- `SHOULD-FIX` + `SKIPPED` rows: Justification must reference a specific code-level reason, not generic text ("not relevant", "out of scope", "refactoring suggestion")
- `NITPICK` rows: Justification column shows `—`
- **Low-ceremony exception**: Skip the table entirely if total findings across all agents ≤ 3

### Enforcement Gates

| Condition | Action |
|-----------|--------|
| Any `MUST-FIX` finding has Action=`SKIPPED` | **STOP** — Present the finding to user, ask: _"This MUST-FIX finding was not applied: [finding]. Proceed anyway? (y/n)"_ |
| More than 3 `SHOULD-FIX` findings have Action=`SKIPPED` | **STOP** — Present all skipped SHOULD-FIX items, ask: _"[N] SHOULD-FIX findings were skipped (max 3 allowed). Approve these skips? (y/n)"_ |
| All gates pass | Proceed to commit & push |

### Output Format Changes

The code-reviewer agent and the 4 wrap-up review agent prompts must output findings in this structured format:

```
[MUST-FIX] file.py:42 — Swallowed ValueError hides connection failures
[SHOULD-FIX] handler.py:120 — Catch block too broad; catches SystemExit
[NITPICK] utils.py:30 — Variable `tmp` could be more descriptive
```

### Session Summary Update

The wrap-up summary line changes from:
```
- Code Review: PASS — Issues: [N found, N fixed, N skipped]
```
to:
```
- Code Review: PASS — [N MUST-FIX (N fixed), N SHOULD-FIX (N fixed, N skipped), N NITPICK (skipped)]
```

## Files Involved

- `.claude/skills/wrap-up-session/SKILL.md` — Steps 4 (agent prompts), 5 (reconciliation + enforcement), 7 (gate + summary format)
- `.claude/agents/code-reviewer.md` — Output format to include severity tags

## Edge Cases

- **Zero findings**: All agents return no issues → skip reconciliation table, proceed normally
- **All NITPICK**: Every finding is cosmetic → table is auto-skipped (≤3 by definition or all NITPICK), proceed
- **Agent failure**: A failed agent already triggers "degraded" status and user prompt (existing behavior, unchanged)
- **Classification gaming**: Agent marks a real bug as NITPICK → mitigated by the classification rule (logic/behavior issues cannot be NITPICK)
- **Duplicate findings**: Two agents flag the same issue → deduplicate in reconciliation table, use highest severity

## Acceptance Criteria

- [ ] Each of the 4 wrap-up review agents classifies findings as MUST-FIX, SHOULD-FIX, or NITPICK
- [ ] Classification rules are documented: NITPICK = cosmetic only, highest severity wins on conflicts
- [ ] Reconciliation table is produced when total findings > 3
- [ ] MUST-FIX findings cannot be skipped without user approval
- [ ] More than 3 skipped SHOULD-FIX findings triggers user approval gate
- [ ] SHOULD-FIX skip justifications must be code-specific (not generic dismissals)
- [ ] Session summary shows severity breakdown instead of flat count
- [ ] Code-reviewer agent output format includes severity tags
- [ ] Existing behavior preserved: agent failure → degraded status, review-fix loop max 2 iterations
