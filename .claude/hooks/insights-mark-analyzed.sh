#!/bin/bash
# Mark one or more Claude Code session IDs as analyzed by /insights, and stamp
# today's date into ~/.claude/insights-state.json so the daily nudge stays
# silent for the rest of the day.
#
# Usage: insights-mark-analyzed.sh <session-id> [<session-id>...]

set -euo pipefail

if [ "$#" -lt 1 ]; then
  echo "usage: $0 <session-id> [<session-id>...]" >&2
  exit 2
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required but not installed" >&2
  exit 1
fi

STATE_FILE="$HOME/.claude/insights-state.json"
TODAY=$(date +%Y-%m-%d)

mkdir -p "$(dirname "$STATE_FILE")"

if [ ! -f "$STATE_FILE" ]; then
  printf '{"last_run_date":"","analyzed_sessions":[]}\n' > "$STATE_FILE"
fi

# Build a JSON array of incoming IDs to merge into the state file.
IDS_JSON=$(printf '%s\n' "$@" | jq -R . | jq -s .)

tmp=$(mktemp)
jq \
  --arg d "$TODAY" \
  --argjson new "$IDS_JSON" \
  '.last_run_date = $d
   | .analyzed_sessions = ((.analyzed_sessions // []) + $new | unique)' \
  "$STATE_FILE" > "$tmp" && mv "$tmp" "$STATE_FILE"

echo "insights-state updated: last_run_date=$TODAY, +$# session(s) marked analyzed"
