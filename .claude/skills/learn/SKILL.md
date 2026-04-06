---
name: learn
description: Extract durable patterns from the current session and persist to memory.md and lessons.md.
disable-model-invocation: false
---

# /learn — Capture Session Learnings

Extract durable patterns from this session and persist them into `.claude/memory.md` and `tasks/lessons.md`.

## Steps

### 1. Review the Session
- Run `git log --oneline -10` to see what changed
- Read `tasks/todo.md` to see what was completed
- Read `tasks/lessons.md` for any notes made mid-session
- Recall any corrections the user made or surprises encountered

### 2. Extract 1–5 Patterns
Focus on insights that would prevent future mistakes or speed up future work:
- Mistakes made and their root causes
- Effective approaches discovered
- Architectural decisions and the reasoning behind them
- Edge cases that weren't anticipated
- Tool or workflow patterns that worked well

Skip trivial or one-off observations. Only persist patterns with reuse value.

### 3. Format Each Learning

```
### [Short descriptive title]
**Context**: When does this pattern apply?
**Pattern**: What to do (or avoid)
**Evidence**: What triggered this insight
```

### 4. Append to `.claude/memory.md`
Under the "Patterns & Lessons" section, append each new learning.

### 5. Append Session Summary to `.claude/memory.md`
Under the "Session History" section:

```
### [YYYY-MM-DD] — [2-3 word summary]
- Key changes: [bullet list of what was built/changed]
- Lessons added: [number, or "none"]
```

### 6. Update `tasks/lessons.md`
Mirror the patterns into `tasks/lessons.md` if it exists (tactical, project-specific lessons).

### 7. Confirm
Reply: "Learnings captured. `.claude/memory.md` and `tasks/lessons.md` updated."
