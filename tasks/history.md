# History

> Migrated from the Session History section of tasks/memory.md.

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
  unproven guess be auto-applied with the authority of a proven defect. (extracted: tasks/solutions/patterns/confidence-and-severity-are-independent-severity-says-how-mu.md)
- Pattern: A `MUST-FIX` at `confidence: 50` must be *verified*, not fixed and not blocked
  on — otherwise a speculative finding deadlocks every commit. Caught in this session's own
  Phase 3 gate, in the very rule being written. (extracted: tasks/solutions/patterns/a-must-fix-at-confidence-50-must-be-verified-not-fixed.md)
- Lessons added: 4 patterns above
- Deferred: Tier 3.1/3.2/3.3 (typed learning store, harness cutover, concept glossary) —
  27 open tasks in `tasks/todo.md`. `tasks/lessons.md` deliberately NOT created; Tier 3
  retires it, so adding it now only gives the migration another file to archive.

### [2026-07-08] — Visual plan/recap skills

- Key changes: Added `/visual-plan` + `/visual-recap` (opt-in) that render self-contained HTML visual docs locally by wrapping the existing `html-presentation` generator; new `visual-render.py` post-processor injects diff coloring + tabsets. No external MCP/hosted service (adapted from BuilderIO/skills' hosted model).
- Pattern: To extend a `/sync`-managed skill's output without editing it, wrap it — a new skill owns a post-processor that operates on the managed skill's OUTPUT. Keeps the managed file untouched so `/sync` never clobbers the work. (extracted: tasks/solutions/patterns/to-extend-a-sync-managed-skill-s-output-without-editing-it-w.md)
- Pattern: The bash test suite enforces `.agents/` ↔ `.claude/` byte-identical skill parity (`test-skill-parity.sh`) + doc-convention token greps (`test-doc-conventions.sh`). Any new skill must be authored in BOTH trees identically and wired into both tests. (extracted: tasks/solutions/patterns/the-bash-test-suite-enforces-agents-claude-byte-identical-sk.md)
- Lessons added: none (captured as patterns above)
