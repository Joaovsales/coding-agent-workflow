# Evidence Strength Hierarchy

Reference for `/debug` Phase 1 — ranking evidence by discriminating power.

## The Hierarchy (Strongest → Weakest)

### Level 1 — Controlled Reproduction
A test or procedure that **isolates the exact cause** and can toggle the bug on/off.

- Minimal reproduction test that fails with the bug and passes without
- Bisected commit that introduces the behavior
- Environment variable or config flag that enables/disables the symptom

**Use when**: You can write a failing test or bisect to a specific change.

### Level 2 — Primary Artifacts
**Timestamped, provenance-tracked records** directly produced by the system.

- Application logs with timestamps bracketing the failure
- Database query logs showing the exact state transition
- Git history showing when the code changed
- Metrics/traces from monitoring (APM, error tracking)

**Use when**: Reproduction is hard but system telemetry is available.

### Level 3 — Multiple Independent Sources Converging
**Two or more unrelated evidence streams** pointing to the same explanation.

- Log analysis AND code inspection both suggest the same root cause
- Error rate spike AND deploy timestamp correlate
- User report AND automated alert describe the same symptom

**Use when**: No single piece of evidence is conclusive, but multiple weak signals align.

### Level 4 — Single Code-Path Inference
The code **could** produce the observed behavior, but nothing uniquely discriminates this explanation from alternatives.

- "This function doesn't handle null, and the error is a null reference"
- "This race condition could explain the intermittent failure"

**Use when**: You can trace a plausible path through the code but haven't confirmed it's THE path.

### Level 5 — Circumstantial Clues
**Naming, proximity, timing, or position** suggest a connection without confirming it.

- "The error started around the time this file was changed"
- "The failing function is near the function that was recently modified"
- "The variable name suggests it holds user input"

**Use when**: You're forming initial hypotheses before deeper investigation.

### Level 6 — Intuition or Analogy
**No concrete evidence** — reasoning by pattern matching against past experience.

- "This feels like a caching issue"
- "Similar bugs in other projects were caused by..."
- "My gut says it's a race condition"

**Use when**: Starting investigation only. Never present Level 6 as a conclusion.

## Usage in Debugging

When forming hypotheses in Phase 1:
1. **Label each piece of evidence** with its level (1-6)
2. **Down-rank explanations** supported only by Level 5-6 evidence when Level 1-3 evidence contradicts them
3. **Seek disconfirming evidence** — actively try to disprove your leading hypothesis
4. **Escalate investigation** if the best available evidence is Level 4+ after reasonable effort

When reporting findings:
- State the evidence level for each claim
- Never present Level 4+ evidence with the same confidence as Level 1-2
- If all evidence is Level 5-6: acknowledge uncertainty, recommend discriminating tests
