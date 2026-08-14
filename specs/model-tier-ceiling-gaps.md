# Spec: Close the gaps the Ceiling tier left open

> Follows PR #53, which shipped the Ceiling tier. This spec covers three things
> #53 named but did not finish, plus a test-harness hole found while verifying
> them. It is deliberately narrow: the Ceiling tier itself, its rationale, and its
> `CLAUDE.md` vocabulary are #53's and are not restated here.

## Behavior

`Ceiling` means "omit the `model` override so the sub-agent inherits the session
model". #53 established the tier and applied it to three review roles. Four
things remained.

### 1. `software-design-expert-review` joins Ceiling

#53 left it at Reviewer tier (`sonnet`) with an explicit rationale — its own skill
read *"`model: sonnet` — Reviewer tier, not Ceiling"* — and `tests/test-model-tiers.sh`
asserted the pin via `PINNED_AGENTS`.

**This spec overrides that decision.** An APOSD structural audit is correctness
work: the defects it finds are the expensive kind, and a design flaw caught late
costs far more than the token difference. It is the one change here that reverses
a documented choice rather than completing an unfinished one, so it is the one
most worth a reviewer's pushback.

`PINNED_AGENTS` keeps a subject — `context-document-optimizer`, also Reviewer
tier — so the mirror guard #53 added does not go vacuous. That guard protects a
real observed regression: the `.agents/` → `.claude/` parity copy is a plain `cp`
from a tree that is model-agnostic by contract, so it silently drops a
Claude-only `model:` line, and parity tests cannot catch it because the `cp` is
what made the two files identical.

### 2. `critic` gains a planner floor

Plain `ceiling` inherits in every direction **including down**. On a Builder- or
Scout-tier session the adversarial gate of last resort ran below planner tier —
a silent downgrade of the one reviewer whose whole job is catching what the others
missed.

Resolution becomes `*ceiling (planner floor)*`: omit the override at planner tier
or above, pass the planner alias below it.

The floor is a **dispatch rule, not frontmatter.** A `model: opus` pin would
satisfy the floor on a Sonnet session but *cap* the agent on any session stronger
than Opus — the same defect Ceiling exists to remove. Nothing mechanically
enforces the floor; the test pins the rule's presence and the absence of a pin,
which is as far as a static guard reaches. This limit is stated rather than
hidden.

### 3. Concrete model IDs leave the routing tables

Four OpenRouter IDs lived in `CLAUDE.md`, `/build`'s table (both trees), and
`PI_SETUP.md`. Three copies of a release-sensitive fact is three chances to go
stale, and the two tables are the copies nobody updates.

`PI_SETUP.md` § Sub-Agent Routing becomes the named single source. Both tables
carry tiers only.

This also reconciles a contradiction #53 introduced: `CLAUDE.md` gained the rule
*"leave ceiling-tier agents out of `agentOverrides` so they inherit"* while
`PI_SETUP.md`'s example config went on pinning all four of them.

### 4. `assert_not_contains` no longer passes vacuously

Absence-of-needle is trivially true of the empty string, so any `grep`/`sed`
extraction that matched nothing reported `ok` — turning a load-bearing check into
a silent pass. `assert_contains` needs no such guard (an empty haystack cannot
contain a non-empty needle), which is why the hole was one-sided and easy to miss.

The guard goes in the primitive rather than in each caller, because "remember to
check your extraction first" is the discipline whose absence causes the bug.

Two helpers follow from the same work: `assert_file_matches` /
`assert_file_not_matches` for anchored patterns like `^model:` that
`assert_file_contains` cannot express (`grep -qF` is literal-only), and
`assert_prose_contains`, which collapses whitespace so a prose assertion depends
on the words rather than on where the markdown hard-wrap happens to fall.

## Inputs

Read from disk on current `master` (`7c3dc74`), not assumed:

- `CLAUDE.md` — Agents table (10 rows), Model Routing (5 tiers incl. `Ceiling`),
  and the dispatch Rules block.
- `.claude/agents/` — `code-reviewer`, `security-reviewer`, `critic` already
  unpinned by #53; `software-design-expert-review` still `model: sonnet`.
