# tests/test-session-start.sh — P1 compaction-aware SessionStart restore branch.
. "$(dirname "$0")/lib.sh"

REPO="$(cd "$(dirname "$0")/.." && pwd)"
HOOK="$REPO/.claude/hooks/session-start.sh"
cd "$REPO"

# --- source=compact -> lightweight restore, NO full banner ---
out_compact=$(printf '{"source":"compact"}' | bash "$HOOK" 2>/dev/null)
assert_contains "$out_compact" "Context was just compacted" "P1: compact source prints restore block"
assert_not_contains "$out_compact" "SKILLS AVAILABLE" "P1: compact source skips full skills banner"

# --- source=startup -> full banner ---
out_startup=$(printf '{"source":"startup"}' | bash "$HOOK" 2>/dev/null)
assert_contains "$out_startup" "SKILLS AVAILABLE" "P1: startup source prints full banner"

# --- empty/absent stdin -> defaults to full banner (no regression) ---
out_empty=$(printf '' | bash "$HOOK" 2>/dev/null)
assert_contains "$out_empty" "SKILLS AVAILABLE" "P1: empty stdin defaults to full banner"

finish
