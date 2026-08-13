---
title: "A `MUST-FIX` at `confidence: 50` must be *verified*, not fixed"
date: 2026-08-10
problem_type: pattern
module: general
tags: [migrated, pattern]
applies_when: ""
needs_review: true
migrated_from: tasks/memory.md
---

## A `MUST-FIX` at `confidence: 50` must be *verified*, not fixed

**Pattern**: A `MUST-FIX` at `confidence: 50` must be *verified*, not fixed and not blocked on — otherwise a speculative finding deadlocks every commit. Caught in this session's own Phase 3 gate, in the very rule being written.

_Extracted from session history entry "Compound engineering Tier 2 (review epistemics)" (2026-08-10) in `tasks/history.md`._
