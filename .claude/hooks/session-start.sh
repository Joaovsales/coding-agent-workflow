#!/bin/bash
# Claude Code Session Start Hook
# Orients the agent at the beginning of every session by surfacing memory,
# active tasks, and recent lessons without requiring manual reads.

set -euo pipefail

DIVIDER="════════════════════════════════════════"

echo ""
echo "$DIVIDER"
echo "  SESSION START — Coding Agent Workflow"
echo "$DIVIDER"

# ── Memory ──────────────────────────────────────────────────────────────────
MEMORY_FILE=".claude/memory.md"
if [ -f "$MEMORY_FILE" ]; then
  echo ""
  echo "📚  MEMORY  (.claude/memory.md)"
  echo "────────────────────────────────"
  # Show just the Patterns & Lessons and Architecture Decisions sections
  awk '/^## Architecture Decisions/,/^## (Stack|Patterns|Session)/' "$MEMORY_FILE" | head -20
  echo ""
  awk '/^## Patterns & Lessons/,/^## Session History/' "$MEMORY_FILE" | head -30
else
  echo ""
  echo "📚  No .claude/memory.md found — consider running /learn to initialise it."
fi

# ── Active Tasks ─────────────────────────────────────────────────────────────
TODO_FILE="tasks/todo.md"
if [ -f "$TODO_FILE" ]; then
  PENDING=$(grep -c '^\s*\[ \]' "$TODO_FILE" 2>/dev/null || true)
  IN_PROGRESS=$(grep -c '^\s*\[~\]' "$TODO_FILE" 2>/dev/null || true)
  echo ""
  echo "📋  ACTIVE TASKS  (tasks/todo.md) — $PENDING pending, $IN_PROGRESS in-progress"
  echo "────────────────────────────────"
  grep -E '^\s*\[([ ~])\]' "$TODO_FILE" | head -10 || echo "  None."
else
  echo ""
  echo "📋  No tasks/todo.md found."
fi

# ── Lessons ──────────────────────────────────────────────────────────────────
LESSONS_FILE="tasks/lessons.md"
if [ -f "$LESSONS_FILE" ] && [ -s "$LESSONS_FILE" ]; then
  echo ""
  echo "📖  RECENT LESSONS  (tasks/lessons.md)"
  echo "────────────────────────────────"
  tail -20 "$LESSONS_FILE"
fi

# ── Git Status ───────────────────────────────────────────────────────────────
if git rev-parse --is-inside-work-tree &>/dev/null; then
  BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
  UNCOMMITTED=$(git status --short 2>/dev/null | wc -l | tr -d ' ')
  echo ""
  echo "🌿  GIT  branch: $BRANCH | uncommitted changes: $UNCOMMITTED"
fi

echo ""
echo "$DIVIDER"
echo "  Ready. Use /plan to start a new task, or continue from tasks/todo.md."
echo "$DIVIDER"
echo ""
