#!/bin/bash
# Claude Code Session Start Hook
# Orients the agent at the beginning of every session by surfacing memory,
# active tasks, and recent lessons without requiring manual reads.

set -euo pipefail

# Kill switch: skip hook if SKIP_SESSION_START=1
[ "${SKIP_SESSION_START:-0}" = "1" ] && exit 0

# ── Active-session sentinel ──────────────────────────────────────────────────
# Written here, removed by session-stop.sh. Cron jobs that source
# cron-quiet-hours.sh use its presence to suppress human-readable reporting
# during active sessions (failure-only path in observability discipline).
SENTINEL="${CLAUDE_SESSION_SENTINEL:-/tmp/claude-code-session-active}"
printf 'pid=%s\nstarted=%s\nrepo=%s\n' "$$" "$(date -u +%FT%TZ)" "$(pwd)" > "$SENTINEL" 2>/dev/null || true

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
# If CLAUDE.md lacks a "## Deployment Targets" section AND any known deployment
# signal file exists at the project root, print a one-line nudge. Non-blocking.
# Suppressed by creating .claude/deploy-nudge-dismissed.
if [ ! -f ".claude/deploy-nudge-dismissed" ] && [ -f "CLAUDE.md" ]; then
  # Match ONLY a literal "## Deployment Targets" heading line — not headings with
  # extra text like "## Deployment Targets — Schema Reference (Inactive Example)".
  # This lets the template repo document the schema without activating verification.
  if ! grep -qE '^## Deployment Targets[[:space:]]*$' CLAUDE.md 2>/dev/null; then
    DEPLOY_SIGNAL=""
    for signal in railway.json railway.toml .railway vercel.json .vercel .vercelignore netlify.toml fly.toml render.yaml; do
      if [ -e "$signal" ]; then
        DEPLOY_SIGNAL="$signal"
        break
      fi
    done
    if [ -n "$DEPLOY_SIGNAL" ]; then
      echo ""
      echo "⚠  Deploy signals detected ($DEPLOY_SIGNAL) but no Deployment Targets in CLAUDE.md."
      echo "   Run /setup-deployment to enable automatic build verification."
    fi
  fi
fi

# ── Workflow Template Drift Check ────────────────────────────────────────────
# Notifies if the coding-agent-workflow template has new commits affecting
# syncable paths (.claude/skills, .claude/agents, .claude/hooks, settings.json).
# Silent when in sync (observability discipline: loud only on actionable state).
#
# Preconditions:
#   - A git remote named 'workflow' must exist (skipped otherwise)
#   - Not dismissed via .claude/sync-check-dismissed
#
# Behaviour:
#   - Fetches at most once per 24h (cached in .claude/.sync-check-cache)
#   - 5s network timeout — never hangs the session if offline
#   - Reports drift count; user runs /sync to review & apply
WORKFLOW_CHECK_CACHE=".claude/.sync-check-cache"
WORKFLOW_CHECK_MAX_AGE=86400  # 24 hours

if [ ! -f ".claude/sync-check-dismissed" ] \
   && git rev-parse --is-inside-work-tree &>/dev/null \
   && git remote get-url workflow &>/dev/null; then

  NEED_FETCH=1
  if [ -f "$WORKFLOW_CHECK_CACHE" ]; then
    CACHE_MTIME=$(stat -c %Y "$WORKFLOW_CHECK_CACHE" 2>/dev/null \
                  || stat -f %m "$WORKFLOW_CHECK_CACHE" 2>/dev/null \
                  || echo 0)
    CACHE_AGE=$(( $(date +%s) - CACHE_MTIME ))
    [ "$CACHE_AGE" -lt "$WORKFLOW_CHECK_MAX_AGE" ] && NEED_FETCH=0
  fi

  DRIFT_COUNT=0
  WORKFLOW_BRANCH=""

  if [ "$NEED_FETCH" = "1" ]; then
    WORKFLOW_BRANCH=$(git ls-remote --symref workflow HEAD 2>/dev/null \
      | awk '/^ref:/ {sub("refs/heads/","",$2); print $2; exit}')
    WORKFLOW_BRANCH=${WORKFLOW_BRANCH:-main}

    if timeout 5 git fetch workflow "$WORKFLOW_BRANCH" &>/dev/null; then
      DRIFT_COUNT=$(git diff --name-only "workflow/$WORKFLOW_BRANCH" -- \
        .claude/skills .claude/agents .claude/hooks .claude/settings.json 2>/dev/null \
        | wc -l | tr -d ' ')
      printf '%s\n%s\n' "$DRIFT_COUNT" "$WORKFLOW_BRANCH" > "$WORKFLOW_CHECK_CACHE"
    fi
  else
    DRIFT_COUNT=$(sed -n '1p' "$WORKFLOW_CHECK_CACHE" 2>/dev/null || echo 0)
    WORKFLOW_BRANCH=$(sed -n '2p' "$WORKFLOW_CHECK_CACHE" 2>/dev/null)
    WORKFLOW_BRANCH=${WORKFLOW_BRANCH:-main}
  fi

  if [ "${DRIFT_COUNT:-0}" -gt 0 ]; then
    echo ""
    echo "🔄  TEMPLATE DRIFT — $DRIFT_COUNT file(s) differ from workflow/$WORKFLOW_BRANCH"
    echo "    Run /sync to review and apply updates (or 'touch .claude/sync-check-dismissed' to silence)."
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
