#!/usr/bin/env bash
# install.sh — One-time setup to enforce Claude workflow across all projects.
#
# What this does:
#   1. Copies skills and agents into ~/.claude/ (global Claude Code config)
#   2. Copies .agents/ into ~/.agents/ (harness-neutral skills — all harnesses)
#   3. Installs global Cursor config into ~/.cursor/ (agents, skills, hooks)
#   4. Installs a global SessionStart hook that orients Claude in any project
#   5. Sets up a git template dir so `git init` auto-bootstraps workflow scaffold
#   6. Configures ~/.claude/settings.json with skills path
#   7. Configures Pi (~/.pi/agent/settings.json) if installed
#   8. Prints a `newproject` shell function to add to your .bashrc / .zshrc
#
# Usage:
#   git clone <this-repo> ~/coding-agent-workflow
#   cd ~/coding-agent-workflow && bash install.sh

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_HOME="$HOME/.claude"
CURSOR_HOME="$HOME/.cursor"
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
ok "copied" "~/.agents/ ($(find "$HOME/.agents/skills" -name 'SKILL.md' | wc -l | tr -d ' ') skills)"

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

# ── 7b. Global Cursor configuration ───────────────────────────────────────────
step "Installing global Cursor config → ~/.cursor/"
mkdir -p "$CURSOR_HOME/agents" "$CURSOR_HOME/hooks/lib" "$CURSOR_HOME/skills"

# Remember repo path for bootstrap script and updates
echo "$REPO_DIR" > "$CURSOR_HOME/.workflow-repo"

# Subagents — available in every project
cp "$REPO_DIR/.cursor/agents/"*.md "$CURSOR_HOME/agents/"
ok "copied" "$(ls "$CURSOR_HOME/agents/"*.md | wc -l | tr -d ' ') agents → ~/.cursor/agents/"

# Skills — symlink from canonical ~/.agents/skills/
for skill_dir in "$HOME/.agents/skills/"*/; do
  [ -d "$skill_dir" ] || continue
  skill_name="$(basename "$skill_dir")"
  ln -sfn "$skill_dir" "$CURSOR_HOME/skills/$skill_name"
done
ok "linked" "$(find "$CURSOR_HOME/skills" -maxdepth 1 -type l 2>/dev/null | wc -l | tr -d ' ') skills → ~/.cursor/skills/"

# Hooks — workspace-aware scripts (resolve project root from hook stdin)
cp -r "$REPO_DIR/.cursor/hooks/"* "$CURSOR_HOME/hooks/"
chmod +x "$CURSOR_HOME/hooks/"*.sh 2>/dev/null || true
chmod +x "$CURSOR_HOME/hooks/lib/"*.sh 2>/dev/null || true
ok "copied" "~/.cursor/hooks/ (session-start, session-stop, resolve-workspace)"

# hooks.json — create or note manual merge
CURSOR_HOOKS_FILE="$CURSOR_HOME/hooks.json"
CURSOR_SESSION_CMD="bash $CURSOR_HOME/hooks/session-start.sh"
CURSOR_STOP_CMD="bash $CURSOR_HOME/hooks/session-stop.sh"

if [ ! -f "$CURSOR_HOOKS_FILE" ]; then
  cat > "$CURSOR_HOOKS_FILE" <<EOF
{
  "version": 1,
  "hooks": {
    "sessionStart": [{ "command": "$CURSOR_SESSION_CMD" }],
    "stop": [{ "command": "$CURSOR_STOP_CMD" }]
  }
}
EOF
  ok "created" "~/.cursor/hooks.json"
