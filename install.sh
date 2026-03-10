#!/usr/bin/env bash
# install.sh — One-time setup to enforce Claude workflow across all projects.
#
# What this does:
#   1. Copies skills and agents into ~/.claude/ (global Claude Code config)
#   2. Installs a global SessionStart hook that orients Claude in any project
#   3. Sets up a git template dir so `git init` auto-installs a post-init hook
#   4. Prints a `newproject` shell function to add to your .bashrc / .zshrc
#
# Usage:
#   git clone <this-repo> ~/coding-agent-workflow
#   cd ~/coding-agent-workflow && bash install.sh

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_HOME="$HOME/.claude"
GIT_TEMPLATE_DIR="$HOME/.git-templates"

GREEN='\033[0;32m'
BOLD='\033[1m'
RESET='\033[0m'

step() { echo -e "\n${BOLD}▶ $1${RESET}"; }
ok()   { echo -e "  ${GREEN}✓${RESET} $2"; }

# ── 1. Global CLAUDE.md ───────────────────────────────────────────────────────
step "Installing global CLAUDE.md"
mkdir -p "$CLAUDE_HOME"
cp "$REPO_DIR/CLAUDE.md" "$CLAUDE_HOME/CLAUDE.md"
ok "copied" "~/.claude/CLAUDE.md"

# ── 2. Global skills (commands) ───────────────────────────────────────────────
step "Installing global skills → ~/.claude/commands/"
mkdir -p "$CLAUDE_HOME/commands"
cp "$REPO_DIR/.claude/commands/"*.md "$CLAUDE_HOME/commands/"
ok "copied" "$(ls "$CLAUDE_HOME/commands/"*.md | wc -l | tr -d ' ') skills"

# ── 3. Global agents ─────────────────────────────────────────────────────────
step "Installing global agents → ~/.claude/agents/"
mkdir -p "$CLAUDE_HOME/agents"
cp "$REPO_DIR/.claude/agents/"*.md "$CLAUDE_HOME/agents/"
ok "copied" "$(ls "$CLAUDE_HOME/agents/"*.md | wc -l | tr -d ' ') agents"

# ── 4. Global SessionStart hook ───────────────────────────────────────────────
step "Installing global SessionStart hook"
mkdir -p "$CLAUDE_HOME/hooks"
cp "$REPO_DIR/.claude/hooks/session-start.sh" "$CLAUDE_HOME/hooks/session-start.sh"
chmod +x "$CLAUDE_HOME/hooks/session-start.sh"
ok "copied" "~/.claude/hooks/session-start.sh"

# Merge SessionStart into ~/.claude/settings.json (preserves existing settings)
SETTINGS_FILE="$CLAUDE_HOME/settings.json"
SESSION_HOOK_CMD="bash $CLAUDE_HOME/hooks/session-start.sh"

if [ ! -f "$SETTINGS_FILE" ]; then
  cat > "$SETTINGS_FILE" <<EOF
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "$SESSION_HOOK_CMD"
          }
        ]
      }
    ]
  }
}
EOF
  ok "created" "~/.claude/settings.json"
else
  # Check if SessionStart hook is already present
  if ! grep -q "session-start.sh" "$SETTINGS_FILE" 2>/dev/null; then
    echo ""
    echo "  NOTE: ~/.claude/settings.json already exists."
    echo "  Add this SessionStart hook manually if it's missing:"
    echo ""
    echo '    "SessionStart": [{"hooks": [{"type": "command", "command": "'"$SESSION_HOOK_CMD"'"}]}]'
    echo ""
  else
    ok "already present" "SessionStart hook in ~/.claude/settings.json"
  fi
fi

# ── 5. Git template directory ─────────────────────────────────────────────────
step "Setting up git template dir → $GIT_TEMPLATE_DIR"
mkdir -p "$GIT_TEMPLATE_DIR/hooks"

# post-init hook: copies Claude project scaffold into newly init'd repos
cat > "$GIT_TEMPLATE_DIR/hooks/post-init" <<'HOOK'
#!/usr/bin/env bash
# Auto-installed by coding-agent-workflow/install.sh
# Copies minimal Claude project scaffold after every `git init`.
# Safe: only runs if the files don't already exist.

PROJECT_TEMPLATE="$HOME/coding-agent-workflow/project-template"

if [ ! -d "$PROJECT_TEMPLATE" ]; then
  exit 0  # template not found — skip silently
fi

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

copy_if_missing() {
  local src="$PROJECT_TEMPLATE/$1"
  local dst="$REPO_ROOT/$1"
  if [ -f "$src" ] && [ ! -f "$dst" ]; then
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
    echo "  [claude] created $1"
  fi
}

copy_if_missing "CLAUDE.md"
copy_if_missing "tasks/todo.md"
copy_if_missing "tasks/bugs.md"
copy_if_missing "tasks/lessons.md"

if [ ! -d "$REPO_ROOT/specs" ]; then
  mkdir -p "$REPO_ROOT/specs"
  echo "  [claude] created specs/"
fi
HOOK
chmod +x "$GIT_TEMPLATE_DIR/hooks/post-init"

git config --global init.templateDir "$GIT_TEMPLATE_DIR"
ok "set" "git config --global init.templateDir $GIT_TEMPLATE_DIR"
ok "installed" "post-init hook (runs on every git init)"

# ── 6. Print newproject shell function ────────────────────────────────────────
step "Shell function — add this to your ~/.bashrc or ~/.zshrc"
cat <<'SHELLCONFIG'

# ── Claude Workflow: new project bootstrapper ─────────────────────────────────
newproject() {
  local name="${1:?Usage: newproject <project-name>}"
  mkdir -p "$name" && cd "$name"
  git init                        # triggers post-init hook → copies Claude scaffold
  echo "# $name" > README.md
  git add . && git commit -m "chore: init project with Claude workflow scaffold"
  echo ""
  echo "Project '$name' ready. Open with: claude"
}
# ─────────────────────────────────────────────────────────────────────────────

SHELLCONFIG

echo ""
echo -e "${BOLD}Done.${RESET}"
echo ""
echo "  Reload your shell:  source ~/.bashrc  (or ~/.zshrc)"
echo "  Start a new project: newproject my-app"
echo "  Or in an existing repo: copy project-template/ files in manually."
echo ""
echo "  Claude will now orient itself at session start in every project"
echo "  (memory, active tasks, lessons, git branch) via the global SessionStart hook."
echo ""
