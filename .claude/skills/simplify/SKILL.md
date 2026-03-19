---
name: simplify
description: Review changed code for reuse, clean code, and SOLID violations, then fix issues found.
argument-hint: "[optional file path]"
---

# /simplify — Code Simplification Review

Review recently changed code for reuse opportunities, quality issues, and unnecessary complexity. Fix any issues found.

## Scope

Determine files to review:
1. If invoked with a file path argument: review that file
2. Otherwise: review all changed files via `git diff --name-only HEAD~1..HEAD` and `git diff --name-only` (staged + unstaged)
3. Skip generated files, lock files, and test files (tests are reviewed only for duplication)

## Review Checklist

For each file, check:

### 1. Code Reuse
- **Duplicated logic** across files or within the same file → extract shared function/module
- **Copy-pasted patterns** with minor variations → parameterize into a single function
- **Existing utilities** that already do what new code does → replace with the existing utility

### 2. Clean Code Violations
- Functions **>20 LOC** → split into smaller, focused functions
- Functions with **>3 parameters** → use an options object/dataclass
- **Poor naming**: abbreviations, generic names (`data`, `info`, `tmp`, `result`) → rename to reveal intent
- **Mixed abstraction levels** in a single function → separate high-level flow from low-level detail
- **Dead code**: unreachable branches, unused imports, commented-out code → remove entirely

### 3. SOLID Violations
- **Single Responsibility**: class/function does more than one thing → split
- **Open/Closed**: new behavior added via `if/else` chains → refactor to strategy/registry pattern
- **Dependency Inversion**: hard-coded dependencies → inject via constructor/parameter

### 4. Unnecessary Complexity
- **Over-abstraction**: wrapper classes/functions that add no value → inline them
- **Premature generalization**: configurable code with only one configuration → simplify to the concrete case
- **Defensive code for impossible cases**: validation of internal values that are already guaranteed → remove
- **Feature flags or backwards-compat shims** for removed features → clean up

### 5. Efficiency
- **Redundant computations**: same value calculated multiple times → compute once and reuse
- **N+1 patterns**: loops making individual calls that could be batched → batch
- **Unnecessary allocations**: building large intermediate structures when streaming/iterating would suffice

## Process

1. **Read** each file in scope
2. **List issues** found with file path, line range, and category
3. **Fix** each issue directly (edit the file)
4. **Re-run tests** after all fixes to confirm nothing broke
5. If tests fail after a simplification: **revert that change** and move on

## Output

```
══════════════════════════════════
  SIMPLIFY — [N] files reviewed
══════════════════════════════════

Changes Applied:
  - [file:line] [category] — [short description of change]
  - [file:line] [category] — [short description of change]

No Issues:
  - [files that were already clean]

Tests: [PASS / FAIL — reverted N changes]
══════════════════════════════════
```

## Principles

- **Only simplify, never add features.** This is a reduction pass, not an enhancement.
- **Preserve behavior.** Every change must be test-verified.
- **Small edits.** One logical change at a time so failures are easy to isolate.
- **Trust the tests.** If tests pass after simplification, the change is safe. If they fail, revert.
