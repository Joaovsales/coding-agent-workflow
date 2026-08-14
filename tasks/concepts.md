# Concepts — Project Glossary

> Project-specific vocabulary: entities, named processes, and status terms whose
> meaning is **local to this project**. Accretes as a side effect of `/learn`,
> never as a separate chore; pruned by `/memory-maintain` — a term with a
> standard industry meaning does not belong here. Entry format: one bullet per
> term, alphabetical within its section: `- **term** — definition.`
>
> Sweep: done 2026-08-13

## Harness vocabulary

- **ceiling** — model-tier resolution meaning "omit the model override so the sub-agent inherits the session model"; not a model name. Reserved for the highest-stakes review roles.
- **drift** — divergence between the two skill trees (`.agents/` canonical vs `.claude/` copy) or between a downstream project and this template; caught by the parity tests and the session-start drift check.
- **gate** — a hard checkpoint that blocks progress until its condition holds (plan confirmation, quality gate, evidence gate). A review reports; a gate stops.
- **register** — a single append-oriented markdown file under `tasks/` recording one kind of thing (todo, history, checkpoint, this glossary).
- **store** — the typed learning store at `tasks/solutions/`: one document per learning, YAML frontmatter, grep-first retrieval. Replaces the retired monolithic `tasks/memory.md`.
- **tier** — a model-routing band (Ceiling / Planner / Builder / Reviewer / Scout), or an adoption phase in a multi-mechanism spec (Tier 1–3).

## Project vocabulary

- **canonical tree** — `.agents/`, the source of truth for skills and agent personas; `.claude/` holds the byte-identical copy. Edits land canonical-first, then are copied.
- **circuit breaker** — the `/build`/`/yolo` failure escalation: repeated task failures trigger the `/refresh` backstop, then planner-tier review, then a loop stop — never a silent retry spiral.
- **dispatch disclosure** — the required line in review output stating whether passes ran as separately dispatched agents or inline, naming the corroboration lost when inline.
- **downstream** — a project that installed this template via `install.sh` and receives updates through `/sync`; this repo is the upstream template.
- **harness** — an agent runtime the workflow supports (Claude Code, Pi); `harness: universal` prose must run identically on both.
- **heavy pass** — `/memory-maintain`'s every-5-sessions consolidation (Phases 1–4); contrast **light pass**, the bounded per-session work.
- **needs_review** — frontmatter flag marking a store document with inferred or missing required fields; resolved by `/memory-maintain` Phase 1.
- **parity** — the byte-identical requirement between the canonical tree and its `.claude/` copy, enforced by `tests/test-skill-parity.sh`.
- **shortcut** — a deliberate minimal implementation marked `TODO(shortcut):` with its limitation and upgrade path stated.
- **track** — one of the store's two document kinds, selected by `problem_type`: bug track (`symptoms`/`root_cause`/`resolution`) or knowledge track (`applies_when`).
