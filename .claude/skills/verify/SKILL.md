---
name: verify
description: Enforce evidence-based verification before any completion claims. Use before committing, creating PRs, marking tasks done, or claiming success.
disable-model-invocation: false
---

# /verify — Verification Before Completion

## Overview

Claiming work is complete without verification is dishonesty, not efficiency. Every claim of success — tests passing, bugs fixed, builds clean, requirements met — must be backed by fresh, direct evidence obtained in the same message as the claim. Memory of a previous run is not evidence. Confidence is not evidence. Only output from a command you just ran is evidence.

## The Iron Law

```
NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE
```

If you have not run the verification command in this message, you cannot claim it passes. "It passed earlier" is not verification. "I'm confident it passes" is not verification. Running the command and reading the output is verification.

## The Gate Function

Before making any completion claim, execute every step in sequence:

1. **IDENTIFY**: What command proves this claim? Name it explicitly before running anything.
2. **RUN**: Execute the FULL command — no truncation, no partial scope, no skipped phases.
3. **READ**: Read the complete output. Check the exit code. Count failures. Do not skim.
4. **VERIFY**: Does the output confirm the claim?
   - If NO: State the actual status with the evidence. Do not claim completion.
   - If YES: State the claim WITH the supporting evidence (exit code, test counts, output excerpt).
5. **ONLY THEN**: Make the claim.

Skip any step = lying, not verifying.

## Common Failures

| Claim | Requires | Not Sufficient |
|-------|----------|----------------|
| Tests pass | Full test suite run with 0 failures and exit code 0 | "Tests passed before my change", partial suite run, running only the new test |
| Linter clean | Linter run on all changed files with 0 errors/warnings | Assuming no lint errors, running on a subset of files |
| Build succeeds | Build command exits 0 with no errors in output | Previous build succeeded, type checker passed |
| Bug fixed | Reproduction test now passes AND full suite still green | Reading the fix and concluding it is correct |
| Regression test works | Red-Green cycle: test failed before fix, passes after | Writing a test that only runs green |
| Agent completed | Reading agent output AND independently running verification commands | Trusting agent's self-reported "success" |
| Requirements met | Each acceptance criterion mapped to a passing test or demonstrated behavior | Reviewing the spec and believing the implementation matches |

## Red Flags — STOP

If you notice any of the following, stop and run the verification gate before proceeding:

- Using "should", "probably", "seems to", "likely", or "appears to" in a completion statement
- Expressing satisfaction before verification ("Great!", "Perfect!", "Done!", "That fixed it!")
- About to commit, push, or open a PR without a fresh test run in the same message
- Trusting an agent's success report without independently running verification commands
- Relying on partial verification ("I ran the unit tests" when integration tests also exist)
- Claiming a bug is fixed without running the reproduction test
- Any wording that implies success without having run and read verification output

These are not edge cases. They are common failure modes. Treat each one as a hard stop.

## Rationalization Prevention

The following rationalizations are not acceptable. Each has a correct response.

| Excuse | Reality |
|--------|---------|
| "Should work now" | RUN the verification command |
| "I'm confident" | Confidence is not evidence — run the command |
| "Just this once" | There are no exceptions to this rule |
| "Linter passed" | Linter is not compiler, compiler is not test suite — run all three |
| "Agent said success" | Agents self-report; verify independently with your own command run |
| "I'm tired" | Exhaustion does not change what counts as evidence |
| "Partial check is enough" | Partial verification proves partial things — run the full scope |
| "Different words so the rule doesn't apply" | The spirit of this rule governs, not the letter — if it is a completion claim, verify it |
| "The test I wrote proves it" | Only if the test ran red before the fix and green after — confirm both |
| "I reviewed the diff and it looks correct" | Code review is useful; it does not replace test execution |

## Verification Patterns

### Tests

**Correct:**
```
Run: pytest tests/ -v
Output: 47 passed, 0 failed (exit 0)
Claim: All tests pass.
```

**Incorrect:**
```
I made the fix. The tests should be passing now.
```

---

### Regression Tests (TDD Red-Green)

**Correct:**
```
Before fix — Run: pytest tests/test_auth.py::test_token_expiry -v
Output: FAILED (exit 1) — confirms reproduction

After fix — Run: pytest tests/test_auth.py::test_token_expiry -v && pytest tests/ -v
Output: PASSED, 47 passed, 0 failed (exit 0)
Claim: Bug is fixed. Regression test passes. No regressions introduced.
```

**Incorrect:**
```
I wrote a test for this case and the fix looks correct.
```

---

### Build

**Correct:**
```
Run: npm run build
Output: Build complete. 0 errors. (exit 0)
Claim: Build succeeds.
```

**Incorrect:**
```
The TypeScript errors are resolved so the build should pass.
```

---

### Requirements Checklist

**Correct:**
```
Acceptance criteria from specs/auth.md:
[AC-1] Token expires after 1 hour — test_token_expiry: PASS
[AC-2] Refresh token rotates on use — test_refresh_rotation: PASS
[AC-3] Revoked tokens rejected — test_revoked_token: PASS
Full suite: 47 passed, 0 failed.
Claim: All acceptance criteria met.
```

**Incorrect:**
```
The implementation covers all the acceptance criteria described in the spec.
```

---

### Agent Delegation Results

**Correct:**
```
Agent returned. Running independent verification:
Run: pytest tests/ -v
Output: 52 passed, 0 failed (exit 0)
Run: npm run lint
Output: 0 errors, 0 warnings (exit 0)
Claim: Agent implementation is verified. Tests and linter are clean.
```

**Incorrect:**
```
The backend-developer agent completed the task successfully.
```

## Integration

- **Required by**: `/build` (Phase 2 after each task, Phase 4 spec validation), `/debug` (Phase 3 loop verification), `/wrap-up-session` (Step 6 before commit)
- **Invoke before**: committing, PR creation, marking any task `[x]`, moving to the next task, reporting completion to the user

When any of the above trigger points is reached, run through the Gate Function for every claim that will appear in the completion report. Do not batch-assert without batch-verifying.

## The Bottom Line

No shortcuts for verification. Run the command. Read the output. THEN claim the result. This is non-negotiable.
