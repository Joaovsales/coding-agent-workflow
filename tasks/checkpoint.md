# Checkpoint — 2026-08-10T19:36:45Z

> Auto-written by PreCompact hook (trigger: unknown). Re-read on resume.

## Git
- Branch: feat/compound-engineering-tier-2

```
M  .agents/skills/auto-improve/SKILL.md
M  .agents/skills/auto-push/SKILL.md
M  .agents/skills/build/SKILL.md
A  .agents/skills/build/references/subagent-resilience.md
M  .agents/skills/quality-gate/SKILL.md
M  .agents/skills/yolo/SKILL.md
M  .claude/skills/auto-improve/SKILL.md
M  .claude/skills/auto-push/SKILL.md
M  .claude/skills/build/SKILL.md
A  .claude/skills/build/references/subagent-resilience.md
M  .claude/skills/quality-gate/SKILL.md
M  .claude/skills/yolo/SKILL.md
 M tasks/todo.md
```

## In-Progress & Pending Tasks (tasks/todo.md)
[ ] TDD: `tasks/solutions/README.md` defines the frontmatter schema, both tracks with their required fields, the `problem_type` enum, the category map, and `needs_review` — verify by reading against spec § M3 -> Write the schema doc; create the store with `.gitkeep`
[ ] TDD: `tests/test-solutions-schema.sh` fails on a document with an unknown `problem_type`, a missing track-required field, or a date in the filename, and passes on a valid one — verify with fixtures in the scratch dir -> Write the schema guard
[ ] TDD: `scripts/migrate-learning-store.py` resolves its interpreter by probing `python3`/`python`/`py`, and a bare run on this repo prints a dry-run plan and writes nothing — verify by running it and confirming `git status` is unchanged -> Write the script skeleton: arg parsing (`--apply`, `--force`, `--repo`, `--report`), repo resolution, dry-run default, report renderer
[ ] TDD: The script converts all five `memory.md` section kinds to their correct destinations — Architecture Decisions and Patterns to `tasks/solutions/`, Session History bodies to `tasks/history.md`, Project Context to `tasks/project-context.md` — verify against a fixture copy of the real `tasks/memory.md` -> Implement the memory.md section parser and per-kind writers
[ ] TDD: The script extracts the two `- Pattern:` bullets leaked into the real 2026-07-08 session-history entry as their own knowledge-track documents while leaving the narrative bullet in `tasks/history.md`, cross-linked — verify against the real file as a fixture -> Implement leaked-pattern extraction
[ ] TDD: The script maps `tasks/bugs.md` columns by header name and produces correct bug-track documents from both the 8-column repo schema and the 5-column `project-template` schema, carrying unrecognized columns into the body — verify with one fixture per schema -> Implement the header-driven bug-table reader
[ ] TDD: The script splits free-form `tasks/lessons.md` on headings when present and on blank-line blocks otherwise, one document per block — verify with a heading fixture, a blank-line fixture, and an unsplittable single-block fixture -> Implement the lessons parser
[ ] TDD: Every document with an inferred or missing required field carries `needs_review: true` and appears in the report; documents with complete fields do not — verify with the 5-column bug fixture and a complete-field fixture -> Implement the needs_review stamp and report section
[ ] TDD: `--apply` archives `memory.md`, `lessons.md`, and `bugs.md` to `tasks/archive/<UTC-timestamp>/` and deletes nothing; a second run detects the completed migration, changes nothing, and exits 0 — verify by running twice against a fixture repo -> Implement archiving and the idempotency check
[ ] TDD: The script refuses a dirty git tree without `--force`, skips the check with a note when not a git repo, and exits non-zero naming the failing source on any error — verify with a dirty fixture, a non-repo fixture, and a malformed-input fixture -> Implement the safety gates and exit codes
[ ] TDD: The script does not overwrite an existing `tasks/project-context.md`; it writes `tasks/project-context.migrated.md`, reports the conflict, and exits 0 — verify with a fixture that already has the file -> Implement the conflict path
[ ] TDD: Two entries that slug identically produce a numeric suffix rather than an overwrite; an entry with no date falls back to last-commit date then today and records which fallback it used — verify with a collision fixture and a dateless fixture -> Implement slug collision handling and date fallback
[ ] TDD: An unrecognized `##` section in `memory.md` is archived verbatim and named in the report as unmigrated, never guessed at — verify with a diverged-sections fixture -> Implement unknown-section passthrough
[ ] TDD: `tests/test-migrate-learning-store.sh` runs every fixture case above under `tests/run.sh` and is green — verify by full run -> Assemble the fixture-driven test file
[ ] TDD: This repo's store is migrated and `tasks/archive/<timestamp>/` holds all three originals — verify with `ls tasks/solutions tasks/archive` and a schema-guard run over the produced documents -> Run the script with `--apply` on this repo
[ ] TDD: `tests/test-doc-conventions.sh` asserts `/build` and `/checkpoint` do NOT reference `tasks/memory.md` and passes — verify by full run -> Invert the existing memory.md assertion and point it at the new store
[ ] TDD: No file outside `tasks/archive/` and `specs/` references `tasks/memory.md`, `tasks/lessons.md`, or `tasks/bugs.md` — verify by grep across both skill trees, hooks, `CLAUDE.md`, `README.md`, `install.sh` -> Update all 11 canonical skills plus copies, both hooks, `CLAUDE.md`, `README.md`, and `install.sh`
[ ] TDD: `session-start.sh` reports store counts in one line, dumps no document bodies, and its banner grows by at most one line — verify by running the hook against a seeded store and diffing banner length -> Rewrite the memory/lessons block as a count line
[ ] TDD: `pre-compact.sh` flushes to the new destinations — verify by running it and reading the output paths -> Update the flush targets
[ ] TDD: `/learn` writes `tasks/solutions/<category>/<slug>.md` with the date in frontmatter, scores overlap across the five dimensions, updates rather than duplicates at High, and carries the grounding rule — verify by reading against spec § M3 -> Rewrite `learn/SKILL.md`
[ ] TDD: `/debug` and `debug/templates/bug-report-template.md` write bug-track documents with valid frontmatter — verify by reading both against the schema -> Update the skill and template
[ ] TDD: `/memory-maintain` sweeps the store for stale, contradicted, and `needs_review` documents — verify by reading against spec § M3 -> Add the sweep passes
[ ] TDD: `/sync` detects an unmigrated store and instructs the user to run the migration script — verify by reading the post-sync step -> Add the detection step to `sync/SKILL.md`
[ ] TDD: `install.sh` and `project-template/tasks/` seed `solutions/README.md`, `history.md`, and `concepts.md`, and no longer seed `lessons.md` or `bugs.md` — verify by listing the template and reading the seed block -> Update the seeds
[ ] TDD: `tasks/concepts.md` exists seeded with this harness's vocabulary (tier, gate, register, drift, ceiling, store), and `/learn` adds an entry when a learning surfaces project-specific vocabulary with no separate prompt — verify by reading both -> Seed the glossary; add the side-effect capture step to `/learn`
[ ] TDD: `/memory-maintain` prunes entries that are not project-specific vocabulary — verify by reading the prune rule -> Add the concepts prune pass
[ ] TDD: `CLAUDE.md` Key Directories lists `tasks/solutions/`, `tasks/history.md`, and `tasks/concepts.md` and no longer lists the retired files — verify by reading the table -> Update Key Directories and the Session Start Checklist

## Active Spec
- specs/compound-engineering-adoption.md

## How to Resume
1. Read this file and `tasks/todo.md`
2. Read `tasks/memory.md` for project context
3. Continue from the first `[~]` (or `[ ]`) item in `tasks/todo.md`
