# Condition-Based Waiting

Replace arbitrary timeouts with condition polling to eliminate flaky tests.

**Core principle:** Wait for the actual condition you care about, not a guess about how long it takes.

## When to Use

- Tests contain `setTimeout`, `sleep`, or arbitrary delays
- Tests fail inconsistently (flaky)
- Tests fail under load or in CI but pass locally
- Waiting for async operations to complete

## When NOT to Use

- Testing actual timing behavior (debounce, throttle)
- Documented system intervals with known timing
- Performance benchmarks

## The Pattern

```typescript
async function waitFor(
  condition: () => boolean | Promise<boolean>,
  options?: { timeout?: number; interval?: number }
): Promise<void> {
  const timeout = options?.timeout ?? 5000;
  const interval = options?.interval ?? 10;
  const start = Date.now();

  while (Date.now() - start < timeout) {
    if (await condition()) return;
    await new Promise(r => setTimeout(r, interval));
  }
  throw new Error(`Condition not met within ${timeout}ms`);
}
```

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Polling too aggressively (1ms) | Use 10-50ms intervals |
| No timeout | Always set a maximum wait time |
| Caching stale data | Re-evaluate condition fresh each poll |
| Testing timing instead of state | Wait for state change, not elapsed time |

## Example Refactor

**Before (flaky):**
```typescript
await doAsyncThing();
await sleep(500); // hope it's done
expect(result).toBe('done');
```

**After (reliable):**
```typescript
await doAsyncThing();
await waitFor(() => result === 'done');
expect(result).toBe('done');
```

## Results

From real-world application:
- Pass rate: 60% → 100%
- Execution time: 40% faster (no unnecessary waiting)
- Flaky test tickets: eliminated
