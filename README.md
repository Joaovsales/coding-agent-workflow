# Coding Agent Workflow

A reusable coding agent configuration system for **Claude Code** — consolidating rules, subagents, skills, hooks, and workflows that enforce spec-driven, TDD-first development.

## Quick Start

1. Copy this repo's `.claude/` directory and `CLAUDE.md` into your project root
2. Optionally copy `.cursor/` for Cursor IDE support
3. Claude Code reads `CLAUDE.md` automatically on every session

---

## Directory Structure

```
.
├── CLAUDE.md                        ← Primary Claude Code config (read this first)
├── .claude/
│   ├── memory.md                    ← Persistent project memory (updated via /learn)
│   ├── settings.json                ← Hook configuration
│   ├── agents/                      ← Specialized Claude Code subagents
│   │   ├── planner.md               ← Spec writing + task planning
│   │   ├── backend-developer.md
│   │   ├── frontend-developer.md
│   │   ├── frontend-design-validator.md
│   │   ├── code-reviewer.md
│   │   ├── code-debugger.md
│   │   ├── security-reviewer.md     ← OWASP security audits
│   │   ├── content-generator-expert.md
│   │   └── context-document-optimizer.md
│   ├── commands/                    ← Skills invokable with /command-name
│   │   ├── plan.md                  ← /plan — spec + plan mode
│   │   ├── tdd.md                   ← /tdd — TDD workflow
│   │   ├── learn.md                 ← /learn — capture session learnings
│   │   ├── checkpoint.md            ← /checkpoint — save session snapshot
│   │   ├── security-scan.md         ← /security-scan — security review
│   │   ├── wrap-up-session.md       ← /wrap-up-session — review, test, commit
│   │   ├── orchestrate-subagents.md ← /orchestrate-subagents — multi-agent execution
│   │   └── pre-qa-smoke-test.md     ← /pre-qa-smoke-test — pre-push checks
│   └── hooks/
│       ├── session-start.sh         ← Prints memory + active tasks at session start
│       └── auto-test-runner.sh      ← Runs tests on file save, creates failure tasks
├── .cursor/                         ← Cursor IDE integration (secondary)
│   ├── AGENTS.md                    ← Agent reference for Cursor + Claude Code
│   ├── commands/                    ← Cursor command palette entries
│   └── rules/                       ← Auto-loaded Cursor rules (.mdc)
├── conductor/                       ← Project management
│   ├── workflow.md                  ← Task workflow + verification protocol
│   ├── tech-stack.md                ← Technology decisions
│   ├── product.md                   ← Product overview
│   ├── product-guidelines.md        ← UX + brand guidelines
│   └── code_styleguides/            ← Python + TypeScript style guides
├── tasks/
│   └── todo.md                      ← Active task plan (single source of truth)
├── awesome-claude-code-subagents/   ← 72+ categorized subagent library
└── makefile                         ← Build + test automation
```

---

## Skills (Claude Code Commands)

Invoke with `/skill-name` in any Claude Code session:

| Skill | What It Does |
|-------|-------------|
| `/plan` | Interviews you about requirements, writes a spec + TDD task plan |
| `/tdd` | Walks through the TDD loop for tasks in `tasks/todo.md` |
| `/learn` | Extracts session patterns and saves them to `.claude/memory.md` |
| `/checkpoint` | Saves a progress snapshot to `tasks/checkpoint.md` |
| `/security-scan` | Audits changed files for OWASP vulnerabilities |
| `/wrap-up-session` | Parallel code review, runs tests, commits and pushes |
| `/orchestrate-subagents` | Coordinates specialized agents for complex features |
| `/pre-qa-smoke-test` | Pre-push quality checks |

---

## Agents

| Agent | Use When |
|-------|---------|
| `planner` | Before any feature — spec and task planning |
| `backend-developer` | APIs, databases, auth, performance |
| `frontend-developer` | UI components, responsive design |
| `frontend-design-validator` | Verify UI matches design references |
| `code-reviewer` | After implementation — quality review |
| `code-debugger` | Debugging errors and test failures |
| `security-reviewer` | Before merging — security audit |
| `content-generator-expert` | PDF pipeline, search, AI content generation |
| `context-document-optimizer` | Compress docs for AI consumption |

---

## Hooks

| Hook | Trigger | What It Does |
|------|---------|-------------|
| `session-start.sh` | Session start | Prints memory, active tasks, git status |
| `auto-test-runner.sh` | After Bash tool use | Runs tests on changed files, creates failure task files |

---

## Workflow

```
Feature Request
    │
    ▼
/plan ──► spec + task list in tasks/todo.md
    │
    ▼ (user confirms 'y')
/tdd ──► failing test → code → pass → refactor → [x]
    │
    ▼ (all tasks done)
/security-scan ──► check changed files
    │
    ▼
/wrap-up-session ──► parallel review → tests → commit → push
    │
    ▼
/learn ──► save insights to .claude/memory.md
```

---

## Sources

- [shanraisshan/claude-code-best-practice](https://github.com/shanraisshan/claude-code-best-practice) — Command/agent/skill architecture
- [affaan-m/everything-claude-code](https://github.com/affaan-m/everything-claude-code) — Memory system, hook lifecycle, continuous learning
- Internal projects: PDF Idea Generator v2, PIX Receipt Tracker
