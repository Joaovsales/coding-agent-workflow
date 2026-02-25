# Available Claude Code Subagents

This project has access to specialized Claude Code subagents installed globally in `~/.cursor/agents/`.

## How to Use Agents in Cursor

To invoke an agent, use the `@` symbol followed by the agent name in your prompt:

```
@backend-developer help me optimize the payment API endpoints
@frontend-developer create a responsive upload component
```

You can also use the Task tool to delegate work to these specialized agents.

## Installed Agents

### Core Development Agents

#### @api-designer
- **Description**: Senior API architect specializing in REST and GraphQL design
- **Best For**: 
  - Designing RESTful APIs with proper HTTP semantics
  - GraphQL schema design and resolver optimization
  - API versioning strategies
  - OpenAPI/Swagger documentation
  - Rate limiting and pagination patterns

#### @backend-developer
- **Description**: Senior backend engineer specializing in scalable API development and microservices architecture
- **Best For**:
  - Building robust server-side solutions (Node.js, Python, Go)
  - Database schema design and optimization
  - Authentication and authorization implementation
  - Caching strategies and performance optimization
  - Security measures following OWASP guidelines
  - Test coverage and error handling

#### @frontend-developer
- **Description**: Expert in modern frontend development and user interfaces
- **Best For**:
  - React, Vue, Angular applications
  - Responsive UI component development
  - State management and performance optimization
  - Accessibility and cross-browser compatibility
  - Modern build tools and bundlers

#### @fullstack-developer
- **Description**: Full-stack engineer with expertise across the entire development stack
- **Best For**:
  - End-to-end feature implementation
  - Frontend-backend integration
  - Database to UI data flow
  - Complete application architecture
  - System-wide optimizations

#### @ui-designer
- **Description**: UI/UX specialist focused on beautiful, accessible interfaces
- **Best For**:
  - Component design and styling
  - Design system implementation
  - Accessibility compliance (WCAG)
  - Responsive design patterns
  - CSS architecture and animations

#### @mobile-developer
- **Description**: Mobile application expert for iOS, Android, and cross-platform development
- **Best For**:
  - React Native and Flutter applications
  - Native iOS (Swift) and Android (Kotlin) development
  - Mobile-specific UI/UX patterns
  - App Store deployment
  - Mobile performance optimization

#### @electron-pro
- **Description**: Desktop application specialist using Electron framework
- **Best For**:
  - Cross-platform desktop applications
  - Native OS integration
  - Application packaging and distribution
  - Auto-update mechanisms
  - System tray and native menus

#### @websocket-engineer
- **Description**: Real-time communication specialist
- **Best For**:
  - WebSocket server and client implementation
  - Real-time data synchronization
  - Socket.io and WebRTC integration
  - Pub/sub patterns
  - Connection management and reconnection strategies

#### @graphql-architect
- **Description**: GraphQL expert for modern API development
- **Best For**:
  - GraphQL schema design
  - Resolver optimization and DataLoader
  - Federation and microservices
  - Subscription handling
  - Apollo Server/Client configuration

#### @microservices-architect
- **Description**: Distributed systems expert specializing in microservices architecture
- **Best For**:
  - Service decomposition strategies
  - Inter-service communication patterns
  - API gateway design
  - Service discovery and load balancing
  - Distributed tracing and monitoring

## Installing Additional Agents

If you need more specialized agents, you can install them using the interactive installer:

```bash
cd ~/PROJECT-pix-receipt-tracker/awesome-claude-code-subagents
./install-agents.sh
```

Then copy them to Cursor's directory:

```bash
cp -r ~/.claude/agents/* ~/.cursor/agents/
```

### Available Categories

1. **Core Development** (✓ installed) - Essential development agents
2. **Language Specialists** - Python, JavaScript, Go, Rust, etc.
3. **Infrastructure** - DevOps, Docker, Kubernetes, Cloud
4. **Quality & Security** - Testing, code review, security audits
5. **Data & AI** - Data engineering, ML, database optimization
6. **Developer Experience** - Documentation, CI/CD, Git workflows
7. **Specialized Domains** - Blockchain, IoT, embedded systems
8. **Business & Product** - Product management, analytics
9. **Meta Orchestration** - Multi-agent coordination, task distribution
10. **Research & Analysis** - Code archaeology, technical research

## Examples

### Example 1: Building a New API Endpoint
```
@api-designer I need to design a RESTful API for receipt upload with validation

After design is approved:
@backend-developer implement the receipt upload API endpoint with proper error handling
```

### Example 2: Creating a Complete Feature
```
@fullstack-developer create a payment confirmation screen that:
- Displays payment details from the database
- Shows uploaded receipt preview
- Allows editing before final submission
- Integrates with existing Supabase backend
```

### Example 3: UI Improvements
```
@ui-designer redesign the file upload component to be more modern and accessible
@frontend-developer implement the new design with proper TypeScript types
```

## Tips

- **Be Specific**: Provide clear context about your project structure and requirements
- **Chain Agents**: Use different agents for different aspects (design → implementation → review)
- **Reference Files**: Use `@filename` to include relevant files in the context
- **Leverage Expertise**: Each agent has specialized knowledge - use the right agent for the task

## Project Context

This is a PIX Receipt Tracker application built with:
- **Frontend**: Next.js 14 + React + TypeScript
- **Backend**: Supabase (PostgreSQL + Storage + Auth)
- **Deployment**: Cloud-based (no local backend)
- **Key Features**: File upload, payment tracking, receipt management

When working with agents, mention these technologies for better context.

## Cursor Cloud specific instructions

### Repository Nature

This is a **documentation and configuration-only repository** (meta repo). It contains AI coding agent rules, workflow configurations, product specifications, style guides, and a `makefile`. There is **no application source code, no dependency manifests, no Dockerfiles, and no runnable application** in this repo. The `makefile` references a separate application codebase ("PDF Idea Generator v2") that is not present here.

### Available Tooling

- **Markdown lint**: `markdownlint` (installed globally via npm). Run with:
  ```
  markdownlint '**/*.md' --ignore node_modules --ignore .git
  ```
  Add `--disable MD013` to suppress line-length warnings (stylistic, not structural).
- **Makefile validation**: `make -n <target>` dry-runs to verify syntax. All targets parse correctly but cannot execute since Docker Compose files and application code are absent.

### Key Directories

| Directory | Purpose |
|---|---|
| `.cursor/rules/` | Auto-loaded Cursor IDE rules (`.mdc` files) |
| `.cursor/commands/` | Cursor command palette scripts |
| `.claude/agents/` | 7 specialized Claude agent definitions |
| `.claude/hooks/` | Auto-test runner hook scripts |
| `conductor/` | Product specs, tech stack docs, workflow, style guides, feature tracks |

### Gotchas

- The `makefile` targets (`make up`, `make test`, etc.) all depend on Docker Compose and `.env` files that do not exist in this repo. They are designed for the companion application repo.
- The `awesome-claude-code-subagents/` directory is empty despite being referenced in `README.md`.
- There are no automated tests to run in this repo.
