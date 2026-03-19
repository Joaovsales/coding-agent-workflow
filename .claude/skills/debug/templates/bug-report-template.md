# Bug Report Template

Use this format when adding entries to `tasks/bugs.md`.

## Entry Format

```markdown
| [ID] | [YYYY-MM-DD] | [One-line description] | [Root cause] | [Fix summary] | [file1, file2] | [status] | [test name/path] |
```

## Field Definitions

| Field | Description | Example |
|-------|-------------|---------|
| **ID** | Sequential bug ID | `BUG-001` |
| **Date** | Date discovered | `2026-03-19` |
| **Description** | One-line summary of the symptom | `Login fails with 500 on expired tokens` |
| **Root Cause** | What actually caused the bug | `Token refresh logic skipped when token expired <5s ago` |
| **Fix** | What was changed to fix it | `Added grace period check in token_refresh()` |
| **Files** | Comma-separated list of changed files | `auth/tokens.py, tests/test_auth.py` |
| **Status** | `open`, `investigating`, `fixed — YYYY-MM-DD` | `fixed — 2026-03-19` |
| **Regression Test** | Test that guards against recurrence | `tests/test_auth.py::test_expired_token_refresh` |

## Status Lifecycle

```
open → investigating → fixed — [date]
                     → wontfix — [reason]
                     → duplicate — [BUG-XXX]
```
