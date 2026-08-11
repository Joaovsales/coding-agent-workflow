# tests/test-session-start.sh — P1 compaction-aware SessionStart restore branch.
. "$(dirname "$0")/lib.sh"

REPO="$(cd "$(dirname "$0")/.." && pwd)"
HOOK="$REPO/.claude/hooks/session-start.sh"
cd "$REPO"

# --- source=compact -> lightweight restore, NO full banner ---
out_compact=$(printf '{"source":"compact"}' | bash "$HOOK" 2>/dev/null)
assert_contains "$out_compact" "Context was just compacted" "P1: compact source prints restore block"
assert_not_contains "$out_compact" "SKILLS AVAILABLE" "P1: compact source skips full skills banner"
assert_not_contains "$out_compact" "tasks/memory.md" "M3: compact restore no longer points at memory.md"
assert_contains "$out_compact" "tasks/solutions" "M3: compact restore points at the typed store"

# --- source=startup -> full banner ---
out_startup=$(printf '{"source":"startup"}' | bash "$HOOK" 2>/dev/null)
assert_contains "$out_startup" "SKILLS AVAILABLE" "P1: startup source prints full banner"

# --- empty/absent stdin -> defaults to full banner (no regression) ---
out_empty=$(printf '' | bash "$HOOK" 2>/dev/null)
assert_contains "$out_empty" "SKILLS AVAILABLE" "P1: empty stdin defaults to full banner"

# --- M3 store cutover: one-line counts, no bodies, no retired files ---------
tmpS=$(mktemp -d)
cd "$tmpS"
mkdir -p tasks/solutions/patterns
cat > tasks/solutions/patterns/doc-one.md <<'EOF'
---
title: Doc one
date: 2026-08-11
problem_type: pattern
module: tests
tags: [fixture]
applies_when: testing the session-start store line
needs_review: true
---
SECRET-BODY-MARKER-ONE
EOF
cat > tasks/solutions/patterns/doc-two.md <<'EOF'
---
title: Doc two
date: 2026-08-11
problem_type: pattern
module: tests
tags: [fixture]
applies_when: testing the session-start store line
---
SECRET-BODY-MARKER-TWO
EOF
out_store=$(printf '{"source":"startup"}' | CCW_SESSION_GUARD=0 bash "$HOOK" 2>/dev/null)
assert_contains "$out_store" "tasks/solutions" "M3: banner names the store"
assert_contains "$out_store" "2 document" "M3: banner reports document count"
assert_contains "$out_store" "1 needs_review" "M3: banner reports needs_review count"
assert_not_contains "$out_store" "SECRET-BODY-MARKER" "M3: banner dumps no document bodies"
assert_not_contains "$out_store" "tasks/memory.md" "M3: banner no longer references tasks/memory.md"
assert_not_contains "$out_store" "tasks/lessons.md" "M3: banner no longer references tasks/lessons.md"
assert_eq "false" "$([ -f tasks/memory.md ] && echo true || echo false)" \
  "M3: hook no longer bootstraps tasks/memory.md"
cd "$REPO"
rm -rf "$tmpS"

finish
