---
name: memory-maintain
description: Sweep the typed learning store (tasks/solutions/) — resolve needs_review documents, merge duplicates, prune stale or contradicted entries. Invoked at every session start and wrap-up; self-gates on session count.
argument-hint: "[--force]"
harness: universal
---

# /memory-maintain — Learning Store Maintenance

Keep the typed learning store healthy: resolve `needs_review` documents, merge
duplicates, prune stale content, correct contradicted claims. The store schema
and category map live in `tasks/solutions/README.md`.

Invoked at every session start (CLAUDE.md Session Start Checklist) and by
/wrap-up-session Step 1.5. Self-gates on session count so it only does real work
every 5 sessions. Run manually with /memory-maintain --force at any time.

## When to run

This skill runs two passes at different cadences (a Reflector-style split): a
cheap light pass every session, and the heavy consolidation only every 5.

### Light pass — every session (cheap, continuous decay)

Runs on **every** invocation (session start + wrap-up). Bounded work only:
- Count documents and `needs_review` flags (`grep -rl 'needs_review: true' tasks/solutions`).
- If any document written **this session** duplicates an existing one
  (same `module` + overlapping `tags` **and** >70% semantic overlap — the
  migration's generic `module: general` + `migrated` tag alone never qualify),
  merge into the more specific document and note the merge in its body.

**If `tasks/solutions/` is absent or empty: silent no-op (exit 0, no output).**

### Heavy pass — every 5 sessions (gated)

Count session entries in `tasks/history.md` (lines matching `^### \[\d{4}-\d{2}-\d{2}`):
- Run the full sweep below (Phases 1–4) if the count is a multiple of 5
  (5, 10, 15, …) OR --force flag passed
- If neither condition met: skip the heavy pass (the light pass above still ran)

## Phase 1 — Resolve `needs_review` Documents

For every document carrying `needs_review: true` (migration output and flagged
/learn writes):
- Fill the missing track-required fields from evidence: read the files named in
  `module`, the PRs cited in the body, and git history. Bug track needs
  `symptoms` / `root_cause` / `resolution`; knowledge track needs `applies_when`.
- A claim you can verify against the tree gets cited as `file:line`; one you
  cannot is softened and attributed (grounding rule, see /learn).
- When the fields are complete, remove the `needs_review: true` line.
- If the document cannot be grounded at all (source vanished, no evidence),
  move it to `tasks/archive/solutions/` — never delete.

## Phase 2 — Deduplicate

For each pair of documents in the same category with overlapping `module`/`tags`,
check semantic overlap (same problem, same root cause, one a subset of the other).
Merge only if >70% overlap — keep the more specific document, fold in unique
detail, note `[merged from <slug>]` in the body, and delete the emptied sibling's
file only after its content is fully absorbed. Fix any inbound cross-links.
When in doubt, keep separate.

## Phase 3 — Prune Stale and Contradicted Documents

For each document:
- **Stale**: older than 90 days (frontmatter `date`) AND its key terms are
  referenced by no current spec, task, or source file AND it names deleted
  files, removed features, or superseded approaches. All three must hold — never
  prune on age alone. Move stale documents to `tasks/archive/solutions/`.
- **Contradicted**: the tree no longer behaves as the document claims (spot-check
  `file:line` citations). Update the document to the current truth and note the
  correction — never leave a contradicting sibling, never silently drop it.

## Phase 4 — Store Hygiene

- Every document validates against the schema (`tasks/solutions/README.md`):
  required frontmatter, known `problem_type`, category directory matching the
  map, no dates in filenames. Fix violations in place.
- `tasks/history.md` stays a narrative log: any learning prose that leaked into
  it is extracted to a typed document and cross-linked, matching how the
  migration handled `- Pattern:` bullets.

## Output

```
══════════════════════
  STORE MAINTAINED
══════════════════════
Documents: [N total across M categories]
needs_review: [N resolved, N remaining, N archived as ungroundable]
Duplicates: [N merged]
Stale/contradicted: [N archived, N corrected]
Schema violations fixed: [N]
══════════════════════
```
