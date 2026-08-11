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

# --- Tier 2 (M1): independence accounting -----------------------------------
# Corroboration is only evidence when the findings came from separately
# dispatched contexts. The regression this guards is a skill quietly promoting a
# finding because two lenses inside ONE context agreed.
# These docs are hard-wrapped prose, so a pinned multi-word phrase can straddle a
# newline. Match against a whitespace-collapsed rendering: the guard is about the
# rule being stated, not about where the paragraph happens to wrap.
flatten() { tr '\n' ' ' < "$1" | tr -s ' '; }

assert_file_contains "CLAUDE.md" "### Independence Accounting" \
  "M1: CLAUDE.md has an Independence Accounting subsection"
assert_contains "$(flatten CLAUDE.md)" "separately dispatched contexts" \
  "M1: CLAUDE.md requires separately dispatched contexts for corroboration"

taxonomy="$(sed -n '/^## Review Gate Taxonomy/,/^## Finding Model/p' CLAUDE.md | tr '\n' ' ' | tr -s ' ')"
assert_contains "$taxonomy" "Independence Accounting" \
  "M1: Review Gate Taxonomy cross-references Independence Accounting"
assert_contains "$taxonomy" "Finding Model" \
  "M1: Review Gate Taxonomy cross-references the Finding Model"

# --- Tier 2 (M2): four-axis findings in CLAUDE.md and both review skills -----
# Each axis, enum value, and confidence anchor is pinned as its own token. A
# dropped enum value is exactly what would let an unsure finding auto-apply, and
# it is invisible in a whole-block snapshot.
for f in CLAUDE.md \
         .claude/skills/quality-gate/SKILL.md .agents/skills/quality-gate/SKILL.md \
         .claude/skills/wrap-up-session/SKILL.md .agents/skills/wrap-up-session/SKILL.md \
         .claude/skills/software-design-expert-review/SKILL.md \
         .agents/skills/software-design-expert-review/SKILL.md; do
  flat="$(flatten "$f")"
  for axis in severity confidence autofix_class owner; do
    assert_contains "$flat" "\`$axis\`" "M2: $f defines the \`$axis\` axis"
  done
  for value in gated_auto manual advisory release; do
    assert_contains "$flat" "\`$value\`" "M2: $f names the \`$value\` enum value"
  done
  for anchor in 50 75 100; do
    assert_contains "$flat" "\`$anchor\`" "M2: $f names confidence anchor \`$anchor\`"
  done
  # Evidence gate: 75+ requires file:line, and its absence demotes rather than drops.
  assert_contains "$flat" "file:line" "M2: $f requires file:line evidence"
  assert_contains "$flat" "demote" "M2: $f demotes on missing evidence"
  # Apply gate: the conjunction is the gate. Either half alone is the bug.
  assert_contains "$flat" "confidence >= 75" "M2: $f gates auto-apply at anchor 75+"
  # Backwards compatibility: an old single-axis finding is neither applied nor lost.
  assert_contains "$flat" "no \`confidence\`" \
    "M2: $f handles a finding arriving with no confidence"
  # Synthesis never widens the autofix class on disagreement.
  assert_contains "$flat" "more conservative" \
    "M2: $f takes the more conservative autofix_class on disagreement"
done

# Both review skills must disclose whether their passes were dispatched or ran
# inline, and must not promote on same-context agreement.
for f in .claude/skills/quality-gate/SKILL.md .agents/skills/quality-gate/SKILL.md \
         .claude/skills/wrap-up-session/SKILL.md .agents/skills/wrap-up-session/SKILL.md; do
  assert_file_contains "$f" "Dispatch Disclosure" \
    "M1: $f carries a Dispatch Disclosure requirement"
  assert_file_contains "$f" "Review independence:" \
    "M1: $f emits the independence line in its output block"
done

# /software-design-expert-review dispatches its reviewer per file-batch, so its
# independence question is batching, not dispatch-vs-inline. Two batches naming the
# same file:line corroborate; two lenses inside one batch do not. It must also stop
# telling the agent to emit the old single-axis format -- that instruction would
# override the persona and degrade every finding to anchor 50.
for f in .claude/skills/software-design-expert-review/SKILL.md \
         .agents/skills/software-design-expert-review/SKILL.md; do
  assert_file_contains "$f" "Review independence:" \
    "M1: $f emits the independence line in its output block"
  assert_contains "$(flatten "$f")" "separately dispatched" \
    "M1: $f promotes only on separately dispatched batches"
  if grep -qF 'format only."' "$f"; then
    assert_eq "absent" "present" \
      "M2: $f must not instruct the agent to emit single-axis findings"
  else
    assert_eq "absent" "absent" \
      "M2: $f must not instruct the agent to emit single-axis findings"
  fi
done

# --- Tier 2 (M2): unattended loops route a non-auto-appliable MUST-FIX -------
# The apply gate narrows what may be auto-applied, so a MUST-FIX can now be
# unappliable. In an unattended loop that must reach the existing FAIL/STOP
# path, never a user prompt.
for f in .claude/skills/yolo/SKILL.md .agents/skills/yolo/SKILL.md \
         .claude/skills/auto-push/SKILL.md .agents/skills/auto-push/SKILL.md \
         .claude/skills/auto-improve/SKILL.md .agents/skills/auto-improve/SKILL.md; do
  assert_file_contains "$f" "gated_auto" \
    "M2: $f states how a non-gated_auto MUST-FIX is routed"
done

finish
