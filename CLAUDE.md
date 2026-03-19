# Claude Code Project Rules

> Primary configuration for Claude Code. Rules apply to all sessions in this repository.

## Session Start Checklist

At the start of every session:
1. Read `.claude/memory.md` for persistent patterns and lessons
2. Check `tasks/todo.md` for in-progress work
3. Check `tasks/lessons.md` for self-improvement notes

---

## Workflow: Spec → Plan → Build → Wrap Up

### 1. Spec First
For every non-trivial feature, distill the request into a formal Spec before writing any code:
- Create `specs/[feature-name].md` with: Behavior / Inputs / Outputs / Edge Cases / Acceptance Criteria
- Use the `/plan` skill to run this interactively with the user

### 2. Plan Before Code (Hard Gate)
- Write a step-by-step plan to `tasks/todo.md` before touching any source code
- Each task format: `[ ] TDD: [Test Name] -> [Impl Detail]`
- Ask user: _"Does this plan meet your requirements? Confirm with 'y' to begin."_
- **Do not proceed without user confirmation**

### 3. Build (Autonomous Execution)
Run `/build` to execute the plan autonomously:
- Delegates tasks to appropriate sub-agents (`backend-developer`, `frontend-developer`, etc.)
- Each task follows TDD: failing test → minimal impl → refactor → mark `[x]`
- Full test suite after every task (no regressions)
- Runs `/simplify` on all changed files when tasks are done
- Validates every acceptance criterion from the spec
- Reports results — no user prompts between tasks

### 4. Wrap Up
After any user correction: note the root cause in `tasks/lessons.md`.
At session end: run `/wrap-up-session` to sync learnings, tests, and push.

---

## Agents — `.claude/agents/`

Use specialized agents to keep the main context window clean.

| Agent | Model | Best For |
|-------|-------|---------|
| `planner` | `opus` | Spec writing, task breakdown, architecture decisions |
| `backend-developer` | `sonnet` | APIs, databases, auth, performance, security |
| `frontend-developer` | `sonnet` | React/Vue/Angular components, responsive UI |
| `frontend-design-validator` | `sonnet` | Validate UI against design specs |
| `code-reviewer` | `sonnet` | Post-implementation quality review (invoke proactively) |
| `code-debugger` | `sonnet` | Debugging failing tests and runtime errors |
| `security-reviewer` | `sonnet` | OWASP checks, auth flows, injection vectors |
| `content-generator-expert` | `sonnet` | PDF pipeline, semantic search, recommendations |
| `context-document-optimizer` | `sonnet` | Compress large docs for token efficiency |

**Delegation rule**: Use subagents for research, exploration, and parallel analysis. One focused task per subagent.

---

## Model Routing Rules

**These rules are mandatory for all agent delegations and tool invocations.**

| Operation | Model | Rationale |
|-----------|-------|-----------|
| `/plan` — spec writing, architecture, task breakdown | `opus` | Strongest reasoning for design decisions |
| `/build` — TDD, coding, debugging, code review | `sonnet` | Fast, capable coding model |
| Codebase search, grep, file exploration | `haiku` | Fastest model for simple lookups |

### Enforcement

When invoking the **Agent tool**, always pass the `model` parameter:

- **Planning agents** (`planner`): `model: "opus"`
- **Coding agents** (`backend-developer`, `frontend-developer`, `code-reviewer`, `code-debugger`, `content-generator-expert`, `frontend-design-validator`, `context-document-optimizer`, `security-reviewer`): `model: "sonnet"`
- **Explore agents** (codebase search, file discovery, grep): `model: "haiku"`

### Rules

1. **Never use `opus` for code writing** — it is reserved for planning and architecture
2. **Never use `haiku` for code writing or planning** — it is for search/exploration only
3. **Always pass `model` explicitly** — do not rely on defaults
4. Agent YAML front-matter declares the intended model; the Agent tool `model` parameter enforces it

---

## Skills — `.claude/skills/`

Invoke with `/skill-name` in the chat. Each skill is a directory under `.claude/skills/` containing a `SKILL.md` with YAML frontmatter.

| Skill | Purpose |
|-------|---------|
| `/plan` | Interview user, write spec, create task breakdown in `tasks/todo.md` |
| `/build` | Autonomous orchestrator: TDD + sub-agents + simplify + spec validation |
| `/debug` | Investigate & fix bugs: root cause analysis, bug register, lessons, `/loop` test verification |
| `/tdd` | Execute TDD loop for tasks in `tasks/todo.md` (manual, with user checkpoints) |
| `/simplify` | Review changed code for reuse, quality, complexity; fix issues found |
| `/learn` | Extract session patterns and persist to `.claude/memory.md` |
| `/checkpoint` | Snapshot progress to `tasks/checkpoint.md` for handoff or pause |
| `/security-scan` | OWASP-focused audit on recently changed files |
| `/start-qa` | Restart app, health check, launch browser with log monitoring for manual QA |
| `/wrap-up-session` | Sync learnings, update task/bug registers, run tests, push to main |
| `/sync` | Pull latest skills, hooks, agents from the template repo into the current project |

---

## Core Principles

**Never Guess — Verify**
Use Read/Grep/Glob tools before editing. Check file existence. Validate assumptions from actual contents.

**Context7 MCP**
Fetch live library docs before implementing with external packages. Use `resolve-library-id` then `get-library-docs`.

**Clean Code**
- Functions ≤20 LOC, ≤3 parameters
- Single abstraction level per function
- Meaningful names (no abbreviations, no `data`, `info`, `manager`)
- DRY: no duplicated logic; KISS: straightforward over clever

**SOLID Principles**
- Single Responsibility: one reason to change per class/function
- Open/Closed: extend via strategy/registry, not conditionals
- Liskov: subclasses must honor contracts
- Interface Segregation: small, focused interfaces
- Dependency Inversion: inject dependencies, depend on abstractions

**Minimal Impact**
Only touch what's necessary. No unsolicited refactors. No proactive documentation files.

**No Silent Failures**
Explicit errors only. No `except: pass`. No fallback values hiding broken assumptions.

**File & Git Hygiene**
Prefer editing existing files. Never skip git hooks. Keep commits atomic and descriptive.

---

## Quality Gate

Before marking any task complete, confirm:
- [ ] All relevant tests pass
- [ ] New code has ≥80% test coverage
- [ ] No linting or type errors
- [ ] Code passes Clean Code + SOLID review
- [ ] No new security vulnerabilities

---

## Key Directories

```
.claude/agents/     → Specialized subagents (invoked via Agent tool)
.claude/skills/     → Skills invokable with /skill-name
.claude/hooks/      → Lifecycle automation scripts
tasks/todo.md       → Active task plan (single source of truth)
tasks/bugs.md       → Bug register (opened/fixed per session)
tasks/lessons.md    → Self-improvement patterns
tasks/checkpoint.md → Session snapshots
conductor/          → Workflow, tech stack, product docs
specs/              → Feature specifications
```
