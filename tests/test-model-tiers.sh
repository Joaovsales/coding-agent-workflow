#!/bin/bash
# tests/test-model-tiers.sh — the `ceiling` tier must stay un-pinned.
#
# `ceiling` means "omit the model override so the sub-agent inherits the session
# model". The three highest-stakes review roles resolve to it, and the whole point
# is that they run at whatever capability the user is paying for: pin one to a
# concrete model and an Opus session silently gets a Sonnet reviewer.
#
# That regression is invisible at runtime — the review still runs and still
# reports findings, just from a weaker model — so it needs a mechanical guard
# rather than a convention. A single re-added `model: sonnet` line is enough to
# reintroduce it, which is exactly the smallest falsifiable unit to pin.
. "$(dirname "$0")/lib.sh"

REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"

CEILING_AGENTS="code-reviewer security-reviewer software-design-expert-review critic"

# Reviewer-tier personas that MUST keep their Claude-side pin. This is the mirror
# of the ceiling assertion and it guards a real, already-observed regression: the
# `.agents/` -> `.claude/` parity copy is a plain `cp`, and the canonical tree is
# model-agnostic by contract, so copying over a Claude-only `model:` line drops it
# silently. Parity tests cannot catch it -- the `cp` is what made the two files
# identical. Pin the line itself.
PINNED_AGENTS="context-document-optimizer:sonnet"

# --- 1. Ceiling agents carry no model pin in the Claude Code tree -------------
for agent in $CEILING_AGENTS; do
  f=".claude/agents/$agent.md"
  if [ ! -f "$f" ]; then
    _TESTS=$((_TESTS + 1)); _FAILS=$((_FAILS + 1))
    printf '  FAIL ModelTier: %s is missing\n' "$f"
    continue
  fi
  if grep -qE '^model:' "$f"; then
    _TESTS=$((_TESTS + 1)); _FAILS=$((_FAILS + 1))
    printf '  FAIL ModelTier: %s pins a model (%s) — ceiling agents must inherit\n' \
      "$f" "$(grep -m1 -E '^model:' "$f")"
  else
    assert_eq "unpinned" "unpinned" "ModelTier: $agent inherits the session model"
  fi
done

# --- 1b. Reviewer-tier agents keep their Claude-side model pin ----------------
for entry in $PINNED_AGENTS; do
  agent="${entry%%:*}"; want="${entry##*:}"
  f=".claude/agents/$agent.md"
  assert_file_contains "$f" "model: $want" \
    "ModelTier: $agent keeps its Claude-side 'model: $want' pin (not a ceiling role)"
done

