# Concepts — Project Glossary

> Project-specific vocabulary: entities, named processes, and status terms whose
> meaning is **local to this project**. Accretes as a side effect of `/learn`,
> never as a separate chore; pruned by `/memory-maintain` — a term with a
> standard industry meaning does not belong here. Entry format: one bullet per
> term, alphabetical within its section: `- **term** — definition.`
>
> Sweep: pending
> (While pending, the next `/memory-maintain` run performs a one-time full sweep
> of README, `specs/`, docs, and domain identifiers to populate this file, then
> flips the line above to `Sweep: done YYYY-MM-DD`. Maintenance mode after that.)

## Harness vocabulary

- **ceiling** — model-tier resolution meaning "omit the model override so the sub-agent inherits the session model"; not a model name. Reserved for the highest-stakes review roles.
- **drift** — divergence between this project's synced workflow files and the template repo; caught by the session-start drift check.
- **gate** — a hard checkpoint that blocks progress until its condition holds (plan confirmation, quality gate, evidence gate). A review reports; a gate stops.
- **register** — a single append-oriented markdown file under `tasks/` recording one kind of thing (todo, history, checkpoint, this glossary).
- **store** — the typed learning store at `tasks/solutions/`: one document per learning, YAML frontmatter, grep-first retrieval.
- **tier** — a model-routing band (Ceiling / Planner / Builder / Reviewer / Scout).

## Project vocabulary

_Populated by the bootstrap sweep and by `/learn`; nothing captured yet._
