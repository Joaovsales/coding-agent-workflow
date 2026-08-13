---
title: A first-run trigger added to a self-gating skill must be checked against every early exit above it
date: 2026-08-13
problem_type: pattern
module: .agents/skills/memory-maintain
tags: [skills, self-gating, bootstrap, early-exit, review]
applies_when: adding a new trigger, phase, or check to a skill (or script) that already contains conditional no-op / early-exit rules
---

# A first-run trigger must be checked against every early exit above it

## Context

M4 added a one-time glossary bootstrap sweep (Phase 0) to `/memory-maintain`,
keyed on a `> Sweep: pending` marker and fired from the light pass. The light
pass already carried a blanket rule: *"If `tasks/solutions/` is absent or empty:
silent no-op (exit 0, no output)."*

A fresh install — the only scenario Phase 0 exists for — has an empty store and
a `pending` glossary **at the same time**. The pre-existing early exit would
have swallowed the new trigger silently, in both directions: the sweep never
runs, and Phase 0 is specified to emit nothing when it finds nothing. Dead and
green simultaneously. Caught by a dispatched critic at review
(finding anchored to `.agents/skills/memory-maintain/SKILL.md:35`), not by any
test — prose behavior is not mechanically guarded (M7 rule).

## Pattern

When adding a trigger to an existing skill or script, enumerate every
conditional exit that executes **before** it and ask, for each: "can the state
that fires my trigger coexist with the state that fires this exit?" If yes,
exempt the trigger explicitly in the exit's own wording, not just by bullet
ordering — ordering is not enforcement in prose.

The fix here: *"silent no-op — but the glossary marker check above runs
regardless. A fresh install has an empty store and a `pending` glossary at the
same time."*

## Evidence

This session, branch `feat/compound-engineering-tier-3.3-glossary`; critic
review verdict HOLD, MUST-FIX at confidence 75. The coexistence state was
verified against `install.sh` (seeds `tasks/solutions/README.md` + a `pending`
`tasks/concepts.md` together) rather than assumed.
