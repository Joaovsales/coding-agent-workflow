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


## Plan: Codex Harness Adapter
> Spec: specs/codex-harness-adapter.md
> Branch: agent/codex-harness-adapter-pr

[x] TDD: `tests/test-codex-install.sh` covers isolated installation, personal-content preservation, valid rendered agents/hooks, and idempotence -> add the failing integration/static test
[x] TDD: renderer tests cover shared AGENTS block, Markdown-agent-to-TOML conversion, and hooks JSON merge -> add the stdlib renderer/merger
[x] TDD: Codex adapter installs canonical skills, agents, hooks, and managed global rules from any working directory -> add `scripts/install-codex.sh` and hook adapters
[x] TDD: project scaffold test requires neutral `AGENTS.md` -> add template seed and copy it from the git `post-init` hook
[x] TDD: documentation test requires Codex setup/update instructions and harness-neutral language -> update README and installer help text
[x] Full validation: `bash tests/run.sh`, shell syntax checks, Python compile/parse checks, and security review of changed scripts

## Session Summary — 2026-08-14
- Completed: 6 tasks (Codex harness adapter, renderer, hooks, neutral project seed, docs, and validation)
- Pending: 0
- Carry-forward: review and merge the draft PR

## Plan: Review Context Contract
> Spec: specs/review-context-contract.md
> Base: origin/master @ 23f0d7d — branch feat/review-context-contract (worktree)

[x] TDD: `tests/test-review-context.sh` fails on master because `CLAUDE.md` has no § Review Dispatch Contract -> add the section with the 7-item payload table and the absent-vs-empty rule
[x] TDD: same test asserts the intent-shared / conclusions-withheld split names Independence Accounting as the reason -> add the split to the new section
[x] TDD: test asserts a finding at `75` must name its dependency and that an unnamed one reads as `50` -> extend `CLAUDE.md` § Finding Model
[x] TDD: test asserts the verification path (read dependency -> promote to 100 with evidence, drop, or hold and say what stopped it) and that verification-promotion is NOT agreement-promotion -> extend § Finding Model
[x] TDD: test asserts all four dispatch sites (wrap-up Step 4 + Parallel Code Review, quality-gate Phase 3, software-design-expert-review Phase 2) cite the contract by section name, in BOTH trees -> edit 3 skills canonical-first, then byte-identical copy
[x] TDD: test asserts each dispatch site states the absent-vs-empty rule for spec and deferrals -> add the payload lines at each site
[x] TDD: test asserts all 8 reviewer persona files (4 personas x 2 trees) carry a `## Context Intake` section naming given / fetch-yourself / out-of-scope -> add the section; `tests/test-agents.sh` must stay green (frontmatter untouched)
[x] TDD: `tests/test-model-tiers.sh` §8 widened to fail when a Ceiling role is pinned in a bare table cell -> widen the guard, then unpin `auto-improve`'s design-review charter to *ceiling* (both trees)
[x] TDD: mutation probes — delete the contract section, remove one site's pointer, remove one persona's intake, delete the anchor-75 rule; each must turn the suite red. Commit first, then probe -> record counts in the spec
[x] TDD: `bash tests/test-skill-parity.sh` green over every edited skill; `bash tests/run.sh` green with assertion count recorded against the 1108-assertion baseline -> run both, then `/quality-gate`

---

## Session Summary — [2026-08-18] [25999b1..f96255d]
- Completed: 0 planned tasks (direct bug-fix request; no /plan run this session)
- Pending: 0 — the plan blocks above belong to earlier worktrees and are all closed
- Carry-forward: decide whether the no-session_id guard fallback should exist at all
  (the critic argued for "no session_id -> just print", since the guard suppresses a
  cosmetic duplicate but fails by losing a functional banner); ~290 unreaped
  `.ccw-session-start-*` sentinels in /tmp with nothing reaping them

---

## Plan: UTF-8 at every Python IO boundary
> No /plan — direct user bug report: `generate-presentation.py` decoded stdin with the platform default codec.
> Branch: claude/vibrant-chaum-2cad9b (worktree off master @ 25999b1)

[x] Fix the reported stdin decode in both mirror copies -> `tests/test-html-presentation.sh` (26 assertions) pins the `--markdown -` path, and asserts PYTHONIOENCODING took effect so the pin cannot go vacuous
[x] Review-driven: `utf-8-sig` on both markdown branches -> a retained BOM defeated the H1 match and silently dropped the title and every section at exit 0
[x] Review-driven: pin stdout in `generate-presentation.py`; explicit encoding on `visual-render.py`'s subprocess capture (`text=True` left `result.stderr` as `None` on a failing child)
[x] Learnings: encoding-class pattern doc

## Session Summary — 2026-08-18 [25999b1..HEAD]
- Completed: 3 items (1 as reported, 2 surfaced by the review gate)
- Pending: 0
- Carry-forward: none. This branch also fixed the Codex adapter and diagnosed the
  session guard; both were superseded by #66 and #68, which landed on master first.
  Taken from upstream at merge — see the history entry for what my diagnosis got wrong.
