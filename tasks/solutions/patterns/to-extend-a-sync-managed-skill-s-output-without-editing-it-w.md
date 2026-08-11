---
title: To extend a `/sync`-managed skill's output without editing it, wrap
date: 2026-07-08
problem_type: pattern
module: general
tags: [migrated, pattern]
applies_when: ""
needs_review: true
migrated_from: tasks/memory.md
---

## To extend a `/sync`-managed skill's output without editing it, wrap

**Pattern**: To extend a `/sync`-managed skill's output without editing it, wrap it — a new skill owns a post-processor that operates on the managed skill's OUTPUT. Keeps the managed file untouched so `/sync` never clobbers the work.

_Extracted from session history entry "Visual plan/recap skills" (2026-07-08) in `tasks/history.md`._
