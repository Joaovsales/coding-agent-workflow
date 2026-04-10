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

## Deployment Verification — Schema Reference (Inactive Example)

> ⚠ **THIS REPO HAS NO ACTIVE DEPLOYMENT TARGETS.** This is the template repo and it doesn't deploy anywhere. The block below documents the schema that downstream projects will populate via `/setup-deployment`. The section header is intentionally **not** the literal `## Deployment Targets` so that `/verify-deployment` and `session-start.sh` treat this repo as having no Deployment Targets and skip silently.

**Downstream projects** that want to enable deployment verification should run `/setup-deployment`, which writes a real `## Deployment Targets` section near the bottom of this file (matched by the exact-match regex `^## Deployment Targets[[:space:]]*$`).

The schema below uses indented code blocks (not fenced) so no `## Deployment Targets` line appears at column 0 in this template repo. A real configured project would look like this:

        ## Deployment Targets

        > Populated by /setup-deployment. Read by /verify-deployment.
        > Delete this section to disable deployment verification for this project.

        | Service | Runbook                          | Triggers on branch | Project ID    |
        |---------|----------------------------------|--------------------|---------------|
        | Railway | .claude/deployments/railway.md   | main               | my-api-prod   |
        | Vercel  | .claude/deployments/vercel.md    | main               | acme/marketing |

        **Config:**
        - Max fix iterations: 3
        - Build timeout: 15m
        - Preferred status source: github-checks

**Schema rules:**

- The section heading must be **exactly** `## Deployment Targets` (no trailing text). `/verify-deployment` and the session-start hook both match this header with the regex `^## Deployment Targets[[:space:]]*$` so any extra text disables verification.
- `Service` — display name (free-form, used in reports)
- `Runbook` — relative path to a runbook file in `.claude/deployments/` whose frontmatter declares the service-specific contract
- `Triggers on branch` — exact branch name or glob (e.g. `preview/*`); only targets matching the current branch are verified on a given push
- `Project ID` — free-form string interpolated into the runbook's `dashboard_url_template`; consult each runbook for the expected format

**Config block** (optional, overrides runbook defaults):

- `Max fix iterations` — how many times `/verify-deployment` will loop the `code-debugger` fix cycle before escalating
- `Build timeout` — max wait per build attempt before declaring `TIMEOUT`
- `Preferred status source` — `github-checks` (default) or `cli`

To add a new deployment service, drop a runbook file into `.claude/deployments/<service>.md` following the contract in `.claude/deployments/README.md`, then re-run `/setup-deployment`.
