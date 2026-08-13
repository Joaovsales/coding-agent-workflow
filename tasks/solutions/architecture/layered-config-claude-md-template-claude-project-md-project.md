---
title: Layered config (CLAUDE.md template + .claude/project.md project + CLAUDE.local.md personal)
date: 2026-08-11
problem_type: architecture-decision
module: general
tags: [migrated, architecture]
applies_when: ""
needs_review: true
date_source: git-log
migrated_from: tasks/memory.md
---

## Layered config (CLAUDE.md template + .claude/project.md project + CLAUDE.local.md personal)

**Rationale**: Lets `/sync` overwrite template safely; uses native `@import`; clear ownership per layer
