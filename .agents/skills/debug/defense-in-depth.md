# Defense-in-Depth Validation

After finding and fixing a root cause, add validation at multiple layers to make the bug structurally impossible to recur.

**Core principle:** Validate at EVERY layer data passes through. Make the bug structurally impossible.

## The Four Layers

### 1. Entry Point Validation
Check incoming data at API/function boundaries:
- Reject obviously invalid inputs (empty strings, nulls, negative counts)
- Validate types and ranges
- Return clear error messages

### 2. Business Logic Validation
Ensure data is appropriate for the specific operation:
- Check preconditions before processing
- Validate state transitions
- Verify assumptions about data relationships

### 3. Environment Guards
Add context-specific safeguards:
- Prevent dangerous operations outside expected directories
- Validate configuration before use
- Check resource availability before consumption

### 4. Debug Instrumentation
Capture diagnostic information for future investigations:
- Log unexpected but non-fatal conditions
- Record state at key checkpoints
- Add assertions for invariants that should always hold

## Verification

After implementing all layers:
1. Test that removing any single layer still catches the bug at another layer
2. Verify all layers work together without false positives
3. Confirm the original reproduction test still passes

## Why Single Validation Fails

- Different code paths can bypass a single check
- Refactoring can accidentally remove the one guard
- Test mocks can hide that the guard isn't working
- Multiple layers create redundancy — the system stays safe even if one layer is bypassed
