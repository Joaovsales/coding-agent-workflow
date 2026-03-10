# Coding Agent Workflow

A reusable Claude Code configuration system that enforces **spec-driven, TDD-first development** across all your projects — with persistent memory, specialized agents, and a structured session lifecycle.

---

## What's Included

| Layer | What it does |
|-------|-------------|
| **CLAUDE.md** | Core rules: Spec → Plan → TDD workflow, Clean Code, SOLID, quality gate |
| **Skills** (`.claude/commands/`) | `/plan`, `/tdd`, `/learn`, `/checkpoint`, `/security-scan`, `/wrap-up-session` |
| **Agents** (`.claude/agents/`) | 9 specialized subagents for planning, coding, review, debugging, security |
| **Hooks** (`.claude/hooks/`) | Session start orientation + auto test runner on file save |
| **Memory** (`.claude/memory.md`) | Persistent patterns and session history, updated via `/learn` |

---

## Using This as Your Default for Every Project

Run `install.sh` once. It sets up three layers of enforcement that activate automatically for every future project.

### Step 1 — Clone and install

```bash
git clone <this-repo-url> ~/coding-agent-workflow
cd ~/coding-agent-workflow
bash install.sh
```

Then paste the printed `newproject()` function into your `~/.bashrc` or `~/.zshrc`:

```bash
source ~/.bashrc   # or source ~/.zshrc
```

### Step 2 — Start every new project with

```bash
newproject my-app
cd my-app
claude
```

That's it. Claude is fully oriented from the first message.

---

## What `install.sh` Does

### Layer 1 — Global Claude config (`~/.claude/`)

Copies your skills, agents, and CLAUDE.md into `~/.claude/`. Claude Code reads this directory for **every session in every project** — no per-project setup needed.

```
~/.claude/
├── CLAUDE.md          ← global rules (applies everywhere)
├── commands/          ← all skills available in every project
├── agents/            ← all agents available in every project
├── hooks/
│   └── session-start.sh
└── settings.json      ← registers the SessionStart hook globally
```

The **SessionStart hook** runs automatically at the start of every Claude Code session. It prints:
- Active patterns and lessons from `.claude/memory.md`
- Pending and in-progress tasks from `tasks/todo.md`
- Recent lessons from `tasks/lessons.md`
- Current git branch and uncommitted change count

### Layer 2 — Git template directory (`~/.git-templates/`)

Sets `git config --global init.templateDir ~/.git-templates`. Every time you run `git init`, a `post-init` hook fires and copies this scaffold into the new repo (only if files don't already exist):

```
tasks/todo.md       ← active task plan
tasks/bugs.md       ← bug register
tasks/lessons.md    ← session lessons
specs/              ← feature specification directory
CLAUDE.md           ← project-specific overrides
```

### Layer 3 — `newproject` shell function

```bash
newproject() {
  local name="${1:?Usage: newproject <project-name>}"
  mkdir -p "$name" && cd "$name"
  git init                        # triggers post-init hook → copies Claude scaffold
  echo "# $name" > README.md
  git add . && git commit -m "chore: init project with Claude workflow scaffold"
}
```

Wraps `git init` (which triggers layer 2) and makes an initial commit. One command from zero to a fully scaffolded, Claude-ready project.

---

## Keeping It Up to Date

Re-running `install.sh` is safe — it overwrites `~/.claude/` with the latest version:

```bash
cd ~/coding-agent-workflow
git pull
bash install.sh
```

---

## Adding to an Existing Project

No need to use `newproject`. Just copy the scaffold files manually:

```bash
cp ~/coding-agent-workflow/project-template/tasks/todo.md tasks/
cp ~/coding-agent-workflow/project-template/tasks/bugs.md tasks/
cp ~/coding-agent-workflow/project-template/tasks/lessons.md tasks/
cp ~/coding-agent-workflow/project-template/CLAUDE.md .
mkdir -p specs
```

Then edit `CLAUDE.md` to fill in your project's stack and test commands.

---

## Session Workflow

```
Feature Request
    │
    ▼
/plan ──► interviews you → writes spec → task list in tasks/todo.md
    │
    ▼  (confirm with 'y')
/tdd ──► failing test → minimal code → pass → refactor → mark [x]
    │
    ▼  (all tasks done)
/security-scan ──► audit changed files for OWASP issues
    │
    ▼
/wrap-up-session ──► sync learnings → update tasks + bugs → run tests → push
```

---

## Skills

Invoke with `/skill-name` in any Claude Code session:

| Skill | What It Does |
|-------|-------------|
| `/plan` | Interviews you, writes a spec to `specs/`, creates TDD task plan in `tasks/todo.md` |
| `/tdd` | Walks through the TDD loop: failing test → code → pass → refactor → `[x]` |
| `/learn` | Extracts session patterns and appends them to `.claude/memory.md` |
| `/checkpoint` | Saves a progress snapshot to `tasks/checkpoint.md` for handoff or pause |
| `/security-scan` | Audits changed files against OWASP top 10; blocks commit on HIGH/MEDIUM |
| `/wrap-up-session` | Syncs learnings, updates task + bug registers, runs tests, pushes to main |

---

## Agents

Claude delegates to these automatically (or you can invoke them via the Agent tool):

| Agent | Best For |
|-------|---------|
| `planner` | Spec writing, task breakdown, architecture decisions |
| `backend-developer` | APIs, databases, auth, performance, security |
| `frontend-developer` | React/Vue/Angular components, responsive UI |
| `frontend-design-validator` | Verify UI matches design references |
| `code-reviewer` | Post-implementation quality review (invoked proactively) |
| `code-debugger` | Debugging failing tests and runtime errors |
| `security-reviewer` | OWASP checks, auth flows, injection vectors |
| `content-generator-expert` | PDF pipeline, semantic search, AI content generation |
| `context-document-optimizer` | Compress large docs for token efficiency |

---

## Hooks

| Hook | Trigger | What It Does |
|------|---------|-------------|
| `session-start.sh` | Session start | Prints memory, active tasks, lessons, git status |
| `auto-test-runner.sh` | After every Bash tool use | Runs tests on changed files; creates task entries on failure |

---

## Directory Structure

```
.
├── install.sh                       ← Run once to set up global Claude config
├── CLAUDE.md                        ← Core rules (copied to ~/.claude/CLAUDE.md)
├── project-template/                ← Scaffold copied into new projects
│   ├── CLAUDE.md                    ← Project-specific override template
│   └── tasks/
│       ├── todo.md
│       ├── bugs.md
│       └── lessons.md
├── .claude/
│   ├── memory.md                    ← Persistent project memory (updated via /learn)
│   ├── settings.json                ← Hook configuration
│   ├── agents/                      ← 9 specialized subagents
│   ├── commands/                    ← 6 skills (/plan, /tdd, /learn, /checkpoint, /security-scan, /wrap-up-session)
│   └── hooks/
│       ├── session-start.sh
│       └── auto-test-runner.sh
├── tasks/
│   └── todo.md                      ← Active task plan for this repo
├── specs/                           ← Feature specifications
├── awesome-claude-code-subagents/   ← Extended subagent library
└── makefile                         ← Build + test automation
```

---

## Sources

- [shanraisshan/claude-code-best-practice](https://github.com/shanraisshan/claude-code-best-practice) — Command/agent/skill architecture
- [affaan-m/everything-claude-code](https://github.com/affaan-m/everything-claude-code) — Memory system, hook lifecycle, continuous learning
