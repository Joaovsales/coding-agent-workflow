---
name: deslop
description: Detect and remove AI-generated anti-patterns (hedge words, over-abstraction, filler code). Use after /simplify or standalone on changed files.
---

# /deslop — AI Slop Cleaner

## The Iron Law

```
DELETION OVER REWRITING — REMOVE SLOP, DON'T REWORD IT
```

AI-generated code has specific anti-patterns that `/simplify` doesn't catch. `/simplify` targets structural issues (long functions, SOLID violations). `/deslop` targets AI behavioral artifacts — the filler, hedging, and over-engineering that LLMs produce by default.

## Detection Targets

### 1. Hedge Words in Comments
Comments containing: "should", "might", "probably", "seems to", "arguably", "Note:", "Important:", "basically", "essentially"

**Action**: Delete the comment entirely. If the comment contains useful information buried in hedge words, rewrite to a single declarative statement.

### 2. Restating-the-Code Comments
```
// Bad — says what the code already says:
// Increment the counter
counter++;

// Set the user name
user.name = name;
```

**Action**: Delete. The code is the documentation.

### 3. Over-Documented Simple Functions
Docstring/JSDoc longer than the function body for trivial functions (getters, setters, simple transforms, one-liners).

**Action**: Delete the docstring. If the function name is clear, no doc needed.

### 4. Obvious Type Annotations
```typescript
// Bad — type is self-evident:
const name: string = "hello";
const count: number = 0;
const items: string[] = [];
```

**Action**: Remove the annotation. Let inference work.

### 5. Impossible-Case Error Handling
```python
# Bad — this function only receives validated input from internal caller:
def process_item(item):
    if item is None:
        raise ValueError("item cannot be None")  # caller already validates
```

**Action**: Delete the guard. Trust internal contracts. Only validate at system boundaries.

### 6. Filler Abstractions
- Wrapper functions that just call another function with the same args
- "Manager" / "Handler" / "Helper" classes with one method
- Factory functions that return a single concrete type

**Action**: Inline the wrapper. Delete the abstraction layer.

### 7. Verbose Logging
```python
# Bad — logging repeats the function name and obvious context:
logger.info(f"Starting process_payment for user {user_id}")
# ... 3 lines of logic ...
logger.info(f"Finished process_payment for user {user_id}")
```

**Action**: Remove entry/exit logging for short functions. Keep logging only for surprising states, errors, or branch decisions.

### 8. Empty or Passthrough Catch Blocks
```javascript
// Bad:
try { doThing(); } catch (e) { throw e; }  // passthrough
try { doThing(); } catch (e) { /* ignore */ }  // swallowed
```

**Action**: Remove the try/catch entirely (passthrough) or add explicit handling with a reason comment (swallowed).

## Process

1. **Identify scope**: `git diff --name-only` against baseline (or explicit file list if provided)
2. **For each file**:
   a. Read the file
   b. Scan for each detection target (instruction-based, not regex)
   c. List findings: `file:line — [target category] — what to delete`
   d. Apply deletions (favor removing over rewriting)
   e. Run tests relevant to the file
   f. If tests fail: revert that file's changes, note it, move on
3. **Report results**

## Output Format

```
## Deslop Report

Files scanned: [N]
Files cleaned: [N]
Files skipped (test failure on cleanup): [N]

| File | Category | Lines Removed | Detail |
|------|----------|---------------|--------|
| `path/to/file.py:12` | Hedge comment | 2 | Removed "# This should probably..." |
| `path/to/file.ts:45` | Restating comment | 1 | Removed "// Set the name" |
| `path/to/util.ts:8-15` | Filler abstraction | 8 | Inlined wrapper function |

Total lines removed: [N]
Tests: [PASS / N files reverted due to test failure]
```

## When NOT to Deslop

- **Public API documentation** — keep docstrings on exported/public interfaces
- **Regulatory/compliance comments** — "GDPR: ...", "PCI-DSS: ..." stay
- **TODO/FIXME comments** — these are action items, not slop
- **Error handling at system boundaries** — keep validation on user input, API responses, file I/O
- **Logging in long-running or distributed processes** — entry/exit logging is valuable there

## Integration

- **Standalone**: `/deslop` on any file set
- **In `/build`**: Runs in Phase 3 after `/simplify`, before spec validation
- **In `/wrap-up-session`**: Can be run as part of the review-fix cycle

## Key Principle

The best code change is a deletion. Every line removed is a line that can't have bugs, can't confuse readers, and doesn't consume tokens in AI context windows.
