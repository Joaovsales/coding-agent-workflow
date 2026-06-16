---
name: quality-gate
description: 3-phase post-build quality review: structural quality (simplify), AI anti-patterns (deslop), APOSD design review. Run after all build tasks complete.
argument-hint: "[--scope <path>]"
disable-model-invocation: false
---

# /quality-gate — Post-Build Quality Review

3-phase sequential review run after all build tasks are complete. Each phase has a unique mandate.

## Scope

Determine files to review:
1. If `--scope <path>` provided: review only that path
2. Otherwise: `git diff --name-only <base>..HEAD` — all files changed since the build started

Skip: generated files, lock files, migration files, test fixtures.

---

## Phase 1 — Structural Quality (simplify)

**Mandate**: "Is this code structurally sound?" — function size, naming, reuse, SOLID.

For each file in scope:

### 1.1 Code Reuse
- **Duplicated logic** across files → extract shared function/module
- **Existing utilities** that already do what new code does → replace

### 1.2 Clean Code
- Functions **>20 LOC** → split
- Functions with **>3 parameters** → use options object/dataclass
- **Poor naming**: generic names (`data`, `info`, `tmp`, `result`) → rename to reveal intent
- **Dead code**: unreachable branches, unused imports → remove

### 1.3 SOLID
- **Single Responsibility**: class/function does more than one thing → split
- **Open/Closed**: new behavior via `if/else` chains → strategy/registry
- **Dependency Inversion**: hard-coded dependencies → inject

### 1.4 Unnecessary Complexity
- **Over-abstraction**: wrappers adding no value → inline
- **Premature generalization**: configurable with only one config → simplify
- **Defensive code for impossible cases** (internal values already guaranteed) → remove

**Process**: Read → list issues → fix → run tests after all fixes. Revert any fix that breaks tests.

---

## Phase 2 — AI Anti-Patterns (deslop)

**Mandate**: "Does this code contain AI behavioral artifacts?" — hedge words, filler, over-engineering.

**Iron law: deletion over rewriting.**

For each file in scope:

### 2.1 Hedge Words in Comments
Comments with: "should", "might", "probably", "seems to", "basically", "essentially"
→ Delete or rewrite as single declarative statement.

### 2.2 Restating-the-Code Comments
```
// Set the user name
user.name = name;
```
→ Delete. Code is documentation.

### 2.3 Over-Documented Simple Functions
Docstring longer than function body for trivial functions (getters, setters, one-liners)
→ Delete the docstring.

### 2.4 Obvious Type Annotations
```typescript
const name: string = "hello";  // type is self-evident
```
→ Remove annotation, let inference work.

### 2.5 Impossible-Case Error Handling
Guards on internal values already validated by the caller → Delete.
Keep validation ONLY at system boundaries (user input, API responses, file I/O).

### 2.6 Filler Abstractions
- Wrapper functions that just call another with same args
- Manager/Handler/Helper classes with one method
→ Inline and delete.

### 2.7 Verbose Logging
Entry/exit logging for short functions → Remove.
Keep only: surprising states, errors, branch decisions.

### 2.8 Passthrough Catch Blocks
```javascript
try { doThing(); } catch (e) { throw e; }  // passthrough
```
→ Remove entirely.

**Process**: Scan → list findings → apply deletions → run tests per file. Revert if tests fail.

---

## Phase 3 — Design Quality (APOSD)

**Mandate**: "Are modules well-designed?" — deep/shallow, info leakage, complexity flow.

### Inline checks (all harnesses):

Read all changed files together. For each module, check:

1. **Deep vs shallow**: Is the interface simpler than the implementation? Shallow = interface as complex as implementation → flag
2. **Information leakage**: Does a design decision appear in >1 file? → flag
3. **Pull complexity down**: Does the caller need internal knowledge to use this? → flag
4. **Temporal decomposition**: Is the module split by execution order, not responsibility? → flag
5. **Pass-through methods**: Any method that just forwards to another with same signature? → flag
6. **Vague names**: Any public name that requires reading the body to understand? → flag
7. **Conjoined methods**: Methods so coupled you can't use one without the other? → flag

Report findings as `file:line [MUST-FIX/SHOULD-FIX/NITPICK] — description`. Apply MUST-FIX and SHOULD-FIX fixes inline. Run tests after fixes.

## Claude Code Enhancements

Dispatch the `software-design-expert-review` skill (invokes `software-design-expert-review` agent, model: sonnet) instead of running inline Phase 3. The agent is read-only — it reports findings only. Apply MUST-FIX and SHOULD-FIX findings in the main context after the agent returns. Run tests after applying fixes.

---

## Output

```
══════════════════════════════════════════
  QUALITY GATE — [N] files reviewed
══════════════════════════════════════════

Phase 1 — Structural Quality
  Applied: [N changes — list with file:line]
  Tests: [PASS / FAIL — N reverted]

Phase 2 — AI Anti-Patterns
  Removed: [N lines — list with file:line and category]
  Tests: [PASS / FAIL — N reverted]

Phase 3 — APOSD Design (/software-design-expert-review)
  Verdict: 🟢 GO / 🟡 HOLD (N refactors applied) / 🔴 STOP
  Tests: [PASS / FAIL]

══════════════════════════════════════════
```