- `tests/test-model-tiers.sh` — 105 lines, `CEILING_AGENTS` (3) and
  `PINNED_AGENTS` (1).
- `.agents/skills/build/SKILL.md` — 8-row table with 8 concrete IDs; ladder and
  circuit breaker naming IDs.
- `.agents/skills/{quality-gate,software-design-expert-review}/SKILL.md` — the two
  design-reviewer dispatch sites.
- `PI_SETUP.md` — concrete IDs plus an `agentOverrides` example pinning all four
  review roles; zero mentions of `ceiling`.
- `tests/lib.sh` — 5 assertion helpers, none regex, none whitespace-normalizing.

## Outputs

| Path | Change |
|------|--------|
| `CLAUDE.md` | design reviewer → `*ceiling*`; `critic` → `*ceiling (planner floor)*`; floor rule added; Pi column dropped, pointer added; Ceiling row covers design |
| `.claude/agents/software-design-expert-review.md` | delete the `model:` line |
| `.agents/skills/build/SKILL.md` + `.claude/` copy | Tier column replaces Model ID column; ladder and circuit breaker name tiers |
| `.agents/skills/{quality-gate,software-design-expert-review}/SKILL.md` + copies | dispatch at Ceiling, no `model` |
| `PI_SETUP.md` | named single source; Ceiling row; four roles removed from `agentOverrides` with the reason |
| `tests/lib.sh` | empty-haystack guard; `assert_file_matches`, `assert_file_not_matches`, `assert_prose_contains` |
| `tests/test-model-tiers.sh` | `CEILING_AGENTS` gains the design reviewer; `PINNED_AGENTS` → `context-document-optimizer`; sections 6–8 added |

### Unchanged, deliberately

- Debugger attempts 3–4 stay at Reviewer/`sonnet`. Identical to attempts 1–2, so
  on Claude Code the escalation ladder still escalates to the model that just
  failed. Real, pre-existing, and out of scope — noted so it is not mistaken for
  fixed.
- Master's hand-rolled `^model:` loops in `tests/test-model-tiers.sh` §1–3 are not
  collapsed onto the new helpers. The refactor is available but would make this
  diff read as a rewrite of #53's test rather than an extension.
- `code-reviewer`, `security-reviewer` get no floor. Only `critic` needs one.

## Edge Cases

- **A Haiku session.** `code-reviewer`, `security-reviewer`, and the design
  reviewer run on Haiku. Accepted: Ceiling means the session's choice governs, and
  a user on Haiku chose cheap. `critic` is the exception, by floor.
- **Someone re-pins a Ceiling role.** `tests/test-model-tiers.sh` fails, in both
  the agent file and the routing tables. Verified by probing each.
- **The floor is unenforceable.** Stated in `CLAUDE.md` and in this spec.
- **Pi cannot express a floor declaratively.** `agentOverrides` omits `critic`, so
  it inherits; a user on a sub-planner Pi session pins it manually. Documented in
  `PI_SETUP.md`.
- **Markdown reflow.** Prose assertions use `assert_prose_contains`, so rewrapping
  a paragraph does not break the suite.

## Acceptance Criteria

- [x] All four review roles resolve to a Ceiling variant in `CLAUDE.md` and `/build`
- [x] `.claude/agents/` pins no model for any of the four
- [x] The six non-Ceiling personas keep their pins (guards a blanket strip)
- [x] `critic`'s floor is stated as a dispatch rule, and the test fails if the rule is deleted
- [x] No concrete provider model ID remains in `CLAUDE.md` or either `/build` copy
- [x] `PI_SETUP.md` claims single-source ownership and explains Ceiling
- [x] `PI_SETUP.md`'s `agentOverrides` no longer contradicts `CLAUDE.md`
- [x] No skill routes the design reviewer to a concrete model
- [x] `assert_not_contains` fails on an empty haystack, with no sibling test broken
- [x] `tests/test-skill-parity.sh` green over every edited skill
- [x] `bash tests/run.sh` green — 15 files, 1079 assertions

## Non-Goals

- No change to the Ceiling tier's definition or rationale — #53 owns those.
- No floors beyond `critic`.
- No fix for the debugger 3–4 escalation no-op.
- No refactor of #53's existing test loops.
