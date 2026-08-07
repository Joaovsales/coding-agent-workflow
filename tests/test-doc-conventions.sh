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

# --- visual-recap: documentation contract present in both tree copies ---
for f in .claude/skills/visual-recap/SKILL.md .agents/skills/visual-recap/SKILL.md; do
  for token in "name: visual-recap" "argument-hint:" "Skip when trivial" \
               "true by construction" "git diff" "--name-status" "--stat" \
               "data-model" "api-endpoint" "file-tree" "keychange-" \
               "scripts/visual-render.py" "tasks/recaps/"; do
    assert_file_contains "$f" "$token" "visual-recap: $f contains '$token'"
  done
done

# --- visual-plan: documentation contract present in both tree copies ---
# The renderer token was `../visual-recap/scripts/visual-render.py` until
# test-skill-references.sh surfaced it as an escaping path: the Bash tool's cwd is
# the project root, so `../visual-recap/...` resolved OUTSIDE the repo and the
# documented command could never have run. This suite passed anyway because
# test-visual-render.sh invokes the script by an explicit absolute path -- a green
# suite over a broken skill. The pin is updated to the canonical-tree path that
# actually resolves; it is not relaxed.
for f in .claude/skills/visual-plan/SKILL.md .agents/skills/visual-plan/SKILL.md; do
  for token in "name: visual-plan" "argument-hint:" "Skip when trivial" \
               "read-only" "specs/" ".plan.html" \
               ".agents/skills/visual-recap/scripts/visual-render.py" "file map" \
               "open questions" "wireframe" "NEW"; do
    assert_file_contains "$f" "$token" "visual-plan: $f contains '$token'"
  done
done


# --- Banned construct: load-time shell pre-resolution in skill bodies ---
# A SKILL.md line of the form  !`cmd`  runs cmd when the SKILL LOADS and inlines
# its stdout. It is banned outright here for two reasons that cannot be guarded
# around:
#   1. It is Claude-Code-only. On Pi the line is inert literal text, so any skill
#      depending on the inlined value is already broken on the other harness.
#   2. On Claude Code a non-zero exit ABORTS skill load with a user-facing error.
#      Every plausible use is git/gh context (`git rev-parse`, `gh pr view`) whose
#      non-zero exit is a NORMAL state -- no PR yet, detached HEAD, not a repo --
#      so the ordinary case would break the skill. The POSIX guards that force
#      exit 0 (`2>/dev/null || echo X`) then fail to PARSE under PowerShell.
# Gather context at runtime with one argv-style command per tool call instead.
# The `!\[` exclusion keeps markdown image syntax from matching.
while IFS= read -r f; do
  hits="$(grep -n '![`]' "$f" 2>/dev/null | grep -cv '!\[' || true)"
  assert_eq "0" "${hits:-0}" "BannedConstruct: $f has no load-time !\`cmd\` pre-resolution"
done <<INNER_EOF
$(find .agents/skills .claude/skills -name '*.md' -not -path '*/.claude/worktrees/*' | sort)
INNER_EOF

finish
