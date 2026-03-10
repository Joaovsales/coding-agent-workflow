# Project Memory

> Persistent knowledge base across Claude Code sessions.
> **Always read this at session start.**
> Updated via the `/learn` skill at session end.

---

## Project Context

**Repository**: `coding-agent-workflow`
**Purpose**: A reusable, project-agnostic coding agent configuration system — consolidated rules, subagents, skills, hooks, and workflows that enforce spec-driven, TDD-first development.

**Primary tools**:
- Claude Code (primary agent runtime)
- `.claude/agents/` — specialized subagents
- `.claude/commands/` — skills invokable with `/skill-name`
- `CLAUDE.md` — root-level Claude Code config

**Secondary (Cursor IDE, still functional)**:
- `.cursor/rules/` — auto-loaded Cursor rules
- `.cursor/commands/` — Cursor command palette commands

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

---

## Stack Reference

> Update this section when project tech stack changes.

**Backend**: Python + FastAPI, Supabase (PostgreSQL + pgvector), Redis + ARQ, AWS S3
**Frontend**: React + Vite, Radix UI + TailwindCSS
**Testing**: Pytest (backend), Vitest + Playwright (frontend)
**Infrastructure**: Docker Compose

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

_No sessions recorded yet._
