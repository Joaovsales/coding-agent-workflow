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

_No patterns captured yet. Use `/learn` at session end to add entries._

---

## Session History

> Append entries here via `/learn`. Format:
> ### [YYYY-MM-DD] — [2-3 word summary]
> - Key changes: [bullet list]
> - Lessons added: [count or none]

### [2026-07-08] — Visual plan/recap skills
- Key changes: Added `/visual-plan` + `/visual-recap` (opt-in) that render self-contained HTML visual docs locally by wrapping the existing `html-presentation` generator; new `visual-render.py` post-processor injects diff coloring + tabsets. No external MCP/hosted service (adapted from BuilderIO/skills' hosted model).
- Pattern: To extend a `/sync`-managed skill's output without editing it, wrap it — a new skill owns a post-processor that operates on the managed skill's OUTPUT. Keeps the managed file untouched so `/sync` never clobbers the work.
- Pattern: The bash test suite enforces `.agents/` ↔ `.claude/` byte-identical skill parity (`test-skill-parity.sh`) + doc-convention token greps (`test-doc-conventions.sh`). Any new skill must be authored in BOTH trees identically and wired into both tests.
- Lessons added: none (captured as patterns above)
