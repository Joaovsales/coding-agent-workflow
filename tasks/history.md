# History

> Migrated from the Session History section of tasks/memory.md.

### [2026-08-13] — Typed learning store (M3 + M3-MIG)

- Key changes: Built the typed learning store and cut the harness over to it.
  New `tasks/solutions/<category>/<slug>.md` schema (`tasks/solutions/README.md`),
  stdlib-only `scripts/migrate-learning-store.py` (dry-run default, `--apply`,
  archive-never-delete, conflict diversion to `.migrated.md`), and this repo's own
  migration applied (15 documents, originals in `tasks/archive/20260811T183743Z/`).
  Session-start banner reduced to one-line store counts; `/learn`, `/memory-maintain`,
  `/debug`, `/sync` rewritten for the store; retired-file references swept from both
  skill trees, hooks, CLAUDE.md, README, install.sh, project-template. New suites:
  test-migrate-learning-store.sh (78 asserts), test-solutions-schema.sh (31, incl.
  enum-sync across script/validator/README). Branch `worktree-m3-typed-learning-store`.
- Learnings captured: tasks/solutions/bugs/grep-zero-matches-aborts-hooks-under-set-e-pipefail.md,
  tasks/solutions/patterns/construct-retired-paths-at-runtime-to-keep-literal-sweeps-strict.md

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

### [2026-08-13] — M4 concept glossary

- Key changes: Added `tasks/concepts.md` (accreting concept glossary) + template seed; `/memory-maintain` Phase 0 one-time bootstrap sweep keyed on a `> Sweep: pending` marker, fired from the light pass; `/learn` Step 7 concept capture; pruning rule in Phase 4; install.sh seed; guards in test-doc-conventions.sh + test-install-sh.sh. Dogfooded the sweep on this repo (10 terms admitted, marker flipped).
- Learnings captured: tasks/solutions/patterns/first-run-triggers-must-precede-every-early-exit-above-them.md

### [2026-08-14] — Agent registration repair

- Key changes: Three documented personas (`code-reviewer`, `context-document-optimizer`,
  `frontend-design-validator`) were absent from the harness agent registry despite existing
  in both trees with correct names and a green suite. Cause was a YAML parse error — their
  `description:` values were unquoted plain scalars carrying `": "` from auto-generated
  `<example>` prose. Rewrote all three colon-free (both trees), added `tests/test-agents.sh`
  § 4 (frontmatter constructs that break registration, with nine negative self-test fixtures)
  and § 5 (CLAUDE.md § Agents -> counterpart file, with a count floor so the check cannot
  fail open). Documented the constraint as rule 5 in `.agents/agents/README.md`.
- Verified live: all three personas registered on the next session start, and the four
  `/wrap-up-session` review passes dispatched — three of them `code-reviewer`, the exact
  pass that was broken.
- Learnings captured: tasks/solutions/bugs/unquoted-yaml-scalar-silently-deregisters-an-agent-persona.md
- Review: 4 parallel passes (3x code-reviewer, 1x critic), separately dispatched, so
  corroboration between them is independent. 4 MUST-FIX and 8 SHOULD-FIX raised; the
  vacuity findings (checks passing when their input vanished) were found independently by
  three of the four passes and all were fixed. One critic claim was disproven on check —
  a "lossless" single-quoted restore of the original description raises ParserError on its
  own apostrophes.
- Deployment: the broken copies in `~/.claude/agents/` were refreshed by hand the same day.
  Fixing the repo does not fix the machine - an installed persona has its own copy, so
  "repo is green" and "harness is fixed" are separate claims.

### [2026-08-18] — Windows session-guard key collapse

- Fixed a Windows-only defect in `.claude/hooks/session-start.sh`: the double-invocation
  guard fell back to `$PPID`, which is `1` for bash spawned from a native Windows parent,
  so every session in every repo shared one sentinel and a second repo opened inside the
  5-minute window got no banner at all. Confirmed in the wild — `/tmp/.ccw-session-start-1-*`
  was being rewritten by live sessions. Now keys on `session_id` parsed with sed (the `jq`
  branch is gone, and `jq` is absent on this machine so it was never the live path), falling
  back to a `cksum` of `$PWD`.
- Added seven guard assertions to `tests/test-session-start.sh`. The load-bearing detail is
  that they redirect to a file instead of capturing with `$(...)`: command substitution forks
  a fresh subshell per call, so `$PPID` varied per invocation and the old guard was **inert
  under test** — which is why the defect shipped. Three pre-existing assertions had to take
  `CCW_SESSION_GUARD=0`; they were green only because the guard never fired.
- The 4-pass review then found a MUST-FIX **in the fix**: the new `cksum` pipeline had no
  `|| true`, so under `set -eo pipefail` a missing `cksum` killed the hook at exit 127 with
  zero output — a worse silent-banner loss than the original bug, with the documented
  degradation unreachable. All four passes found it independently; reproduced directly.
  A second MUST-FIX explained why it was invisible: the "stays silent" assertions checked
  stdout only, and a crash also prints nothing.
- Also fixed from review: extracted a shared `json_string_field` helper (the sed idiom had
  been cloned, with two divergent character classes), widened the `session_id` capture to
  `[^"]*`, bounded the raw-path fallback, added expiry/empty-payload/cksum-absent coverage,
  and set `CCW_SESSION_GUARD=0` in `codex/hooks/session_start.py` — Codex registers once, and
  the now-stable cwd key would have suppressed its second session in a repo.
- Learnings captured: `tasks/solutions/bugs/ppid-is-1-on-windows-so-a-ppid-keyed-guard-collapses.md`,
  `tasks/solutions/patterns/command-substitution-forks-a-subshell-so-ppid-varies-per-call.md`
- Review: 4 parallel passes (3x code-reviewer, 1x critic), separately dispatched, so
  corroboration is independent. 2 MUST-FIX and 13 SHOULD-FIX raised; 1 SHOULD-FIX skipped
  (`pre-compact.sh` still requires `jq` — pre-existing line, advisory/human).
- Open, not acted on: the critic argued the fallback should be dropped entirely (no
  `session_id` -> just print), since the guard suppresses a cosmetic duplicate but fails by
  losing a functional banner. That deletes several findings rather than fixing them. Left to
  the user, because the requested fix shape was explicitly a stable-and-distinct *key*.
- Not fixed, pre-existing: `tests/test-codex-install.sh` red baseline (unchanged, still open);
  ~290 unreaped `.ccw-session-start-*` sentinels accumulating in `/tmp` since 30 July.
