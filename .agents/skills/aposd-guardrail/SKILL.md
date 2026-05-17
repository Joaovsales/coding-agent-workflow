---
name: aposd-guardrail
description: >
  A Philosophy of Software Design (APOSD) guardrail skill. Runs a structured design
  review before a coding task is considered "done". Use after implementing a feature,
  refactoring, or completing a TDD cycle. Scans for information leakage, repetition,
  shallow modules, temporal decomposition, and other APOSD red flags. Produces a
  go/no-go recommendation with actionable refactoring tasks. Must gate the "done"
  decision; do NOT mark a backlog item complete until this skill's review is
  satistfactory. Compatible with any pi project and any language.
compatibility: >
  Requires a git repository or explicit file input. Works with Python, TypeScript,
  Go, Rust, or any language. No external dependencies for the review itself.
  Optional prettier HTML report generator requires Python 3.9+.
---

# APOSD Guardrail — Design Review Skill

## Overview

This skill prevents the classic trap: *"the spec is green so the task is done.*”  
It runs a structured design review based on **A Philosophy of Software Design** by
John Ousterhout (APOSD). The review is **blocking** — a task is NOT complete until
this guardrail is satisfied.

**When to run:**
- After passing tests but before marking a backlog item "done"
- After any significant refactor
- After adding a new module, class, or architectural layer
- Proactively: user asks "is this good enough?" or "can we ship this?"

**How to run:**
```bash
/skill:aposd-guardrail            # Review all uncommitted / recently touched files
/skill:aposd-guardrail --file path/to/module.py   # Scope to one file
/skill:aposd-guardrail --scope circuit-breaker    # Scope to functional area
```

---

## Workflow (Blocking Gate)

The review is a **3-phase gate**. If any phase fails, the task stays in-flight.

### Phase 0 — Gather Evidence (Required)

1. Run `git diff --stat` (or accept the `--file` / `--scope` argument).
2. For each changed file, capture approximate size and nature (new/modified/deleted).
3. Identify any files that were touched but have **no tests** — flag immediately.

### Phase 1 — Structured Design Review (Required)

Run every module through the APOSD lens. For each module (function, class, file)
in the change set, answer these questions:

#### P1. Deep vs Shallow
- Is the interface simple relative to the functionality provided?
- Does a caller need to know internal state names (HALF_OPEN, etc.) to use it?
- Rule of thumb: if a module's docstring is longer than its public API, it may be shallow.

#### P2. Information Hiding / Leakage
- Does the module expose implementation details that callers shouldn't know?
  - Example: `_deduplicate_pipeline` repeating DB column names that `PDFCrud` should own.
- If someone renames a DB column or changes a lock implementation, how many files change?

#### P3. Pull Complexity Downward
- Did we make the caller's life easier at the expense of the implementation?
  - Example: `get_circuit_breaker(name)` hides registry lifecycle vs. callers constructing breakers inline.
- Or did we push complexity UPWARD (worse interface, simpler implementation)?

#### P4. General vs Special-Purpose
- Could this module be more general without adding complexity?
- If we added a new provider tomorrow, would we need to modify this file?

#### P5. Define Errors Out of Existence
- Did we "design away" an error rather than handling it?
  - Example: deduplication via content hash eliminates the "duplicate processing" error entirely.
- Are there exceptions that a better design would make impossible?

#### P6. Design It Twice (Quick Check)
- Was at least one radically different approach considered?
- If not, ask: how would the code look if we inverted the dependency?

#### P7. Naming
- Are names self-explanatory without comments?
  - Red flags: `data`, `result`, `count`, `tmp`, `process`, `handle`, `item`.
- Would a new teammate understand `copy_pipeline_artifacts` without reading the body?

### Phase 2 — Red Flags Checklist (Required)

Explicitly scan for and report each item:

| # | Flag | What to look for |
|---|------|-----------------|
| R1 | **Repetition** | Same pattern ≥3 times → missing abstraction. |
| R2 | **Pass-Through Methods** | Method that only forwards to another with a similar signature. |
| R3 | **Information Leakage** | A design decision visible in >1 module (column names, state enum values, URLs). |
| R4 | **Vague Names** | Variables/functions whose purpose is unclear from the name alone. |
| R5 | **Temporal Decomposition** | Modules split by execution order (step1→step2→step3) rather than functionality. |
| R6 | **Change Amplification** | A small requirement change requires touching many files. |
| R7 | **High Cognitive Load** | Caller needs to know lock states, async internals, DB schema to use the API. |
| R8 | **Unknown Unknowns** | Hidden side effects, implicit ordering contracts, mutable shared state. |
| R9 | **Shallow Module** | Simple functionality with a complex interface (many params, many preconditions). |
| R10 | **Conjoined Methods** | Methods that must be called in a specific order; state machine by convention. |

For each flag found:
- **WHO** — which file/line/module
- **WHY** — what principle it violates
- **IMPACT** — what will happen when the codebase grows
- **FIX** — concrete refactoring (not vague "could be better")

### Phase 3 — Go / No-Go Decision (Blocking)

Produce a **single verdict**:

```
🟢 GO   — No red flags, or only trivial cosmetic issues.
🟡 HOLD — Non-trivial red flags found but contained. Refactor before merge.
🔴 STOP — Critical red flag found. Do NOT mark task complete. Design first, code second.
```

**Rules:**
- `GO` requires **zero** R1–R10 red flags of severity ≥ MEDIUM.
- `HOLD` is acceptable if the refactor tasks are listed with file:line targets and the user explicitly acknowledges them.
- `STOP` is required for any R8 (Unknown Unknowns) that could cause production bugs.

**Do NOT let the user override a `STOP` verdict by saying "it's good enough."**  
The skill's job is to *enforce* the APOSD discipline.

### Phase 4 — Actionable Output (Required on HOLD or STOP)

1. List every file:line that needs a change.
2. Group by theme (e.g., "Information Leakage in CRUD layer").
3. Provide a one-paragraph sketch of the ideal end-state.
4. Include a **checklist** of exact edits required to reach GO.

---

## Output Format

```markdown
# APOSD Guardrail Review — <scope>

## Session Narrative
[One paragraph: what was built and why.]

## Evidence
| File | Δ | Nature |
|------|---|--------|

## Design Principles Check
| Principle | Verdict | Evidence |
|-----------|---------|----------|
| Deep vs Shallow | 🟢/🟡/🔴 | ... |
| Information Hiding | 🟢/🟡/🟴 | ... |
| Pull Complexity Down | 🟢/🟡/🔴 | ... |
| General vs Special | 🟢/🟡/🔴 | ... |
| Define Errors Away | 🟢/🟡/🔴 | ... |
| Design It Twice | 🟢/🟡/🔴 | ... |

## Red Flags
| # | Flag | Severity | Location | Fix |
|---|------|----------|----------|-----|

## Verdict
🟢 GO / 🟡 HOLD / 🔴 STOP

## Required Refactors (if HOLD/STOP)
1. [file:line] **Problem** → **Action**
2. ...

## Learning Moment
> One APOSD principle applied directly to this code, with a reflective question.
```

---

## Templates

- `templates/review-report.md` — Markdown skeleton for copy-paste output
- `templates/handoff-prompt.md` — Prompt for delegating to a subagent or pi skill
- `templates/checklist-pre-commit.md` — Go/no-go checklist template

## References

- `references/principles.md` — Full catalog of APOSD principles with examples
- `references/red-flags-catalog.md` — Each red flag with code-smell symptoms and refactor recipes
- `references/exit-criteria.md` — What "done" really means in a quality-gated workflow

## Scripts

- `scripts/generate-report.py` — (Optional) Converts markdown review into interactive HTML report with:
  - Dark/light toggle
  - Principles grid with links to Stanford APOSD course
  - Expand/collapse diffs
  - Copy-to-clipboard code blocks

---

## Confidence Notes for Craftsmen

> "If you had to explain this module to a new teammate in one sentence, could you?
> If not, the module is too shallow or poorly named."

> "The best module is one where the interface is so simple that the implementation
> could be completely rewritten without callers noticing."

> "A task is not done when the tests pass. A task is done when the next developer
> who touches this code will not curse your name."