# --- 2. Canonical agent tree stays model-agnostic ----------------------------
# Also covered by test-agents.sh; asserted here so this guard reads as a complete
# statement of the tier contract rather than depending on a sibling file.
for f in .agents/agents/*.md; do
  [ -f "$f" ] || continue
  case "$(basename "$f")" in README.md) continue ;; esac
  if grep -qE '^model:' "$f"; then
    _TESTS=$((_TESTS + 1)); _FAILS=$((_FAILS + 1))
    printf '  FAIL ModelTier: canonical %s pins a model\n' "$f"
  else
    assert_eq "agnostic" "agnostic" "ModelTier: canonical $(basename "$f") is model-agnostic"
  fi
done

# --- 3. Non-ceiling agents still resolve to a tier ---------------------------
# Guards the opposite mistake: stripping every pin, which would silently promote
# cheap roles to the session model and inflate cost.
for agent in backend-developer frontend-developer code-debugger scout-unused; do
  f=".claude/agents/$agent.md"
  [ -f "$f" ] || continue
  assert_eq "pinned" "$(grep -qE '^model:' "$f" && echo pinned || echo unpinned)" \
    "ModelTier: non-ceiling $agent still pins a tier model"
done

# --- 4. The tier contract is documented where agents are routed --------------
assert_file_contains CLAUDE.md "| Ceiling |" \
  "ModelTier: CLAUDE.md Model Routing has a Ceiling row"
assert_file_contains CLAUDE.md "omit the model override" \
  "ModelTier: CLAUDE.md defines ceiling as omitting the override"
for f in .agents/skills/build/SKILL.md .claude/skills/build/SKILL.md; do
  assert_file_contains "$f" "Ceiling-tier agents take no \`model\` at all" \
    "ModelTier: $f states the ceiling dispatch rule"
done
for f in .agents/skills/plan/SKILL.md .claude/skills/plan/SKILL.md; do
  assert_file_contains "$f" "ceiling" \
    "ModelTier: $f defers to the ceiling tier"
done

# --- 5. Ceiling roles are not pinned in any routing table -------------------
# A table row that gives a ceiling agent a concrete Claude Code model reintroduces
# the cap in documentation even when the agent file is clean.
for f in CLAUDE.md .agents/skills/build/SKILL.md .claude/skills/build/SKILL.md; do
  for agent in $CEILING_AGENTS; do
    if grep -E "^\|.*\`$agent\`" "$f" | grep -qE '`(sonnet|haiku|opus)`'; then
      _TESTS=$((_TESTS + 1)); _FAILS=$((_FAILS + 1))
      printf '  FAIL ModelTier: %s routes %s to a concrete model\n' "$f" "$agent"
    else
      assert_eq "unpinned" "unpinned" "ModelTier: $f does not pin $agent in a table"
    fi
  done
done

# --- 6. critic never resolves below planner tier ------------------------------
# Plain ceiling downgrades critic on a sub-planner session, and critic is the
# adversarial gate of last resort. The floor is a dispatch rule, not frontmatter:
# a `model: opus` pin would cap the agent at Opus rather than floor it, which is
# the defect the ceiling tier exists to remove. So the rule text is what gets
# pinned here, alongside the no-pin assertion above.
#
# The needles are prose unique to the *rule*, not the phrase "planner floor" --
# that phrase also appears in the Agents table cell, so a looser needle stayed
# green even with the whole explanation deleted (verified: 0 failures before this
# was tightened). assert_prose_contains rather than assert_file_contains because
# CLAUDE.md hard-wraps, and one of these phrases straddles a line break.
assert_prose_contains CLAUDE.md "dispatch rule, not frontmatter" \
  "ModelTier: CLAUDE.md explains critic's floor as a dispatch rule"
assert_prose_contains CLAUDE.md "never resolves below planner tier" \
  "ModelTier: CLAUDE.md states what critic's floor bounds"
assert_file_matches CLAUDE.md '^\| .critic. \| .?ceiling \(planner floor\)' \
  "ModelTier: CLAUDE.md Agents table marks critic ceiling (planner floor)"

# --- 7. No concrete provider model IDs in the routing docs -------------------
# PI_SETUP.md owns them. Three copies of a release-sensitive fact is three
# chances to go stale, and the tables are the copies nobody updates.
for f in CLAUDE.md .agents/skills/build/SKILL.md .claude/skills/build/SKILL.md; do
  for vendor in 'moonshotai/' 'qwen/' 'z-ai/' 'deepseek/' 'anthropic/claude'; do
    assert_file_not_matches "$f" "$vendor" "ModelTier: $f has no hardcoded $vendor ID"
  done
  assert_file_contains "$f" 'PI_SETUP.md` § Sub-Agent Routing' \
    "ModelTier: $f points at PI_SETUP.md for concrete IDs"
done
assert_file_contains PI_SETUP.md "single source of concrete model IDs" \
  "ModelTier: PI_SETUP.md claims ownership of the concrete IDs"

# --- 8. No skill routes the design reviewer to a concrete model --------------
for tree in .agents .claude; do
  for skill in quality-gate software-design-expert-review; do
    assert_file_not_matches "$tree/skills/$skill/SKILL.md" 'model: .?sonnet' \
      "ModelTier: $tree $skill no longer pins the design reviewer"
  done
done

finish
