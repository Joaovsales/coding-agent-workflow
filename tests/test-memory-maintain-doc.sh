# tests/test-memory-maintain-doc.sh — P4 Reflector-lite split in both copies.
. "$(dirname "$0")/lib.sh"

REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"

A=".agents/skills/memory-maintain/SKILL.md"
C=".claude/skills/memory-maintain/SKILL.md"

for f in "$A" "$C"; do
  assert_file_contains "$f" "Lessons pass — every session" "P4: $f documents per-session lessons pass"
  assert_file_contains "$f" "Heavy pass — every 5 sessions" "P4: $f keeps heavy pass gated at 5"
  assert_file_contains "$f" "silent no-op" "P4: $f no-ops when lessons.md absent"
done

assert_files_identical "$A" "$C" "P4: memory-maintain byte-identical across both trees"

finish
