# Task Plan

> Spec: specs/compound-engineering-adoption.md — M3 (typed learning store, full migration) + M3-MIG (standalone migration script)
> Branch: worktree-m3-typed-learning-store (worktree off master)
> Scope: Acceptance Criteria Tier 3.1 + Tier 3.2. Tier 3.3 (M4 concepts glossary) is OUT of scope.
> Note: spec file itself lives on the main clone (untracked); it is the contract, referenced read-only.

---

## Task 1 — Store schema + validator guard

[x] TDD: `tests/test-solutions-schema.sh` fails on fixture docs with (a) unknown `problem_type`, (b) missing track-required field (bug track without `root_cause`; knowledge track without `applies_when`), (c) a date in the filename; passes on valid fixtures and on the real (initially empty) `tasks/solutions/` tree -> write `tasks/solutions/README.md` (frontmatter schema, `problem_type` enum, category map, two tracks, `needs_review`), `tasks/solutions/.gitkeep`, and the validator test sourcing `tests/lib.sh`, excluding `.claude/worktrees/`

## Task 2 — Migration script + fixture-driven tests

[x] TDD: `tests/test-migrate-learning-store.sh` covers: absent inputs (exit 0, no output files), 8-column and 5-column `bugs.md` schemas (header-name mapping, unknown column carried into body), free-form `lessons.md` (split on headings else blank-line blocks, `needs_review: true`), slug collision (numeric suffix), missing date (fallback chain recorded), re-run idempotency (second run exits 0, changes nothing), dirty-tree refusal without `--force`, existing `tasks/project-context.md` conflict (`.migrated.md` written, exit 0), unrecognized `##` section (archived verbatim, reported unmigrated), dry-run default writes nothing, `--apply` archives originals to `tasks/archive/<UTC-timestamp>/` and deletes nothing, non-zero exit on failure naming the source -> write `scripts/migrate-learning-store.py` (stdlib only, Python 3) with interpreter probing `python3`/`python`/`py` in the test harness

## Task 3 — Migrate this repo with --apply

[x] TDD: dry run prints a plan naming every document; `--apply` produces `tasks/solutions/<category>/<slug>.md` docs for the 7 Architecture Decisions rows + 2 `- Pattern:` bullets leaked into the 2026-07-08 session-history entry, `tasks/history.md` retaining the narrative entry (cross-linked), `tasks/project-context.md` (does not pre-exist here), originals moved to `tasks/archive/<UTC-timestamp>/`; `tests/test-solutions-schema.sh` green over the migrated docs; second run exits 0 no-op -> run the script on this worktree

## Task 4 — Hooks cutover

[x] TDD: `tests/test-session-start.sh` asserts the hook reports store counts in one line, dumps no document bodies, banner grows ≤1 line, and references none of the retired files; `tests/test-pre-compact.sh` asserts flush targets the new destinations -> edit `.claude/hooks/session-start.sh` + `.claude/hooks/pre-compact.sh`

## Task 5 — CLAUDE.md / README / install.sh cutover

[x] TDD: `tests/test-doc-conventions.sh` `tasks/memory.md` assertion INVERTED (asserts /build and /checkpoint do NOT reference it) and green; `tests/test-install-sh.sh` green with new seeds -> CLAUDE.md Session Start Checklist + Key Directories describe `tasks/solutions/`, `tasks/history.md`; CLAUDE.md names the migration script; README store description; install.sh seeds `tasks/solutions/README.md` + `tasks/history.md`, stops seeding `lessons.md`/`bugs.md`

## Task 6 — Skills cutover (canonical tree)

[x] TDD: grep across `.agents/skills/` finds zero references to `tasks/memory.md`, `tasks/lessons.md`, `tasks/bugs.md` -> `/learn` writes typed docs with date in frontmatter, five-dimension overlap scoring (High=update, Moderate=create+cross-link, Low=create), grounding rule (file:line or attribute; PR numbers not SHAs); `/memory-maintain` sweeps `tasks/solutions/` for stale/contradicted/`needs_review` docs; `/debug` + bug-report template emit bug-track documents; `/sync` detects an unmigrated store and points at the script; path-reference updates in auto-improve, brainstorm, build, checkpoint, prd, refresh, start-qa, wrap-up-session