elif command -v jq > /dev/null 2>&1; then
  if jq -e '.hooks.sessionStart[]? | select(.command | test("session-start"))' "$CURSOR_HOOKS_FILE" > /dev/null 2>&1; then
    ok "already present" "sessionStart hook in ~/.cursor/hooks.json"
  else
    jq --arg start "$CURSOR_SESSION_CMD" --arg stop "$CURSOR_STOP_CMD" \
      '.hooks.sessionStart = ((.hooks.sessionStart // []) + [{command: $start}]) |
       .hooks.stop = ((.hooks.stop // []) + [{command: $stop}])' \
      "$CURSOR_HOOKS_FILE" > /tmp/cursor_hooks_tmp.json \
      && mv /tmp/cursor_hooks_tmp.json "$CURSOR_HOOKS_FILE"
    ok "merged" "sessionStart/stop into ~/.cursor/hooks.json"
  fi
else
  echo "  NOTE: ~/.cursor/hooks.json exists — merge sessionStart/stop manually:"
  echo "    sessionStart: $CURSOR_SESSION_CMD"
  echo "    stop: $CURSOR_STOP_CMD"
fi

echo ""
echo "  Cursor global install:"
echo "    Skills     → ~/.agents/skills/ + ~/.cursor/skills/ (symlinks)"
echo "    Subagents  → ~/.cursor/agents/"
echo "    Hooks      → ~/.cursor/hooks.json (all projects; resolves workspace from stdin)"
echo "    Rules      → per-project via git init scaffold OR: bash $REPO_DIR/scripts/bootstrap-cursor.sh"
echo "  Optional: Settings → Rules → User Rules — paste session checklist from CLAUDE.md for extra always-on guidance."

# ── 8. Git template directory ─────────────────────────────────────────────────
step "Setting up git template dir → $GIT_TEMPLATE_DIR"
mkdir -p "$GIT_TEMPLATE_DIR/hooks"

# pre-push hook: typecheck + lint before every git push (harness-agnostic)
cp "$REPO_DIR/.agents/git-hooks/pre-push" "$GIT_TEMPLATE_DIR/hooks/pre-push"
chmod +x "$GIT_TEMPLATE_DIR/hooks/pre-push"
ok "installed" "pre-push hook (typecheck + lint before every git push)"

# post-init hook: bootstraps workflow scaffold into newly init'd repos
cat > "$GIT_TEMPLATE_DIR/hooks/post-init" <<HOOK
#!/usr/bin/env bash
# Auto-installed by coding-agent-workflow/install.sh
# Bootstraps Cursor/Claude workflow scaffold after every \`git init\`.
# Safe: skips files that already exist (use bootstrap-cursor.sh --force to overwrite).

WORKFLOW_REPO="\${HOME}/coding-agent-workflow"
if [ -f "\${HOME}/.cursor/.workflow-repo" ]; then
  WORKFLOW_REPO="\$(cat "\${HOME}/.cursor/.workflow-repo")"
fi

if [ ! -f "\${WORKFLOW_REPO}/scripts/bootstrap-cursor.sh" ]; then
  exit 0
fi

bash "\${WORKFLOW_REPO}/scripts/bootstrap-cursor.sh" "\$(git rev-parse --show-toplevel 2>/dev/null || pwd)" 2>/dev/null || true
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
  git init                        # triggers post-init hook → bootstraps workflow scaffold
  echo "# $name" > README.md
  git add . && git commit -m "chore: init project with coding-agent-workflow scaffold"
  echo ""
  echo "Project '$name' ready. Open in Cursor or run: claude"
}
# ─────────────────────────────────────────────────────────────────────────────

SHELLCONFIG

echo ""
echo -e "${BOLD}Done.${RESET}"
echo ""
echo "  Reload your shell:  source ~/.bashrc  (or ~/.zshrc)"
echo "  Start a new project: newproject my-app"
echo "  Existing repo: bash $REPO_DIR/scripts/bootstrap-cursor.sh"
echo ""
echo "  Claude Code: orients at session start via ~/.claude/hooks/session-start.sh"
echo "  Cursor: skills + subagents global; hooks global; rules via CLAUDE.md per project"
echo "  Re-run install.sh after git pull to update global config."
echo ""
