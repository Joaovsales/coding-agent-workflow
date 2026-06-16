---
name: memory-maintain
description: Consolidate, prune, and organize tasks/memory.md and tasks/lessons.md. Invoked at every session start and wrap-up; self-gates on session count.
argument-hint: "[--force]"
harness: universal
disable-model-invocation: false
---

# /memory-maintain — Memory Maintenance

Keep project memory healthy: deduplicate entries, promote durable lessons, prune stale content, enforce a token budget.

Invoked at every session start (CLAUDE.md Session Start Checklist step 4) and by /wrap-up-session Step 1.5. Self-gates on session count so it only does real work every 5 sessions. Run manually with /memory-maintain --force at any time.

## When to run

Check tasks/memory.md Session History entry count:
- Count lines matching `^### \d{4}-\d{2}-\d{2}`
- Run full maintenance if count is a multiple of 5 (5, 10, 15, …) OR --force flag passed
- If neither condition met: exit immediately and silently (no output)

## Phase 1 — Deduplicate Patterns & Lessons

Read the "Patterns & Lessons" section of tasks/memory.md.

For each pair of entries, check for semantic overlap:
- Same root cause described differently
- Same pattern expressed with different wording
- One entry is a subset of another

For overlapping pairs:
- Merge into a single entry (keep the more specific/detailed one, incorporate any unique detail from the other)
- Note the merge: `[merged from session YYYY-MM-DD]`

Deduplication threshold: only merge if >70% semantic overlap. When in doubt, keep separate.

## Phase 2 — Prune Stale Entries

For each entry in "Patterns & Lessons":
- Check if it has been referenced in any spec, task, or source file (grep for key terms)
- Check age: is it from a Session History entry older than 90 days?
- Check relevance: does it reference deleted files, removed features, or superseded approaches?

Mark as stale if: age > 90 days AND no references found AND references deleted artifacts.
All three conditions must hold — do not prune on age alone.

For stale entries: move to a `## Archived` section at the bottom of tasks/memory.md (do not delete — archive).

## Phase 3 — Promote Durable Lessons

Read tasks/lessons.md (tactical per-session lessons).

For each lesson entry older than 14 days:
- Check if it appears across 2+ session summaries (same pattern recurred)
- If yes: promote to tasks/memory.md "Patterns & Lessons" section, remove from tasks/lessons.md

Promoted entry format:
```
### [Title from lessons.md]
**Context**: [when this applies]
**Pattern**: [what to do or avoid]
**Evidence**: [what triggered it — cite session date]
**Promoted**: [YYYY-MM-DD] from tasks/lessons.md
```

## Phase 4 — Token Budget Enforcement

Count approximate tokens in tasks/memory.md (rough estimate: chars / 4).

If > 8000 tokens:
1. Archive the oldest 20% of Session History entries to `tasks/memory-archive-YYYY.md` (year-bucketed)
2. Archive the oldest 20% of "Patterns & Lessons" entries (by session date) to the same archive file
3. Report: "Archived N entries to tasks/memory-archive-YYYY.md to stay under token budget."

## Phase 5 — Reorganize

After all modifications, ensure tasks/memory.md has this structure:

```markdown
# Project Memory

> Maintained by /learn (appends) and /memory-maintain (consolidates). Do not edit manually.

## Architecture Decisions
[entries]

## Patterns & Lessons
[entries — most recently updated first]

## Session History
[entries — newest first]

## Archived
[entries moved here by /memory-maintain — do not delete]
```

If the file lacks any section, create it. Reorder entries so newest are first within each section.

## Output

```
══════════════════════
  MEMORY MAINTAINED
══════════════════════
Patterns & Lessons: [N entries] ([N merged], [N pruned → archived], [N promoted from lessons.md])
Session History: [N entries] ([N archived to memory-archive-YYYY.md])
Token budget: [estimated tokens] / 8000
tasks/lessons.md: [N entries promoted, N remaining]
══════════════════════
```