## Task 7 — project-template seeds

[x] TDD: `project-template/tasks/` carries `solutions/README.md` + `history.md`, no longer carries `lessons.md`/`bugs.md`; template `.gitattributes`/docs consistent -> add/remove the seed files

## Task 8 — Parity copies

[x] TDD: `tests/test-skill-parity.sh` green -> byte-identical copy of every edited `.agents/skills/**` file into `.claude/skills/**`

## Task 9 — Full validation + reference sweep proof

[x] TDD: `bash tests/run.sh` fully green; `grep -rn "tasks/(memory|lessons|bugs)\.md"` across both trees, hooks, CLAUDE.md, README.md, install.sh returns hits only under `tasks/archive/` and `specs/` -> record the sweep output as evidence

## Session Summary — 2026-08-13 [128952c..18e3304]
- Completed: 9 tasks (M3 typed learning store + M3-MIG migration script, all ACs evidenced)
- Pending: 0 tasks
- Carry-forward: M4 (Tier 3.3 concepts glossary) — picked up below on `feat/compound-engineering-tier-3.3-glossary`

---

## Plan: M4 — Accreting Concept Glossary (Tier 3.3)
> Spec: specs/compound-engineering-adoption.md § M4 / Tier 3.3, plus delta addendum specs/compound-engineering-m4-concept-glossary.md (both live untracked on the main clone, per the convention noted at the top of this file)
> Branch: feat/compound-engineering-tier-3.3-glossary (worktree off worktree-m3-typed-learning-store)

[x] Setup: worktree on `feat/compound-engineering-tier-3.3-glossary` off `worktree-m3-typed-learning-store` @ 53db64d; baseline `tests/run.sh` green (15 files)
[x] TDD: doc-conventions asserts both glossary seeds exist, define the six terms (tier, gate, register, drift, ceiling, store) as anchored bullets, and carry exactly one legal-state sweep marker (template must be `pending`) -> `tasks/concepts.md` + `project-template/tasks/concepts.md` written
[x] TDD: test-install-sh asserts `copy_if_missing "tasks/concepts.md"` -> install.sh seeds the glossary
[x] TDD: doc-conventions asserts both `learn/SKILL.md` copies reference `tasks/concepts.md` + the pending marker -> /learn Step 7 concept capture (side effect, refine-in-place, seed-shape bootstrap when absent)
[x] TDD: doc-conventions asserts both `memory-maintain/SKILL.md` copies carry Phase 0, both marker states, and the pruning rule -> Phase 0 bootstrap sweep fires from the light pass (exempt from the empty-store no-op), pruning in Phase 4, glossary line in Output
[x] TDD: doc-conventions asserts CLAUDE.md Key Directories + project-template/CLAUDE.md list the glossary -> both registered; Session Start Checklist gained the read path (consult glossary for unknown project terms)
[x] Evidence: Phase 0 dogfooded on this repo — swept 10 project terms into `## Project vocabulary`, marker flipped to `> Sweep: done 2026-08-13`; second run: `grep -c '^> Sweep: pending'` = 0 → no-op. README scaffold lists (post-init, manual copy, repo tree) and template `.gitattributes` exclusion list updated after critic review.
[x] TDD: full `tests/run.sh` green + parity green; critic dispatched (ceiling tier), verdict HOLD → all MUST-FIX/SHOULD-FIX findings fixed (empty-store/Phase 0 interaction, legal-state marker guard, README drift, CLAUDE.md wording, .gitattributes, read path); re-run green

## Session Summary — 2026-08-13 [53db64d..HEAD]
- Completed: 8 tasks (M4 Tier 3.3 — glossary, bootstrap sweep, capture/prune hooks, guards, dogfood evidence)
- Pending: 0 tasks
- Carry-forward: stacked on unmerged `worktree-m3-typed-learning-store` — M3 PR merges first, then this branch's PR retargets/merges
