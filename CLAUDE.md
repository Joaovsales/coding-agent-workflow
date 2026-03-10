# Claude Code Project Rules

> Primary configuration for Claude Code. Rules apply to all sessions in this repository.

## Session Start Checklist

At the start of every session:
1. Read `.claude/memory.md` for persistent patterns and lessons
2. Check `tasks/todo.md` for in-progress work
3. Check `tasks/lessons.md` for self-improvement notes

---

## Workflow: Spec → Plan → TDD

### 1. Spec First
For every non-trivial feature, distill the request into a formal Spec before writing any code:
- Create `specs/[feature-name].md` with: Behavior / Inputs / Outputs / Edge Cases / Acceptance Criteria
- Use the `/plan` skill to run this interactively with the user

### 2. Plan Before Code (Hard Gate)
- Write a step-by-step plan to `tasks/todo.md` before touching any source code
- Each task format: `[ ] TDD: [Test Name] -> [Impl Detail]`
- Ask user: _"Does this plan meet your requirements? Confirm with 'y' to begin."_
- **Do not proceed without user confirmation**

### 3. TDD Loop
For every task in `tasks/todo.md`:
1. Write a failing test → confirm it fails
2. Write minimal code to pass → confirm it passes
3. Refactor against Clean Code principles
4. Mark `[x]` in `tasks/todo.md`

### 4. Self-Improvement
After any user correction: update `tasks/lessons.md` with the root cause and prevention rule.
At session end: run `/learn` to persist insights to `.claude/memory.md`.

---

## Agents — `.claude/agents/`

Use specialized agents to keep the main context window clean.

| Agent | Best For |
|-------|---------|
| `planner` | Spec writing, task breakdown, architecture decisions |
| `backend-developer` | APIs, databases, auth, performance, security |
| `frontend-developer` | React/Vue/Angular components, responsive UI |
| `frontend-design-validator` | Validate UI against design specs |
| `code-reviewer` | Post-implementation quality review (invoke proactively) |
| `code-debugger` | Debugging failing tests and runtime errors |
| `security-reviewer` | OWASP checks, auth flows, injection vectors |
| `content-generator-expert` | PDF pipeline, semantic search, recommendations |
| `context-document-optimizer` | Compress large docs for token efficiency |

**Delegation rule**: Use subagents for research, exploration, and parallel analysis. One focused task per subagent.

---

## Skills — `.claude/commands/`

Invoke with `/skill-name` in the chat.

| Skill | Purpose |
|-------|---------|
| `/plan` | Interactive spec + plan mode before coding |
| `/tdd` | Enter TDD workflow for current `tasks/todo.md` |
| `/learn` | Capture session learnings into `.claude/memory.md` |
| `/checkpoint` | Snapshot current progress for handoff/pause |
| `/security-scan` | Security audit on changed files |
| `/wrap-up-session` | Parallel review, tests, cleanup, commit, push |
| `/orchestrate-subagents` | Coordinate multi-agent implementation |
| `/pre-qa-smoke-test` | Pre-push quality smoke test |

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
.claude/commands/   → Skills invokable with /command-name
.claude/hooks/      → Lifecycle automation scripts
tasks/todo.md       → Active task plan (single source of truth)
tasks/lessons.md    → Self-improvement patterns
tasks/checkpoint.md → Session snapshots
conductor/          → Workflow, tech stack, product docs
specs/              → Feature specifications
```
