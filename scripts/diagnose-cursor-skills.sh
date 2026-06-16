#!/usr/bin/env bash
# diagnose-cursor-skills.sh — Check why skills (e.g. /build) aren't in Cursor slash menu.
#
# Usage:
#   bash ~/coding-agent-workflow/scripts/diagnose-cursor-skills.sh
#   bash ~/coding-agent-workflow/scripts/diagnose-cursor-skills.sh /path/to/pci-eol

set -uo pipefail

TARGET="${1:-.}"
cd "$TARGET"
ROOT="$(pwd)"

ok()   { echo "  ✓ $1"; }
fail() { echo "  ✗ $1"; }
warn() { echo "  ⚠ $1"; }

echo "Cursor skills diagnostic — $ROOT"
echo "────────────────────────────────────────"

# ── Global install ───────────────────────────────────────────────────────────
echo ""
echo "Global (~/.cursor + ~/.agents)"
GLOBAL_OK=1

if [ -f "$HOME/.agents/skills/build/SKILL.md" ]; then
  ok "~/.agents/skills/build/SKILL.md exists"
  if grep -q 'disable-model-invocation: false' "$HOME/.agents/skills/build/SKILL.md"; then
    ok "build has disable-model-invocation: false"
  else
    fail "build missing disable-model-invocation: false — run: cd ~/coding-agent-workflow && bash install.sh"
    GLOBAL_OK=0
  fi
else
  fail "~/.agents/skills/build/SKILL.md missing — run: cd ~/coding-agent-workflow && bash install.sh"
  GLOBAL_OK=0
fi

if [ -L "$HOME/.cursor/skills/build" ] || [ -f "$HOME/.cursor/skills/build/SKILL.md" ]; then
  ok "~/.cursor/skills/build present"
else
  warn "~/.cursor/skills/build missing — run install.sh"
  GLOBAL_OK=0
fi

GLOBAL_COUNT=$(ls "$HOME/.agents/skills/" 2>/dev/null | wc -l | tr -d ' ')
echo "  Global skill count: ${GLOBAL_COUNT:-0} (expect ≥23)"

# ── Project install ──────────────────────────────────────────────────────────
echo ""
echo "Project ($ROOT)"
PROJECT_OK=1

check_project_skill() {
  local name="$1" path=""
  for path in ".agents/skills/$name/SKILL.md" ".cursor/skills/$name/SKILL.md"; do
    if [ -f "$path" ]; then
      ok "project $path"
      if grep -q 'disable-model-invocation: false' "$path"; then
        ok "project $name has disable-model-invocation: false"
      else
        fail "project $name missing disable-model-invocation: false"
        PROJECT_OK=0
      fi
      return 0
    fi
  done
  if [ -L ".agents/skills" ] || [ -L ".cursor/skills" ]; then
    ok "project skills symlink present ($(ls -la .agents/skills .cursor/skills 2>/dev/null | head -1))"
    return 0
  fi
  return 1
}

if ! check_project_skill "build"; then
  warn "no project-level build skill — Cursor may not show /build without global install OR bootstrap"
  PROJECT_OK=0
fi

for f in CLAUDE.md .cursor/hooks.json; do
  if [ -f "$f" ]; then ok "$f"; else warn "$f missing (rules/hooks)"; fi
done

# ── Fix commands ───────────────────────────────────────────────────────────
echo ""
echo "Fix commands"
echo "────────────────────────────────────────"
if [ "$GLOBAL_OK" = "0" ]; then
  echo "1. Global install (run once on YOUR machine, not cloud agent):"
  echo "     cd ~/coding-agent-workflow && git pull && bash install.sh"
fi
if [ "$PROJECT_OK" = "0" ]; then
  echo "2. Bootstrap this project (installs skills + rules + hooks into repo):"
  echo "     bash ~/coding-agent-workflow/scripts/bootstrap-cursor.sh --force \"$ROOT\""
fi
echo "3. Restart Cursor completely (Quit app, reopen) — skills load at startup"
echo "4. In Cursor: Settings → Features → enable 'Third-party skills' (optional fallback)"
echo "5. Type /build in a NEW agent chat (not old threads)"

if [ "$GLOBAL_OK" = "1" ] && [ "$PROJECT_OK" = "1" ]; then
  echo ""
  ok "Config looks correct — if /build still missing, fully quit and restart Cursor"
fi
