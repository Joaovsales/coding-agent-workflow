# APOSD Guardrail — Go / No-Go Checklist

Use this checklist to gate the "done" decision. Every item must be consciously
answered before merging. No skipped items allowed.

---

## Pre-Flight Checks (Auto-Verify)

- [ ] All new/modified code is covered by tests (even error paths)
- [ ] `pytest` (or relevant test runner) passes with no warnings
- [ ] No `print()` statements left in production code (use logging)
- [ ] No hardcoded secrets, API keys, or credentials in diff
- [ ] Git diff inspected — no accidental file inclusions

## Design Principles (Human / Agent Review)

- [ ] **Deep Modules**: Every new public API is simpler than its implementation. If the docstring is longer than the call site, it's too shallow.
- [ ] **Information Hiding**: No DB column names, lock types, state enum values, or URL patterns leaked across module boundaries.
- [ ] **Pull Complexity Down**: Callers do NOT need to know about internal state machines, ordering rules, or lock acquisition to use the module.
- [ ] **General vs Special**: Could this be more general without much extra code? If a similar feature arrives tomorrow, would we copy-paste this?
- [ ] **Define Errors Away**: Are there exception types that a better design would make impossible?
- [ ] **Design It Twice**: Was at least one alternative approach sketched and rejected with a reason?
- [ ] **Naming**: Every public name is self-explanatory without reading the body. No `data`, `result`, `tmp`, `process`, `handle`.

## Red Flags (Explicit Scan)

- [ ] **R1 Repetition**: No pattern appears ≥3 times without an abstraction (function, class, decorator, or data structure).
- [ ] **R2 Pass-Through**: No method that only forwards to another with the same signature.
- [ ] **R3 Info Leakage**: No design decision visible in >1 file that should belong to 1.
- [ ] **R4 Vague Names**: No variable/function name whose purpose is not obvious from the name alone.
- [ ] **R5 Temporal Decomposition**: No module split by execution order rather than functionality.
- [ ] **R6 Change Amplification**: A small requirement change would NOT require touching many files.
- [ ] **R7 Cognitive Load**: A new teammate does NOT need to know unrelated internals to use the public API.
- [ ] **R8 Unknown Unknowns**: No hidden side effects, implicit contracts, or mutable shared state surprises.
- [ ] **R9 Shallow Module**: No module where the interface is more complex than the functionality it provides.
- [ ] **R10 Conjoined Methods**: No methods that must be called in a specific order (state by convention).

## Verdict

- [ ] 🟢 **GO** — All checks pass. Zero red flags ≥ MEDIUM.
- [ ] 🟡 **HOLD** — Red flags found, but contained. Refactor list below is complete.
- [ ] 🔴 **STOP** — Critical red flag found. Do NOT merge. Redesign required.

## If HOLD or STOP — Refactor Log

| # | file:line | Problem | Fix | Status |
|---|-----------|---------|-----|--------|
| 1 | | | | |
| 2 | | | | |

## Sign-Off

**Reviewer**: ____________________
**Date**: ____________________
**Task**: ____________________

> "A task is not done when the tests pass. A task is done when the next developer
> who touches this code will not curse your name."
