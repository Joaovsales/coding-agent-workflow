# tests/test-skill-parity.sh — .agents/ ↔ .claude/ parity for touched skills.
#
# Note: build/ and checkpoint/ were already divergent between the two trees
# BEFORE this work (build: 278 vs 407 lines; checkpoint: a frontmatter style
# line). Fully reconciling that historical drift is out of scope (a separate
# cleanup). So we enforce:
#   - byte-identity for files created/edited wholesale here (refresh, memory-maintain)
#   - feature-marker parity for the pre-divergent files (our additions in BOTH)
. "$(dirname "$0")/lib.sh"

REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"

# Files we own end-to-end → must be byte-identical across trees.
for s in refresh memory-maintain; do
  assert_files_identical ".agents/skills/$s/SKILL.md" ".claude/skills/$s/SKILL.md" \
    "Parity: $s identical across .agents/ and .claude/"
done

# Pre-divergent files → our additions must exist in BOTH copies.
for marker in "Task-boundary checkpoint" "Backstop first" "Large-Artifact Handoff" "tasks/memory.md"; do
  assert_file_contains ".agents/skills/build/SKILL.md" "$marker" "Parity: build .agents has '$marker'"
  assert_file_contains ".claude/skills/build/SKILL.md" "$marker" "Parity: build .claude has '$marker'"
done
for f in .agents/skills/checkpoint/SKILL.md .claude/skills/checkpoint/SKILL.md; do
  assert_file_contains "$f" "tasks/memory.md" "Parity: checkpoint $f uses tasks/memory.md"
done

finish
