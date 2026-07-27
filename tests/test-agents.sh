# tests/test-agents.sh — .agents/agents/ canonical layer integrity.
#
# Verifies:
#   - every canonical agent has name + description frontmatter (required by
#     pi-subagents discovery)
#   - no canonical agent pins a model (routing is per-harness; see
#     .agents/agents/README.md)
#   - every .claude/agents/ persona has a canonical counterpart
. "$(dirname "$0")/lib.sh"

REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"

CANONICAL=".agents/agents"
CLAUDE=".claude/agents"

# 1. Frontmatter validity + no model pin in canonical agents
for f in "$CANONICAL"/*.md; do
  base="$(basename "$f")"
  [ "$base" = "README.md" ] && continue
  assert_file_contains "$f" "name:" "Agents: $base has name frontmatter"
  assert_file_contains "$f" "description:" "Agents: $base has description frontmatter"
  if grep -qE '^model: ' "$f"; then
    _TESTS=$((_TESTS + 1)); _FAILS=$((_FAILS + 1))
    printf '  FAIL Agents: %s must not pin a model (routing lives in per-harness settings)\n' "$base"
  else
    _TESTS=$((_TESTS + 1)); printf '  ok   Agents: %s is model-agnostic\n' "$base"
  fi
done

# 2. Every Claude agent persona has a canonical counterpart
for f in "$CLAUDE"/*.md; do
  base="$(basename "$f")"
  assert_eq "present" "$([ -f "$CANONICAL/$base" ] && echo present || echo missing)" \
    "Agents: canonical counterpart exists for .claude/agents/$base"
done

finish
