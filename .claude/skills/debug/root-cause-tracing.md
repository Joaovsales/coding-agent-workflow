# Root Cause Tracing

Bugs often manifest deep in the call stack. Your instinct is to fix where the error appears, but that's treating a symptom.

**Core principle:** Trace backward through the call chain until you find the original trigger, then fix at the source.

## When to Use

- Error happens deep in execution (not at entry point)
- Stack trace shows long call chain
- Unclear where invalid data originated
- Need to find which code path triggers the problem

## The Tracing Process

### 1. Observe the Symptom
- Note the exact error message and location
- Record the full stack trace
- Identify the immediate failing operation

### 2. Find Immediate Cause
- What value is wrong at the failure point?
- What operation received bad input?

### 3. Ask: What Called This?
- Trace one level up in the call chain
- What value did the caller pass?
- Where did the caller get that value?

### 4. Keep Tracing Up
- Repeat step 3 at each level
- At each level, check: is this where the value becomes invalid?
- Stop when you find the level where valid data becomes invalid

### 5. Find Original Trigger
- This is the root cause — where the data first goes wrong
- Fix HERE, not at the symptom location

## Adding Diagnostic Instrumentation

When manual tracing is difficult, add temporary logging:

```
For EACH level in the call chain:
  Log what data enters the function
  Log what data exits the function
  Log any transformations applied

Run once to gather evidence
Remove instrumentation after diagnosis
```

Use `console.error()` in tests (not logger — may not show). Include:
- Current values of relevant variables
- Current working directory or environment
- Stack trace via `new Error().stack`

## Key Principle

**NEVER fix just where the error appears. Trace back to find the original trigger.**

Fix at source, not at symptom. Then add validation at intermediate layers to prevent recurrence.
