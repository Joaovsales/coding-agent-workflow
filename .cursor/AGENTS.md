# Available Subagents

> This file documents agents available for both Claude Code (`.claude/agents/`) and Cursor IDE.
> In Claude Code, agents are invoked via the Agent tool with `subagent_type`.
> In Cursor, use `@agent-name` syntax in the chat.

## Claude Code Agents (`.claude/agents/`)

### Planning & Architecture
| Agent | Purpose |
|-------|---------|
| `planner` | Spec writing, task breakdown, requirements interview, architecture decisions |

### Development
| Agent | Purpose |
|-------|---------|
| `backend-developer` | APIs, databases, auth, caching, performance, OWASP security |
| `frontend-developer` | React/Vue/Angular components, responsive UI, accessibility |
| `frontend-design-validator` | Validate UI against design reference documents |

### Quality & Security
| Agent | Purpose |
|-------|---------|
| `code-reviewer` | Post-implementation quality review — Clean Code, SOLID, bugs |
| `code-debugger` | Root-cause analysis for errors, test failures, runtime bugs |
| `security-reviewer` | OWASP checks, injection vectors, auth flows, data exposure |

### Domain Specialists
| Agent | Purpose |
|-------|---------|
| `content-generator-expert` | PDF pipeline, semantic search, recommendations, SSE |
| `context-document-optimizer` | Compress large docs for token-efficient AI context |

---

## Additional Agents (Cursor / general reference)

These agents can be used for additional specializations. In Claude Code, describe the role explicitly in your Agent tool call.

### Core Development
- **api-designer** — REST/GraphQL design, OpenAPI specs, versioning strategies
- **fullstack-developer** — End-to-end feature implementation, frontend-backend integration
- **ui-designer** — Component design, design system implementation, WCAG compliance

### Infrastructure
- **mobile-developer** — React Native, Flutter, iOS (Swift), Android (Kotlin)
- **electron-pro** — Cross-platform desktop apps, native OS integration
- **websocket-engineer** — Real-time WebSocket, Socket.io, WebRTC
- **graphql-architect** — GraphQL schema, DataLoader, Federation, Subscriptions
- **microservices-architect** — Service decomposition, API gateway, distributed tracing

---

## Usage in Claude Code

The Agent tool accepts a `subagent_type` matching the filename in `.claude/agents/` (without `.md`):

```
subagent_type: "planner"
subagent_type: "backend-developer"
subagent_type: "code-reviewer"
subagent_type: "security-reviewer"
```

For agents not in `.claude/agents/`, use `general-purpose` and describe the role in the prompt.

## Usage in Cursor

```
@backend-developer optimize the payment API
@frontend-developer create a responsive upload component
@code-reviewer review the authentication changes
```

## Delegation Guidelines

- **One task per agent** — focused context produces better outputs
- **Chain agents** — design → implement → review → security scan
- **Reference files explicitly** — use @filename or provide full paths in the prompt
- **Validate outputs** — always check agent work before moving to the next step
