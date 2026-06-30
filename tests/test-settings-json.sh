# tests/test-settings-json.sh — P1 settings.json registers the PreCompact hook.
. "$(dirname "$0")/lib.sh"

REPO="$(cd "$(dirname "$0")/.." && pwd)"
SETTINGS="$REPO/.claude/settings.json"

# Valid JSON.
if command -v jq >/dev/null 2>&1; then
  jq . "$SETTINGS" >/dev/null 2>&1
  assert_eq "0" "$?" "P1: settings.json is valid JSON"
  cmd=$(jq -r '.hooks.PreCompact[0].hooks[0].command // ""' "$SETTINGS" 2>/dev/null)
  assert_eq "bash .claude/hooks/pre-compact.sh" "$cmd" "P1: PreCompact hook wired to pre-compact.sh"
else
  assert_file_contains "$SETTINGS" "PreCompact" "P1: settings.json references PreCompact (jq absent)"
  assert_file_contains "$SETTINGS" "pre-compact.sh" "P1: settings.json references pre-compact.sh (jq absent)"
fi

finish
