#!/usr/bin/env bash
# install.sh — One-time setup to enforce Claude workflow across all projects.
#
# What this does:
#   1. Copies skills and agents into ~/.claude/ (global Claude Code config)
#   2. Copies .agents/ into ~/.agents/ (harness-neutral skills + WORKFLOW.md)
#   3. Installs a global SessionStart hook that orients Claude in any project
#   4. Sets up a git template dir so `git init` auto-installs a post-init hook
#   5. Configures ~/.claude/settings.json with skills path
#   6. Configures Pi (~/.pi/agent/settings.json) if installed
#   7. Prints a `newproject` shell function to add to your .bashrc / .zshrc
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

# ── 2. Global skills (backwards-compat copy) ─────────────────────────────────
step "Installing global skills → ~/.claude/skills/"
rm -rf "$CLAUDE_HOME/skills"
cp -r "$REPO_DIR/.claude/skills" "$CLAUDE_HOME/skills"
ok "copied" "$(find "$CLAUDE_HOME/skills" -name 'SKILL.md' | wc -l | tr -d ' ') skills (backwards-compat)"

# ── 3. Shared workflow → ~/.agents/ ──────────────────────────────────────────
step "Installing shared workflow → ~/.agents/"
mkdir -p "$HOME/.agents"
cp -r "$REPO_DIR/.agents/"* "$HOME/.agents/"
ok "copied" "~/.agents/ ($(find "$HOME/.agents/skills" -name 'SKILL.md' | wc -l | tr -d ' ') skills, WORKFLOW.md)"

# ── 4. Global agents ─────────────────────────────────────────────────────────
step "Installing global agents → ~/.claude/agents/"
mkdir -p "$CLAUDE_HOME/agents"
cp "$REPO_DIR/.claude/agents/"*.md "$CLAUDE_HOME/agents/"
ok "copied" "$(ls "$CLAUDE_HOME/agents/"*.md | wc -l | tr -d ' ') agents"

# ── 5. Global SessionStart hook ───────────────────────────────────────────────
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

# ── 6. Configure skills path in ~/.claude/settings.json ──────────────────────
step "Configuring skill paths in ~/.claude/settings.json"
if command -v jq > /dev/null 2>&1; then
  if jq -e '.skills | index("~/.agents/skills")' "$SETTINGS_FILE" > /dev/null 2>&1; then
    ok "already" "~/.agents/skills already in settings"
  else
    jq '.skills = ((.skills // []) + ["~/.agents/skills"])' "$SETTINGS_FILE" > /tmp/settings_tmp.json && mv /tmp/settings_tmp.json "$SETTINGS_FILE"
    ok "updated" "added ~/.agents/skills to settings.json skills array"
  fi
else
  echo "  NOTE: jq not found — skill path not automatically added to settings.json."
  echo "  Add manually: .skills = [\"~/.agents/skills\"] in $SETTINGS_FILE"
fi

# ── 7. Configure Pi if installed ─────────────────────────────────────────────
PI_SETTINGS="$HOME/.pi/agent/settings.json"
if [ -f "$PI_SETTINGS" ]; then
  step "Configuring Pi skill paths"
  if command -v jq > /dev/null 2>&1; then
    if jq -e '.skills | index("~/.agents/skills")' "$PI_SETTINGS" > /dev/null 2>&1; then
      ok "already" "~/.agents/skills already in Pi settings"
    else
      jq '.skills = ((.skills // []) + ["~/.agents/skills"])' "$PI_SETTINGS" > /tmp/pi_settings_tmp.json && mv /tmp/pi_settings_tmp.json "$PI_SETTINGS"
      ok "updated" "added ~/.agents/skills to Pi settings"
    fi
  else
    echo "  NOTE: jq not found — Pi skill path not automatically added."
  fi
fi

# ── 8. Git template directory ─────────────────────────────────────────────────
step "Setting up git template dir → $GIT_TEMPLATE_DIR"
mkdir -p "$GIT_TEMPLATE_DIR/hooks"

# pre-push hook: typecheck + lint before every git push (harness-agnostic)
cp "$REPO_DIR/.agents/git-hooks/pre-push" "$GIT_TEMPLATE_DIR/hooks/pre-push"
chmod +x "$GIT_TEMPLATE_DIR/hooks/pre-push"
ok "installed" "pre-push hook (typecheck + lint before every git push)"

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

# ── 9. Print newproject shell function ────────────────────────────────────────
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
