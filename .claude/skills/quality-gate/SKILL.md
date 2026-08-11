---
name: quality-gate
description: "3-phase post-build quality review: structural quality (simplify), AI anti-patterns (deslop), APOSD design review. Run after all build tasks complete."
argument-hint: "[--scope <path>]"
---

# /quality-gate — Post-Build Quality Review

> **Dispatching sub-agents?** Read `.agents/skills/build/references/subagent-resilience.md` first. This skill runs unattended, so a hung
> sub-agent has no human watching it: give every agent a tool-call budget with a "write partial
> work and stop" escape hatch, arm a stall monitor, and never retry a deterministic failure
> with an identical prompt.

3-phase sequential review run after all build tasks are complete. Each phase has a unique mandate.

## Scope

Determine files to review:
1. If `--scope <path>` provided: review only that path
2. Otherwise: `git diff --name-only <base>..HEAD` — all files changed since the build started

Skip: generated files, lock files, migration files, test fixtures.

---

## Finding Model (four axes)

Every finding in every phase carries four orthogonal fields. One axis cannot answer
another's question: an urgent finding may be a guess, and a certain finding may be
cosmetic. Collapsing them hides which is which.

| Field | Answers | Values |
|-------|---------|--------|
| `severity` | how urgent | `MUST-FIX` / `SHOULD-FIX` / `NITPICK` |
| `confidence` | how sure | `50` / `75` / `100` |
| `autofix_class` | what shape the fix is | `gated_auto` / `manual` / `advisory` |
| `owner` | who acts | `agent` / `human` / `release` |

**Confidence anchors** — pick by the behavioral criterion, never by feel:

| Anchor | Criterion |
|--------|-----------|
| `100` | The failure is reproduced, or the defect is visible in the quoted line without inference. |
| `75` | A concrete failing input or state is named and the quoted line plainly permits it, but it was not run. |
| `50` | Pattern-matched, inferred from naming, or dependent on caller behavior that was not read. |

**`owner` values**: `agent` — in this diff's scope, an agent applies it. `human` —
needs a decision or an access an agent does not have. `release` — real but not
blocking this branch.

**Evidence gate**: anchors `75` and `100` require `evidence` — the verbatim motivating
line with `file:line`. A finding at 75+ with no evidence is **demoted to 50**, never
discarded.

**Apply gate**: auto-apply a finding only when `autofix_class: gated_auto` **and**
`confidence >= 75`. Everything else is reported, not applied.

**On disagreement** between reviewers, synthesis takes the **more conservative**
`autofix_class` — `advisory` is more conservative than `manual`, which is more
conservative than `gated_auto`. Synthesis never widens.

**Old-format degrade**: a finding arriving with no `confidence` is handled as anchor
`50` / `autofix_class: manual` — reported, never auto-applied and never discarded.

Per-finding output format:

```
[MUST-FIX] conf=100 fix=gated_auto owner=agent handler.py:120 — Description and impact
  evidence: `except Exception: pass` (handler.py:120)
```

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

**Never delete `TODO`, `FIXME`, or `TODO(shortcut):` markers.** They record a known
limitation and its upgrade path, so they must survive this phase even when the
surrounding comment is reworded. A deliberate shortcut is not slop.

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

**Process**: Scan → list findings → apply deletions that clear the apply gate → run tests per file. Revert if tests fail.

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

Report every finding in the four-axis format above. Apply only findings that clear the
apply gate; report the rest. Run tests after fixes.

### Independence disclosure (required)

Phase 3 must state in its output which mode it ran in, because the two are otherwise
indistinguishable downstream:

- **Dispatched** — the design review ran as a separately dispatched agent. Its
  agreement with a Phase 1 or Phase 2 finding is independent corroboration and
  promotes `confidence` by exactly one anchor.
- **Inline** — the checks above ran in this context. Agreement with Phase 1 or Phase 2
  is same-context agreement and **never** promotes. Name the corroboration that was
  unavailable.

Per `CLAUDE.md` § *Independence Accounting*. Inline is the correct floor, not a failure.

## Claude Code Enhancements

Dispatch the `software-design-expert-review` skill (invokes the
`software-design-expert-review` agent, model: sonnet) instead of running inline Phase 3.
The agent is read-only — it reports findings only. In the main context, apply the
returned findings that clear the apply gate and report the rest. Run tests after
applying fixes. This is the **dispatched** mode for the disclosure above.

---

## Output

```
══════════════════════════════════════════
  QUALITY GATE — [N] files reviewed
══════════════════════════════════════════

Phase 1 — Structural Quality
  Applied: [N changes — list with file:line, conf, fix, owner]
  Reported only: [N findings below the apply gate — list with the axis that held them]
  Tests: [PASS / FAIL — N reverted]

Phase 2 — AI Anti-Patterns
  Removed: [N lines — list with file:line and category]
  Reported only: [N findings below the apply gate]
  Tests: [PASS / FAIL — N reverted]

Phase 3 — APOSD Design (/software-design-expert-review)
  Mode: DISPATCHED / INLINE — [when inline: corroboration unavailable, no promotion]
  Verdict: 🟢 GO / 🟡 HOLD (N refactors applied) / 🔴 STOP
  Reported only: [N findings below the apply gate]
  Tests: [PASS / FAIL]

Demoted: [N findings at 75+ with no file:line evidence → anchor 50]

══════════════════════════════════════════
```
