# Available Subagents (Cursor)

> Subagents in `.cursor/agents/` — invoked via the Task tool with `subagent_type`.
> Claude Code uses `.claude/agents/` (same prompts, Claude-specific frontmatter).

## Planning & Architecture

| Agent | Purpose |
|-------|---------|
| `planner` | Spec writing, task breakdown, requirements interview, architecture decisions |

## Development

| Agent | Purpose |
|-------|---------|
| `backend-developer` | APIs, databases, auth, caching, performance, OWASP security |
| `frontend-developer` | React/Vue/Angular components, responsive UI, accessibility |
| `frontend-design-validator` | Validate UI against design reference documents |

## Quality & Security / Design

| Agent | Purpose |
|-------|---------|
| `code-reviewer` | Post-implementation quality review — Clean Code, SOLID, bugs |
| `code-debugger` | Root-cause analysis for errors, test failures, runtime bugs |
| `security-reviewer` | OWASP checks, injection vectors, auth flows, data exposure |
| `software-design-expert-review` | Read-only APOSD structural review — depth, leakage, error design |
| `critic` | Adversarial quality gate for plans, code, specs |

## Utilities

| Agent | Purpose |
|-------|---------|
| `context-document-optimizer` | Compress large docs for token-efficient AI context |

---

## Usage in Cursor

```
subagent_type: "planner"
subagent_type: "backend-developer"
subagent_type: "code-reviewer"
```

Review agents (`code-reviewer`, `security-reviewer`, `software-design-expert-review`, `critic`, `context-document-optimizer`, `frontend-design-validator`) are marked `readonly: true` — they report findings but do not edit code.

## Delegation Guidelines

- One task per subagent — focused context produces better outputs
- Chain agents — design → implement → review → security scan
- Reference files explicitly with full paths in the prompt
- Validate outputs before moving to the next step
