# Spec: Migrate Commands to Skills Format

## Behavior
Convert all 10 command files in `.claude/commands/` to the skills directory format under `.claude/skills/`. Each command becomes a skill directory containing a `SKILL.md` file with YAML frontmatter. The old command files are removed. `CLAUDE.md` is updated to reflect the new structure. User-facing invocation (`/plan`, `/build`, etc.) remains unchanged.

## Inputs
- 10 existing command files in `.claude/commands/`
- 1 existing skill (`debug`) as the reference format
- `CLAUDE.md` referencing the old structure

## Outputs
- 10 new skill directories under `.claude/skills/`, each with `SKILL.md`
- Old `.claude/commands/` directory removed
- `CLAUDE.md` updated (directory references, skills table)
- `/sync` command updated to sync `.claude/skills/` instead of `.claude/commands/`

## YAML Frontmatter Mapping

Each skill gets frontmatter based on its behavior:

| Command | `name` | `description` (for auto-invocation) | `argument-hint` | `disable-model-invocation` |
|---------|--------|--------------------------------------|------------------|----------------------------|
| build | build | Execute the task plan from tasks/todo.md autonomously using TDD with sub-agent delegation. Use after /plan is confirmed. | — | true |
| checkpoint | checkpoint | Snapshot current session progress to tasks/checkpoint.md for handoff or pause. | — | false |
| learn | learn | Extract durable patterns from the current session and persist to memory.md and lessons.md. | — | false |
| plan | plan | Interview user, write a feature spec, and create a TDD task breakdown. Use for any non-trivial feature before coding. | "[feature description]" | true |
| security-scan | security-scan | OWASP-focused security audit on recently changed files. Use after code changes to check for vulnerabilities. | — | false |
| simplify | simplify | Review changed code for reuse, clean code, and SOLID violations, then fix issues found. | "[optional file path]" | false |
| start-qa | start-qa | Discover project config, restart app, and launch browser for manual QA testing. | — | true |
| sync | sync | Pull latest skills, hooks, agents, and config from the coding-agent-workflow template repo. | — | false |
| tdd | tdd | Execute TDD loop for tasks in tasks/todo.md with user checkpoints between steps. | — | false |
| wrap-up-session | wrap-up-session | Close session: sync learnings, update registers, run tests, and push. | — | true |

### `disable-model-invocation` rationale
Set to `true` for orchestrator skills that primarily delegate to sub-agents (`build`, `plan`, `start-qa`, `wrap-up-session`). These coordinate work rather than performing it directly.

## Edge Cases
- `/sync` currently syncs `.claude/commands/` — must be updated to sync `.claude/skills/` instead
- `CLAUDE.md` references `.claude/commands/` in multiple places — all must be updated
- The `debug` skill already exists and must not be touched
- Command content (below the frontmatter) stays identical — no prompt changes

## Acceptance Criteria
- [ ] All 10 commands exist as `.claude/skills/[name]/SKILL.md` with correct YAML frontmatter
- [ ] `.claude/commands/` directory is removed
- [ ] `CLAUDE.md` references updated from `commands` to `skills`
- [ ] `/sync` skill references `.claude/skills/` instead of `.claude/commands/`
- [ ] `debug` skill is unchanged
- [ ] All skills are invokable via `/name` (same UX as before)

## Files Involved
- `.claude/commands/*.md` — source files (10, to be deleted)
- `.claude/skills/*/SKILL.md` — target files (10, to be created)
- `CLAUDE.md` — update directory references and skills table
- `.claude/commands/sync.md` → `.claude/skills/sync/SKILL.md` — update sync paths
