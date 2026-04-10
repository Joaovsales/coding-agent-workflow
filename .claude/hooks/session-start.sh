#!/bin/bash
# Claude Code Session Start Hook
# Orients the agent at the beginning of every session by surfacing memory,
# active tasks, and recent lessons without requiring manual reads.

set -euo pipefail

# Kill switch: skip hook if SKIP_SESSION_START=1
[ "${SKIP_SESSION_START:-0}" = "1" ] && exit 0

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

# ── Deployment Signal Nudge ──────────────────────────────────────────────────
# Two non-blocking nudges, unified by the same scan logic:
#
#   Nudge A: CLAUDE.md has no "## Deployment Targets" section AND a runbook in
#            .claude/deployments/ has a detect_file that matches the project
#            root → suggest /setup-deployment (fresh setup).
#
#   Nudge B: CLAUDE.md HAS the section, but a runbook has a matching
#            detect_file AND isn't referenced in the routing table → suggest
#            /setup-deployment (merge new runbook after /sync).
#
# Suppressed globally by creating .claude/deploy-nudge-dismissed.
# The section-header regex is strict (^## Deployment Targets[[:space:]]*$) so
# schema-reference headings with extra text don't count.

if [ ! -f ".claude/deploy-nudge-dismissed" ] && [ -f "CLAUDE.md" ] && [ -d ".claude/deployments" ]; then
  HAS_SECTION=false
  if grep -qE '^## Deployment Targets[[:space:]]*$' CLAUDE.md 2>/dev/null; then
    HAS_SECTION=true
  fi

  UNCONFIGURED_RUNBOOKS=""
  for runbook in .claude/deployments/*.md; do
    [ -f "$runbook" ] || continue
    runbook_name=$(basename "$runbook")
    [ "$runbook_name" = "README.md" ] && continue

    # If the section exists AND this runbook is already referenced, skip.
    if [ "$HAS_SECTION" = "true" ] && grep -qF ".claude/deployments/$runbook_name" CLAUDE.md 2>/dev/null; then
      continue
    fi

    # Parse detect_files from the YAML frontmatter. Stop at the next top-level
    # key or the closing `---`. Returns one path per line.
    while IFS= read -r detect; do
      [ -z "$detect" ] && continue
      if [ -e "$detect" ]; then
        UNCONFIGURED_RUNBOOKS="$UNCONFIGURED_RUNBOOKS $runbook_name"
        break
      fi
    done < <(awk '
      /^---[[:space:]]*$/ { fm++; if (fm > 2) exit; next }
      fm != 1 { next }
      /^detect_files:/ { in_block=1; next }
      in_block && /^[a-zA-Z_]+:/ { in_block=0 }
      in_block && /^[[:space:]]*-[[:space:]]*/ {
        sub(/^[[:space:]]*-[[:space:]]*/, "")
        gsub(/^[[:space:]]+|[[:space:]]+$/, "")
        print
      }
    ' "$runbook" 2>/dev/null)
  done

  if [ -n "$UNCONFIGURED_RUNBOOKS" ]; then
    echo ""
    if [ "$HAS_SECTION" = "false" ]; then
      echo "⚠  Deploy signals detected for unconfigured runbook(s):$UNCONFIGURED_RUNBOOKS"
      echo "   No Deployment Targets section in CLAUDE.md yet."
      echo "   Run /setup-deployment to enable automatic build verification."
    else
      echo "⚠  New deployment runbook(s) not yet in Deployment Targets:$UNCONFIGURED_RUNBOOKS"
      echo "   Run /setup-deployment to merge them into your routing table."
    fi
  fi
fi

# ── Available Skills ────────────────────────────────────────────────────────
echo ""
echo "SKILLS AVAILABLE"
echo "────────────────────────────────"
echo "  /brainstorm  — Divergent design exploration before /plan"
echo "  /plan        — Write spec + task breakdown (use opus)"
echo "  /build       — Autonomous TDD execution with sub-agents"
echo "  /tdd         — Manual TDD loop with user checkpoints"
echo "  /debug       — Root cause analysis + bug register"
echo "  /verify      — Evidence-based verification before claims"
echo "  /simplify    — Code quality review on changed files"
echo "  /deslop      — Remove AI-generated anti-patterns from code"
echo "  /receive-review — Process code review feedback"
echo "  /security-scan  — OWASP audit on changed files"
echo "  /learn       — Extract patterns to memory.md"
echo "  /checkpoint  — Snapshot progress for handoff"
echo "  /wrap-up-session — Close session: review, test, push"
echo "  /writing-skills  — Author new skills"
echo "  /sync        — Pull latest from template repo"

echo ""
echo "$DIVIDER"
echo "  Ready. Use /brainstorm or /plan to start, or continue from tasks/todo.md."
echo "$DIVIDER"
echo ""
