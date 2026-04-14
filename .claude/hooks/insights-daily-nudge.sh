#!/bin/bash
# Claude Code — Daily Insights Nudge (SessionStart hook)
#
# Detects Claude Code session transcripts (across ALL projects) from prior days
# that have not yet been analyzed with /insights, and prints a banner asking
# the agent to generate today's insights report.
#
# State: ~/.claude/insights-state.json
#   {
#     "last_run_date": "YYYY-MM-DD",
#     "analyzed_sessions": ["<session-id>", ...]
#   }
#
# Reports: ~/.claude/insights-reports/YYYY-MM-DD.md  (global, private, not in any repo)
#
# Kill switch: SKIP_INSIGHTS_NUDGE=1

set -euo pipefail

[ "${SKIP_INSIGHTS_NUDGE:-0}" = "1" ] && exit 0

STATE_FILE="$HOME/.claude/insights-state.json"
REPORTS_DIR="$HOME/.claude/insights-reports"
PROJECTS_DIR="$HOME/.claude/projects"

mkdir -p "$REPORTS_DIR"

# Need jq for safe JSON state I/O
if ! command -v jq >/dev/null 2>&1; then
  # Silent skip — don't block session start on missing tooling
  exit 0
fi

[ -d "$PROJECTS_DIR" ] || exit 0

TODAY=$(date +%Y-%m-%d)

# Already ran today? Silent exit (observability discipline: event-only).
LAST_RUN=""
if [ -f "$STATE_FILE" ]; then
  LAST_RUN=$(jq -r '.last_run_date // ""' "$STATE_FILE" 2>/dev/null || echo "")
fi
if [ "$LAST_RUN" = "$TODAY" ]; then
  exit 0
fi

# Build analyzed-ID lookup
ANALYZED_TMP=$(mktemp)
trap 'rm -f "$ANALYZED_TMP"' EXIT
if [ -f "$STATE_FILE" ]; then
  jq -r '.analyzed_sessions[]? // empty' "$STATE_FILE" 2>/dev/null > "$ANALYZED_TMP" || true
fi

# Collect unanalyzed session transcripts from prior days (skip today's — those
# are likely still active).
UNANALYZED=()
while IFS= read -r -d '' file; do
  sid=$(basename "$file" .jsonl)
  # Portable mtime-as-date (GNU and BSD)
  if mtime_day=$(date -r "$file" +%Y-%m-%d 2>/dev/null); then
    :
  else
    mtime_day=$(stat -c %y "$file" 2>/dev/null | cut -d' ' -f1 || echo "")
  fi
  [ -z "$mtime_day" ] && continue
  [ "$mtime_day" = "$TODAY" ] && continue
  if grep -qxF "$sid" "$ANALYZED_TMP" 2>/dev/null; then
    continue
  fi
  UNANALYZED+=("$file")
done < <(find "$PROJECTS_DIR" -type f -name "*.jsonl" -print0 2>/dev/null)

if [ ${#UNANALYZED[@]} -eq 0 ]; then
  # Nothing to do — stamp today to stay silent the rest of the day.
  tmp=$(mktemp)
  if [ -f "$STATE_FILE" ]; then
    jq --arg d "$TODAY" '.last_run_date = $d' "$STATE_FILE" > "$tmp" && mv "$tmp" "$STATE_FILE"
  else
    printf '{"last_run_date":"%s","analyzed_sessions":[]}\n' "$TODAY" > "$tmp" && mv "$tmp" "$STATE_FILE"
  fi
  exit 0
fi

# Emit nudge — injected into the agent's SessionStart context.
REPORT_PATH="$REPORTS_DIR/$TODAY.md"
MARK_SCRIPT="$HOME/.claude/hooks/insights-mark-analyzed.sh"

echo ""
echo "════════════════════════════════════════"
echo "  📊  DAILY /insights DUE"
echo "════════════════════════════════════════"
echo ""
echo "Last run: ${LAST_RUN:-never}    Today: $TODAY"
echo "Unanalyzed prior-day sessions: ${#UNANALYZED[@]}"
echo ""
echo "Sessions to analyze:"
for f in "${UNANALYZED[@]}"; do
  echo "  • $f"
done
echo ""
echo "ACTION REQUIRED (auto-daily-insights):"
echo "  1. Run the /insights skill scoped to the session transcripts above."
echo "  2. Save the rendered report to: $REPORT_PATH"
echo "  3. Mark sessions analyzed by running:"
echo "     bash $MARK_SCRIPT \\"
for f in "${UNANALYZED[@]}"; do
  sid=$(basename "$f" .jsonl)
  echo "       $sid \\"
done
echo ""
echo "  (Silence today's nudge: SKIP_INSIGHTS_NUDGE=1)"
echo "════════════════════════════════════════"
