# Coding Agent Rules Repository

This repository consolidates all rules, subagents, commands, and workflow configurations from multiple projects.

## Directory Structure

```
PROJECT-Coding-agent-rules/
├── .cursor/                          # Cursor IDE configurations
│   ├── AGENTS.md                     # Agent configuration file
│   ├── commands/                     # Custom commands
│   │   ├── orchestrate-subagents.md
│   │   ├── pre-qa-smoke-test.md
│   │   └── wrap-up-session.md
│   └── rules/                        # Cursor coding rules
│       ├── create-prd.mdc
│       ├── master-coding-agent-rules.mdc
│       └── process-task-list.mdc
├── .claude/                          # Claude AI configurations
│   ├── agents/                       # Specialized Claude agents (7 agents)
│   │   ├── backend-developer.md
│   │   ├── code-debugger.md
│   │   ├── code-reviewer.md
│   │   ├── content-generator-expert.md
│   │   ├── context-document-optimizer.md
│   │   ├── frontend-design-validator.md
│   │   └── frontend-developer.md
│   └── hooks/                        # Pre/Post hooks
│       ├── auto-test-runner.ps1
│       └── auto-test-runner.sh
├── awesome-claude-code-subagents/    # 72+ specialized subagents
│   └── categories/
│       ├── 01-core-development/      # Core development roles
│       ├── 02-language-specialists/  # Language-specific experts
│       ├── 03-infrastructure/        # DevOps & Infrastructure
│       ├── 04-quality-security/      # QA, Testing, Security
│       ├── 05-data-ai/              # Data Science & AI/ML
│       ├── 06-developer-experience/ # DX & Tooling
│       ├── 07-specialized-domains/  # Domain-specific experts
│       ├── 08-business-product/     # Business & Product roles
│       ├── 09-meta-orchestration/   # Orchestration & Coordination
│       └── 10-research-analysis/    # Research & Analysis
├── conductor/                        # Project management & workflows
│   ├── code_styleguides/            # Code style guides
│   │   ├── python.md
│   │   └── typescript.md
│   ├── product-guidelines.md
│   ├── product.md
│   ├── tech-stack.md
│   ├── tracks/                      # Feature tracks
│   ├── tracks.md
│   └── workflow.md
└── makefile                         # Build and automation commands
```

## Sources

### From PROJECT-pix-receipt-tracker:
- AGENTS.md configuration
- `orchestrate-subagents.md` command
- Complete awesome-claude-code-subagents library (72+ subagents)

### From PROJETO_pdf-idea-generator:
- 3 Cursor rules (mdc files)
- 2 additional commands
- 7 specialized Claude agents
- 2 hook scripts (PowerShell and Bash)
- Conductor workflow and project management files
- makefile with build commands

## Statistics

- **Total markdown files**: 166+
- **Subagent categories**: 10
- **Specialized Claude agents**: 7
- **Commands**: 3
- **Rules**: 3
- **Hooks**: 2

## Usage

### Cursor IDE
The `.cursor/` directory contains rules and commands that integrate with Cursor IDE:
- Rules in `.cursor/rules/` are automatically loaded by Cursor
- Commands in `.cursor/commands/` can be invoked via Cursor's command palette
- `AGENTS.md` configures available agents for the project

### Claude AI
The `.claude/` directory contains specialized agents and hooks:
- Agents can be invoked for specific tasks
- Hooks automate testing and validation workflows

### Awesome Claude Code Subagents
The `awesome-claude-code-subagents/` directory provides 72+ specialized subagents organized by category:
- Use `install-agents.sh` to set up subagents
- Browse categories to find the right expert for your task
- Each subagent has specific expertise and capabilities

### Conductor
The `conductor/` directory provides project management and workflow structure:
- Style guides for consistent code quality
- Product guidelines and technical specifications
- Feature tracking system
- Workflow documentation

### Makefile
The `makefile` contains build commands and automation scripts for common development tasks.

## License

This is a consolidated repository. Original licenses from source projects apply to their respective components.
# coding-agent-workflow
