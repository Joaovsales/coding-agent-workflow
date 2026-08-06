# Checkpoint — 2026-08-06T17:51:45Z

> Auto-written by PreCompact hook (trigger: unknown). Re-read on resume.

## Git
- Branch: worktree-compound-engineering-adoption

```
 M .agents/skills/visual-plan/SKILL.md
 M .agents/skills/visual-recap/SKILL.md
 M .claude/skills/visual-plan/SKILL.md
 M .claude/skills/visual-recap/SKILL.md
 M tasks/todo.md
 M tests/test-doc-conventions.sh
?? specs/compound-engineering-adoption.md
?? tests/test-skill-frontmatter.sh
?? tests/test-skill-references.sh
```

## In-Progress & Pending Tasks (tasks/todo.md)
[ ] TDD: `CLAUDE.md` Model Routing defines `ceiling` as "omit the override, inherit the session model", names it the fallback where a harness cannot select per-agent models, and resolves `code-reviewer` / `security-reviewer` / `critic` to it — verify by reading the table end to end -> Add the `ceiling` row and resolution rule; reword "pass `model` explicitly on every Agent tool call" so it cannot be read as requiring an override for `ceiling` roles
[ ] TDD: `/build`'s Model Routing table and `/plan`'s Model Routing note agree with `CLAUDE.md` on which roles are `ceiling` — verify by cross-reading all three -> Update both skill tables
[ ] TDD: `tests/test-model-tiers.sh` fails if any `ceiling` role regains a pinned model in `.claude/agents/` or in a routing table — verify by seeding a `model: sonnet` line -> Write the guard; remove the existing `sonnet` pins from the three `ceiling` agent definitions
[ ] TDD: `/writing-skills` states the three-part prose admission test and names all three inadmissible categories (vague effort language, appended motivational rationale, off-drift-point repetition), plus the guard right-sizing rule — verify by reading against spec § M6 -> Add both sections to `writing-skills/SKILL.md`
[ ] TDD: `/receive-review` carries the Change/Verify/Consider classification, states that Verify and Consider items are not edited, and carries the four-step owning-layer protocol — verify by reading against spec § M6 -> Add the triage protocol to `receive-review/SKILL.md`
[ ] TDD: `CLAUDE.md` has an Independence Accounting subsection stating corroboration requires separately dispatched contexts, and the Review Gate Taxonomy block cross-references it — verify by reading both -> Add the subsection and the taxonomy note
[ ] TDD: `/wrap-up-session` Step 4 emits whether the four passes ran dispatched or inline, and names the lost corroboration when inline; no promotion occurs on same-context agreement — verify by reading Step 4 and the output block -> Add the disclosure requirement and the no-promotion rule; add the disclosure line to the output template
[ ] TDD: `/quality-gate` emits the same disclosure for Phase 3 and never promotes on inline agreement — verify by reading Phase 3 and the output block -> Add the disclosure and no-promotion rule
[ ] TDD: `/quality-gate` defines `severity`, `confidence`, `autofix_class`, and `owner` with a behavioral criterion for each of anchors 50/75/100, requires `file:line` evidence at 75+, demotes on absence, and auto-applies only `gated_auto` at 75+ — verify by reading against spec § M2 -> Rewrite the quality-gate finding model and apply gate
[ ] TDD: `/wrap-up-session`'s severity table carries all four axes and Step 5.1 enforcement is keyed on the combination, taking the more conservative `autofix_class` on disagreement and never widening — verify by reading the table and 5.1 -> Rewrite the severity classification and enforcement sections
[ ] TDD: A finding arriving with no `confidence` is handled as anchor 50 / `manual` and is reported rather than applied or discarded — verify by reading the degrade rule in both skills -> Add the backwards-compatibility rule to both
[ ] TDD: `code-reviewer`, `critic`, `security-reviewer`, and `software-design-expert-review` each emit all four fields with the evidence gate, in both trees — verify by reading all eight files -> Update the four agent definitions and copy
[ ] TDD: `/yolo`, `/auto-push`, and `/auto-improve` reach commit with no new user prompt introduced by the apply gate — verify by reading each skill's flow against the new gate -> Adjust the three loop skills only where the gate would otherwise block them
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

## Active Spec
- specs/compound-engineering-adoption.md

## How to Resume
1. Read this file and `tasks/todo.md`
2. Read `tasks/memory.md` for project context
3. Continue from the first `[~]` (or `[ ]`) item in `tasks/todo.md`
