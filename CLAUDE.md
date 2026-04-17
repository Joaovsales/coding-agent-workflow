# Claude Code Project Rules

> Primary configuration for Claude Code. Rules apply to all sessions in this repository.

## Session Start Checklist

At the start of every session:
1. Read `.claude/memory.md` for persistent patterns and lessons
2. Check `tasks/todo.md` for in-progress work
3. Check `tasks/lessons.md` for self-improvement notes

---

## Workflow: PRD → Plan → Build → Wrap Up

### 0. PRD (Greenfield Projects Only)
For new projects, start with `/prd` to interview and produce:
- `specs/prd-<name>.md` — full Product Requirements Document
- `tasks/backlog.md` — ordered work items grouped by phase
- `tasks/project-context.md` — compressed agent briefing (auto-updated, never edit manually)

### 1. Spec First
For every non-trivial feature (or backlog item), distill the request into a formal Spec before writing any code:
- Create `specs/[feature-name].md` with: Behavior / Inputs / Outputs / Edge Cases / Acceptance Criteria
- Use the `/plan` skill to run this interactively with the user
- `/plan` accepts an optional backlog item argument: `/plan <item-name>`

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
**Before** `/wrap-up-session`: if any acceptance criterion in the touched specs describes user-facing behavior, run `/verify-e2e` first. Unit tests alone do not close a user-flow AC. The wrap-up E2E Coverage Gate (Step 6.3) will halt and prompt if user-facing ACs lack a `tasks/e2e-log.md` entry for the current commit.
At session end: run `/wrap-up-session` to sync learnings, tests, push, and **verify the deployment build** (Step 8). If the project has a `## Deployment Targets` section in this file, wrap-up will not claim success until the post-push build resolves green — looping a `code-debugger` fix cycle up to 3 times before escalating.

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
| `critic` | `sonnet` | Adversarial quality gate for plans, code, and specs |
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
- **Coding agents** (`backend-developer`, `frontend-developer`, `code-reviewer`, `code-debugger`, `frontend-design-validator`, `context-document-optimizer`, `security-reviewer`, `critic`): `model: "sonnet"`
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
| `/prd` | Interview user about greenfield project, produce PRD + backlog + agent context file |
| `/brainstorm` | Divergent design exploration: multi-option proposals, trade-offs, design approval before `/plan` |
| `/plan` | Interview user, write spec, create task breakdown in `tasks/todo.md`. Accepts optional backlog item argument |
| `/build` | Autonomous orchestrator: TDD + sub-agents + 2-stage review + parallel dispatch + simplify + spec validation |
| `/debug` | Investigate & fix bugs: root cause analysis, architecture questioning, bug register, lessons, `/loop` test verification |
| `/tdd` | Execute TDD loop for tasks in `tasks/todo.md` (manual, with user checkpoints) |
| `/verify` | Enforce evidence-based verification before any completion claims — no shortcuts |
| `/receive-review` | Process code review feedback: technical evaluation, pushback protocol, anti-performative agreement |
| `/simplify` | Review changed code for reuse, quality, complexity; fix issues found |
| `/deslop` | Detect and remove AI-generated anti-patterns (hedge words, over-abstraction, filler code) |
| `/learn` | Extract session patterns and persist to `.claude/memory.md` |
| `/checkpoint` | Snapshot progress to `tasks/checkpoint.md` for handoff or pause |
| `/security-scan` | OWASP-focused audit on recently changed files |
| `/start-qa` | Restart app, health check, launch browser with log monitoring for manual QA |
| `/setup-deployment` | One-time interactive bootstrap: scan for deploy signals, write `## Deployment Targets` routing into this file |
| `/verify-deployment` | Wait for post-push deployment build, fetch logs on failure, loop a `code-debugger` fix cycle up to 3 iterations before escalating |
| `/wrap-up-session` | Sync learnings, update task/bug registers, run tests, verify, merge worktree, push, **then verify deployment build (Step 8)** |
| `/writing-skills` | Author new skills with proper structure, iron laws, and reference docs |
| `/sync` | Pull latest skills, hooks, agents from the template repo into the current project |
| `/verify-e2e` | Force end-to-end browser walkthrough of user-facing acceptance criteria; writes evidence to `tasks/e2e-log.md` |
| `/folder-context-optimization` | Sweep a folder for legacy/unused files, propose archival |

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

## Tool Preference Ladder

Before reaching for a generic CLI, check this ladder. Using project-specific MCPs first avoids auth prompts, password walls, and flaky subprocess output.

| Domain | Prefer | Over |
|---|---|---|
| Supabase DB / migrations / schema | `mcp__supabase__apply_migration`, `execute_sql`, `get_logs` | `supabase db push`, `psql` |
| Vercel deploys / logs | `mcp__vercel__get_deployment_build_logs`, `get_runtime_logs` | `vercel logs` |
| GitHub PRs / reviews / CI | `mcp__github__*` | `gh` CLI |
| Library docs | `mcp__context7__resolve-library-id` → `get-library-docs` | Web search, guessing from memory |
| Browser E2E validation | Playwright/Chrome MCP with real cookie-based auth | Headless `curl` + token injection |

**Rule:** If a CLI asks for a password or fails auth twice, STOP and use the MCP. Do not guess credentials, do not retry with `--password` flags.

---

## Observability Discipline

Recurring jobs (cron, smoke tests, health checks, `/loop` tasks) must follow **failure-only reporting**:

- **Success path:** silent (exit 0, no log line, no notification)
- **Failure path:** loud (structured error, actionable context, exit non-zero)
- Never log "15/15 passed" every iteration — it trains the reader to ignore the channel

If a passing run must be recorded, write it to a metrics sink (counter, gauge), not to a human-readable log or chat channel.

---

## Quality Gate

Before marking any task complete, confirm:
- [ ] All relevant tests pass
- [ ] New code has ≥80% test coverage
- [ ] **Every user-facing acceptance criterion has an e2e walkthrough recorded in `tasks/e2e-log.md`** (see `/verify-e2e`)
- [ ] No linting or type errors
- [ ] Code passes Clean Code + SOLID review
- [ ] No new security vulnerabilities

---

## Key Directories

```
.claude/agents/            → Specialized subagents (invoked via Agent tool)
.claude/skills/            → Skills invokable with /skill-name
.claude/hooks/             → Lifecycle automation scripts
.claude/deployments/       → Per-service deployment runbooks (adapter pattern for /verify-deployment)
specs/                     → Feature specifications
specs/prd-<name>.md        → Product Requirements Document (from /prd)
tasks/backlog.md           → Ordered work items by phase (from /prd)
tasks/project-context.md   → Compressed agent briefing (auto-generated, do not edit manually)
tasks/todo.md              → Active task plan for current feature (from /plan)
tasks/bugs.md              → Bug register (opened/fixed per session)
tasks/lessons.md           → Self-improvement patterns
tasks/checkpoint.md        → Session snapshots
tasks/deploy-state.json    → Per-session deployment iteration state (gitignored)
tasks/deploy-report.md     → Deployment failure report (written by /verify-deployment after max iterations)
```

---

## Deployment Verification

This template repo has no active deployment targets. Downstream projects: run `/setup-deployment` to populate a `## Deployment Targets` section here. Schema reference: `.claude/deployments/README.md`.
