# Claude Code Project Rules

> DO NOT EDIT — template-managed, overwritten by `/sync`.
> Project-specific rules go in `.claude/project.md`.
> Personal overrides go in `CLAUDE.local.md` (gitignored).

@.agents/WORKFLOW.md
@.claude/project.md
@CLAUDE.local.md

---

## Agents — `.claude/agents/`

| Agent | Model | Best For |
|-------|-------|---------|
| `planner` | `opus` | Spec writing, task breakdown, architecture decisions |
| `backend-developer` | `sonnet` | APIs, databases, auth, performance, security |
| `frontend-developer` | `sonnet` | React/Vue/Angular components, responsive UI |
| `frontend-design-validator` | `sonnet` | Validate UI against design specs |
| `code-reviewer` | `sonnet` | Post-implementation quality review |
| `code-debugger` | `sonnet` | Debugging failing tests and runtime errors |
| `security-reviewer` | `sonnet` | OWASP checks, auth flows, injection vectors |
| `critic` | `sonnet` | Adversarial quality gate for plans, code, specs |
| `context-document-optimizer` | `sonnet` | Compress large docs for token efficiency |

**Rule**: One focused task per subagent. Pass `model` explicitly on every Agent tool call.

---

## Model Routing

| Operation | Model |
|-----------|-------|
| `/plan` — spec writing, architecture | `opus` |
| `/build`, coding, debugging, review | `sonnet` |
| Codebase search, grep, file exploration | `haiku` |

Rules: never `opus` for code writing; never `haiku` for coding or planning; always pass `model` explicitly.

---

## Skills — `.agents/skills/`

| Skill | Purpose |
|-------|---------|
| `/prd` | Greenfield project interview → PRD + backlog + context file |
| `/brainstorm` | Divergent design exploration before `/plan` |
| `/plan` | Interview → spec → task breakdown in `tasks/todo.md` |
| `/build` | Autonomous TDD orchestrator with sub-agent delegation |
| `/debug` | Root cause analysis, bug register, loop verification |
| `/tdd` | Manual TDD loop with user checkpoints |
| `/verify` | Evidence-based verification gate (`--scope deployment\|e2e`) |
| `/quality-gate` | 3-phase post-build review: structural, AI anti-patterns, APOSD (invokes /aposd-guardrail) |
| `/aposd-guardrail` | APOSD design review: deep/shallow, info leakage, red flags, Go/No-Go verdict |
| `/receive-review` | Process code review feedback with pushback protocol |
| `/learn` | Extract session patterns → `memory.md` + `lessons.md` |
| `/checkpoint` | Snapshot progress to `tasks/checkpoint.md` |
| `/security-scan` | OWASP-focused audit on recently changed files |
| `/start-qa` | Restart app + health check + browser with log monitoring |
| `/wrap-up-session` | Learnings, tests, reviews, commit, push |
| `/writing-skills` | Author new skills with proper structure |
| `/sync` | Pull latest skills, hooks, agents from template repo |
| `/folder-context-optimization` | Sweep folder for legacy/unused files |
