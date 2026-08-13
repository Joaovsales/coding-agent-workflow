# Bug Document Template

Every investigated bug becomes one bug-track document in the typed learning
store: `tasks/solutions/bugs/<slug>.md` (`performance/` or `security/` when
`problem_type` is one of those). The full schema and category map live in
`tasks/solutions/README.md`. The slug derives from the title — ASCII kebab-case,
no dates in the filename.

## Document Format

```markdown
---
title: One-line summary of the symptom
date: YYYY-MM-DD
problem_type: bug
module: area or files affected (e.g. auth/tokens.py)
tags: [two, to, five, lowercase-kebab, tags]
symptoms: What was observed failing
root_cause: What actually caused it
resolution: What was changed to fix it
---

**Status**: fixed — YYYY-MM-DD
**Regression test**: tests/test_auth.py::test_expired_token_refresh

[Investigation narrative: evidence levels, disconfirming checks run, dead ends
worth remembering. Cite code as `file:line` and reference PR numbers, not bare
commit SHAs.]
```

## Field Notes

| Field | Rule | Example |
|-------|------|---------|
| `problem_type` | `bug`, `build-failure`, `test-failure`, `runtime-error`, `performance`, or `security` | `bug` |
| `symptoms` | The observable failure, not the diagnosis | `Login fails with 500 on expired tokens` |
| `root_cause` | What actually caused it | `Token refresh skipped when token expired <5s ago` |
| `resolution` | What was changed | `Added grace period check in token_refresh()` |
| **Status** (body) | `open`, `investigating`, `fixed — YYYY-MM-DD`, `wontfix — reason` | `fixed — 2026-03-19` |
| **Regression test** (body) | Test that guards against recurrence | `tests/test_auth.py::test_expired_token_refresh` |

A document written before the fix lands (status `open` / `investigating`) is
normal — update the same document as the investigation progresses; do not create
a sibling. If a required field is genuinely unknown, leave it empty and stamp
`needs_review: true` so `/memory-maintain` sweeps it.
