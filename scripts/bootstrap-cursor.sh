#!/usr/bin/env bash
# bootstrap-cursor.sh — Install workflow scaffold into the current project.
#
# Use when:
#   - Adding the workflow to an existing repo
#   - git init post-init hook (via install.sh git template)
#
# Usage:
#   bash ~/coding-agent-workflow/scripts/bootstrap-cursor.sh
#   bash ~/coding-agent-workflow/scripts/bootstrap-cursor.sh --force

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FORCE=0
TARGET="."

for arg in "$@"; do
  case "$arg" in
    --force) FORCE=1 ;;
    --help|-h)
      echo "Usage: bootstrap-cursor.sh [--force] [target-dir]"
      exit 0
      ;;
    --force|--help|-h) ;;
    *) TARGET="$arg" ;;
  esac
done

cd "$TARGET"
ROOT="$(pwd)"

install_file() {
  local src="$1" dst="$2"
  if [ -f "$dst" ] && [ "$FORCE" != "1" ]; then
    echo "  [workflow] skip (exists): $dst"
    return 0
  fi
  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
  echo "  [workflow] installed $dst"
}

install_tree() {
  local src="$1" dst="$2"
  if [ -d "$dst" ] && [ "$FORCE" != "1" ]; then
    echo "  [workflow] skip (exists): $dst/"
    return 0
  fi
  mkdir -p "$(dirname "$dst")"
  rm -rf "$dst"
  cp -r "$src" "$dst"
  echo "  [workflow] installed $dst/"
}

echo "Bootstrapping coding-agent-workflow into $ROOT"

install_file "$REPO_DIR/CLAUDE.md" "$ROOT/CLAUDE.md"
install_file "$REPO_DIR/.claude/project.md" "$ROOT/.claude/project.md"
install_tree "$REPO_DIR/.cursor/rules" "$ROOT/.cursor/rules"
install_file "$REPO_DIR/.cursor/hooks.json" "$ROOT/.cursor/hooks.json"
install_tree "$REPO_DIR/.cursor/hooks" "$ROOT/.cursor/hooks"
chmod +x "$ROOT/.cursor/hooks/"*.sh 2>/dev/null || true
chmod +x "$ROOT/.cursor/hooks/lib/"*.sh 2>/dev/null || true

for f in todo.md bugs.md lessons.md; do
  install_file "$REPO_DIR/project-template/tasks/$f" "$ROOT/tasks/$f"
done

if [ ! -d "$ROOT/specs" ]; then
  mkdir -p "$ROOT/specs"
  [ -f "$REPO_DIR/specs/README.md" ] && cp "$REPO_DIR/specs/README.md" "$ROOT/specs/README.md"
  echo "  [workflow] created specs/"
fi

install_file "$REPO_DIR/AGENTS.md" "$ROOT/AGENTS.md"

if git rev-parse --is-inside-work-tree &>/dev/null; then
  if ! git remote get-url workflow &>/dev/null 2>&1; then
    echo ""
    echo "  Tip: add template remote for /sync updates:"
    echo "    git remote add workflow https://github.com/Joaovsales/coding-agent-workflow.git"
  fi
fi

echo ""
echo "Done. Skills and subagents load globally (run install.sh once)."
echo "Project rules/hooks installed in .cursor/ and CLAUDE.md."
