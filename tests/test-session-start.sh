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

# --- M3 regression: a store with ZERO needs_review docs must not kill the ---
# banner (grep exits 1 on no match; under set -eo pipefail that aborted the
# hook). Also: the store README's own literal mention of the flag must not be
# counted as a flagged document.
tmpZ=$(mktemp -d)
cd "$tmpZ"
mkdir -p tasks/solutions/patterns
printf '`needs_review: true` is documentation, not a flag\n' > tasks/solutions/README.md
cat > tasks/solutions/patterns/clean-doc.md <<'EOF'
---
title: Clean doc
date: 2026-08-13
problem_type: pattern
module: tests
tags: [fixture]
applies_when: testing the zero-flag store path
---
Body.
EOF
out_zero=$(printf '{"source":"startup"}' | CCW_SESSION_GUARD=0 bash "$HOOK" 2>/dev/null)
ec_zero=$?
assert_eq "0" "$ec_zero" "M3: zero-flag store does not abort the hook"
assert_contains "$out_zero" "SKILLS AVAILABLE" "M3: zero-flag store still prints the full banner"
assert_contains "$out_zero" "1 documents, 0 needs_review" \
  "M3: zero-flag store counts 0 needs_review (README mention not counted)"
assert_not_contains "$out_zero" "Partially migrated" \
  "M3: fully-migrated store gets no partial-migration warning"
cd "$REPO"
rm -rf "$tmpZ"

# --- M3: unmigrated-store branch — old files present, no tasks/solutions/ ---
tmpU=$(mktemp -d)
cd "$tmpU"
mkdir -p tasks
printf '# Memory\n' > tasks/memory.md
out_unmig=$(printf '{"source":"startup"}' | CCW_SESSION_GUARD=0 bash "$HOOK" 2>/dev/null)
assert_contains "$out_unmig" "Unmigrated learning store" \
  "M3: old-store repo gets the migration pointer"
assert_contains "$out_unmig" "migrate-learning-store.py" \
  "M3: migration pointer names the script"
cd "$REPO"
rm -rf "$tmpU"

# --- M3: half-migrated repo — store AND old files both present --------------
tmpP=$(mktemp -d)
cd "$tmpP"
mkdir -p tasks/solutions/patterns
printf '# Memory\n' > tasks/memory.md
out_partial=$(printf '{"source":"startup"}' | CCW_SESSION_GUARD=0 bash "$HOOK" 2>/dev/null)
assert_contains "$out_partial" "LEARNING STORE" \
  "M3: half-migrated repo still prints store counts"
assert_contains "$out_partial" "Partially migrated" \
  "M3: half-migrated repo warns about orphaned old-store files"
cd "$REPO"
rm -rf "$tmpP"

# --- M3: no-store branch — neither old files nor tasks/solutions/ -----------
tmpN=$(mktemp -d)
cd "$tmpN"
out_none=$(printf '{"source":"startup"}' | CCW_SESSION_GUARD=0 bash "$HOOK" 2>/dev/null)
assert_contains "$out_none" "No learning store yet" \
  "M3: storeless repo gets the bootstrap line"
cd "$REPO"
rm -rf "$tmpN"

# --- M3: maintenance nudge fires on a multiple of 5 history entries ---------
tmpM=$(mktemp -d)
cd "$tmpM"
mkdir -p tasks/solutions/patterns
for d in 01 02 03 04 05; do
  printf '### [2026-08-%s] — session %s\n- Key changes: x\n\n' "$d" "$d" >> tasks/history.md
done
out_five=$(printf '{"source":"startup"}' | CCW_SESSION_GUARD=0 bash "$HOOK" 2>/dev/null)
assert_contains "$out_five" "MEMORY MAINTENANCE DUE (5 sessions)" \
  "M3: nudge fires at 5 bracketed-date history entries"
printf '### [2026-08-06] — session 06\n- Key changes: x\n\n' >> tasks/history.md
out_six=$(printf '{"source":"startup"}' | CCW_SESSION_GUARD=0 bash "$HOOK" 2>/dev/null)
assert_not_contains "$out_six" "MEMORY MAINTENANCE DUE" \
  "M3: nudge stays silent off the multiple of 5"
cd "$REPO"
rm -rf "$tmpM"

finish
