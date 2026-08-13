# Project Memory

> Persistent knowledge base across Claude Code sessions.
> **Always read this at session start.**
> Updated via the `/learn` skill at session end.

---

## Project Context

**Repository**: `coding-agent-workflow`
**Purpose**: A reusable, project-agnostic coding agent configuration system — consolidated rules, subagents, skills, hooks, and workflows that enforce spec-driven, TDD-first development.

**Structure**:
- `.claude/agents/` — specialized subagents
- `.claude/skills/` — skills invokable with `/skill-name`
- `.claude/hooks/` — lifecycle automation
- `CLAUDE.md` — root-level Claude Code config

---

## Architecture Decisions

| Decision | Rationale |
|----------|-----------|
| Spec before code | Prevents scope creep and misaligned implementations |
| TDD enforcement | Forces test validity; guarantees behavior-first thinking |
| Hard gate on `tasks/todo.md` | Prevents coding without a plan |
| Subagents for research | Keeps main context clean and focused |
| Memory.md + lessons.md | Two-tier learning: tactical (lessons.md) vs strategic (memory.md) |
| Claude Code primary | Claude Code supports agents, skills, hooks natively without IDE lock-in |
| Layered config (CLAUDE.md template + .claude/project.md project + CLAUDE.local.md personal) | Lets `/sync` overwrite template safely; uses native `@import`; clear ownership per layer |

---

## Patterns & Lessons

> Append entries here via `/learn`. Format:
> ### [Short title]
> **Context**: When this applies
> **Pattern**: What to do or avoid
> **Evidence**: What triggered this learning

### A parity `cp` can clobber a legitimate harness divergence
**Context**: Any time an edit to `.agents/**` is copied to the matching `.claude/**` path.
**Pattern**: `.claude/` copies are byte-identical *except* for allowlisted Claude-only
frontmatter — `.claude/agents/software-design-expert-review.md` carries `model: sonnet`
by design (Reviewer tier, not Ceiling). A blind `cp` from `.agents/` silently drops it,
and `test-skill-parity.sh` cannot catch it because parity is what the `cp` just enforced.
After any parity copy, run `git diff .claude/agents/ | grep -E '^[-+]model:'` and confirm
it is empty.
**Evidence**: Tier 2 build — the `cp` loop dropped that pin; caught only by an explicit
frontmatter diff, not by the 13-file green suite.

### Check `git worktree list` before declaring a prerequisite missing
**Context**: Multi-tier specs where an earlier tier may already be built.
**Pattern**: A tier's work can be complete on an unmerged branch inside a worktree, so
the files are absent from the branch you are standing on. `ls tests/` on `master` said
Tier 1 was unbuilt; `git worktree list` + `git branch` showed it finished on
`feat/compound-engineering-tier-1`. Check both before concluding anything is missing, and
branch the next tier from the real base so the work stacks instead of duplicating.
**Evidence**: Tier 2 build opened by wrongly reporting Tier 1 as not landed.

### A slow test is not a hung test
**Context**: Diagnosing a test suite that exceeds a tool timeout.
**Pattern**: Time each file (`for f in tests/test-*.sh; do ... done`) before diagnosing a
hang. `test-install-sh.sh` runs `install.sh` five times for real and takes ~108s on this
filesystem; the whole suite needs ~4.5 min, so the 2-minute default Bash timeout truncates
it and reads as a hang. Pass an explicit timeout for `tests/run.sh`.
**Evidence**: Tier 2 build — first full-suite run reported a hang that was ordinary slowness.

### Pin whitespace-normalized text when guarding hard-wrapped prose
**Context**: `tests/test-doc-conventions.sh`-style token greps over markdown.
**Pattern**: `grep -F` on a multi-word phrase fails when the phrase straddles a newline in
hard-wrapped prose, producing a phantom failure on a pure reflow. Collapse first
(`tr '\n' ' ' | tr -s ' '`) and assert against that. Single tokens are safe either way.
**Evidence**: Tier 2 — two assertions failed only because "separately dispatched contexts"
wrapped mid-phrase.

---

## Session History

> Append entries here via `/learn`. Format:
> ### [YYYY-MM-DD] — [2-3 word summary]
> - Key changes: [bullet list]
> - Lessons added: [count or none]

### [2026-08-10] — Compound engineering Tier 2 (review epistemics)
- Key changes: Added `CLAUDE.md` § *Finding Model* (four axes — `severity`,
  `confidence`, `autofix_class`, `owner` — with three behavioral confidence anchors) and
  § *Independence Accounting*. `/quality-gate` and `/wrap-up-session` now enforce an apply
  gate (`gated_auto` **and** `confidence >= 75`) and must disclose whether their review
  passes ran `dispatched` or `inline`; inline runs may never promote confidence. The four
  review personas emit all four axes with a `file:line` evidence gate at anchor 75+.
  Guards: +71 lines in `test-doc-conventions.sh`, +22 in `test-agents.sh` (242 + 112
  assertions). Branch `feat/compound-engineering-tier-2`, stacked on Tier 1.
- Pattern: Confidence and severity are independent. Severity says how much a finding
  matters if real; confidence says whether it is real. Collapsing them is what lets an
  unproven guess be auto-applied with the authority of a proven defect.
- Pattern: A `MUST-FIX` at `confidence: 50` must be *verified*, not fixed and not blocked
  on — otherwise a speculative finding deadlocks every commit. Caught in this session's own
  Phase 3 gate, in the very rule being written.
- Lessons added: 4 patterns above
- Deferred: Tier 3.1/3.2/3.3 (typed learning store, harness cutover, concept glossary) —
  27 open tasks in `tasks/todo.md`. `tasks/lessons.md` deliberately NOT created; Tier 3
  retires it, so adding it now only gives the migration another file to archive.

### [2026-07-08] — Visual plan/recap skills
- Key changes: Added `/visual-plan` + `/visual-recap` (opt-in) that render self-contained HTML visual docs locally by wrapping the existing `html-presentation` generator; new `visual-render.py` post-processor injects diff coloring + tabsets. No external MCP/hosted service (adapted from BuilderIO/skills' hosted model).
- Pattern: To extend a `/sync`-managed skill's output without editing it, wrap it — a new skill owns a post-processor that operates on the managed skill's OUTPUT. Keeps the managed file untouched so `/sync` never clobbers the work.
- Pattern: The bash test suite enforces `.agents/` ↔ `.claude/` byte-identical skill parity (`test-skill-parity.sh`) + doc-convention token greps (`test-doc-conventions.sh`). Any new skill must be authored in BOTH trees identically and wired into both tests.
- Lessons added: none (captured as patterns above)
