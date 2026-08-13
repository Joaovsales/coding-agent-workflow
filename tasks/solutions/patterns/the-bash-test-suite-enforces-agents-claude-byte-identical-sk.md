---
title: The bash test suite enforces `.agents/` ↔ `.claude/` byte-identical sk
date: 2026-07-08
problem_type: pattern
module: general
tags: [migrated, pattern]
applies_when: ""
needs_review: true
migrated_from: tasks/memory.md
---

## The bash test suite enforces `.agents/` ↔ `.claude/` byte-identical sk

**Pattern**: The bash test suite enforces `.agents/` ↔ `.claude/` byte-identical skill parity (`test-skill-parity.sh`) + doc-convention token greps (`test-doc-conventions.sh`). Any new skill must be authored in BOTH trees identically and wired into both tests.

_Extracted from session history entry "Visual plan/recap skills" (2026-07-08) in `tasks/history.md`._
