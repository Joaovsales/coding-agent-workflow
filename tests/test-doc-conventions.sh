# tests/test-doc-conventions.sh — documentation invariants across skills/config.
# Extended as P2/P4/P5 land. Pure grep assertions; no temp state.
. "$(dirname "$0")/lib.sh"

REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"

# --- Task 4: no stale .claude/memory.md path; correct tasks/memory.md used ---
for f in .claude/skills/checkpoint/SKILL.md .agents/skills/checkpoint/SKILL.md \
         .claude/skills/build/SKILL.md .agents/skills/build/SKILL.md; do
  if grep -qF ".claude/memory.md" "$f"; then
    assert_eq "absent" "present" "Task4: $f has NO stale .claude/memory.md ref"
  else
    assert_eq "absent" "absent" "Task4: $f has NO stale .claude/memory.md ref"
  fi
  assert_file_contains "$f" "tasks/memory.md" "Task4: $f references tasks/memory.md"
done

# --- Task 5 (P2): both build copies checkpoint at task boundaries ---
for f in .claude/skills/build/SKILL.md .agents/skills/build/SKILL.md; do
  assert_file_contains "$f" "Task-boundary checkpoint" "Task5: $f checkpoints at task boundary"
  assert_file_contains "$f" "pre-compact.sh" "Task5: $f reuses the shared PreCompact flush"
done

# --- Task 7 (P3): circuit breaker auto-invokes /refresh before escalating ---
for f in .claude/skills/build/SKILL.md .agents/skills/build/SKILL.md; do
  assert_file_contains "$f" "Backstop first" "Task7: $f circuit breaker runs /refresh backstop"
done

# --- Task 6 (P3): /refresh registered in CLAUDE.md table + session-start banner ---
assert_file_contains "CLAUDE.md" "\`/refresh\`" "Task6: CLAUDE.md skills table lists /refresh"
assert_file_contains ".claude/hooks/session-start.sh" "/refresh" "Task6: session-start banner lists /refresh"

# --- Task 9 (P5): Large-Artifact Handoff convention + references ---
assert_file_contains ".claude/project.md" "Large-Artifact Handoff" "Task9: project.md defines the convention"
assert_file_contains ".claude/project.md" "truncate with a" "Task9: project.md states truncate-with-pointer"
for f in .claude/skills/build/SKILL.md .agents/skills/build/SKILL.md .claude/skills/verify-deployment/SKILL.md; do
  assert_file_contains "$f" "Large-Artifact Handoff" "Task9: $f references the convention"
done

finish
