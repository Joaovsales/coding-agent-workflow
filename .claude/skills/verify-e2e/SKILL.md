---
name: verify-e2e
description: Force end-to-end browser validation of user-facing acceptance criteria before wrap-up. Use after /build when any AC describes user-facing behavior (auth flows, forms, navigation, UI state).
disable-model-invocation: false
---

# /verify-e2e — End-to-End Walkthrough Gate

Unit tests prove functions work. E2E walkthroughs prove features work.
This skill forces the latter before a feature is allowed to ship.

## When to Invoke

- Automatically by `/build` Phase 4 when any AC is classified `user-facing`
- Automatically by `/wrap-up-session` Step 6.3 when specs changed this session
- Manually before claiming any feature with a UI or user flow is complete

## Pre-Flight

1. Read the active spec from `specs/` and extract **user-facing ACs**
2. Verify the app is running locally (check dev server health endpoint, start via `/start-qa` if not)
3. Verify the browser MCP is available (Playwright or Chrome)
4. Load authentication state the way a real user would — cookie-based session, not injected tokens. For Supabase: use the `@supabase/ssr` cookie flow.

## Walkthrough Protocol

For each user-facing AC:

1. **Describe the user journey** in plain language:
   > "A new user lands on /signup, enters email + password, receives verification email, clicks link, lands on /dashboard logged in."

2. **Execute each step in the real browser** via MCP tool calls:
   - Navigate to URL
   - Interact with real DOM (click, type, submit)
   - Wait for real network responses
   - Capture screenshot at each checkpoint

3. **Assert observable state** at each step:
   - URL matches expected route
   - Required text/element is visible
   - Network request succeeded with expected status
   - No console errors

4. **Negative path check**: run at least one failure variant per AC (wrong password, invalid email, missing permissions)

## Evidence Format

Append to `tasks/e2e-log.md` (create the file if it does not exist; do not commit it empty):

```markdown
## E2E Walkthrough — <Feature Name> — <YYYY-MM-DD> <short-sha>

Spec: specs/<feature>.md
Commit: <full-sha>

### AC-1: <criterion text>
Journey: <plain-language steps>
Steps executed:
  ✓ Navigate /signup → 200, form visible
  ✓ Fill email=test@example.com, password=***
  ✓ Submit → 302 to /verify-email
  ✓ Click verification link → 200, redirect /dashboard
  ✓ Assert session cookie set, user email displayed
Negative: invalid email rejected with inline error ✓
Screenshots: [paths]
Result: PASS

### AC-2: <criterion text>
...
```

The log is **append-only**. Each invocation writes a new section keyed by feature name + commit short-sha. Never overwrite a prior walkthrough — they form the audit trail consumed by `/wrap-up-session` Step 6.3.

## Failure Handling

- **Step fails**: STOP the walkthrough, report the exact step + evidence, do not mark the AC complete. Hand back to `/build` or `/debug`.
- **MCP browser unavailable**: STOP. Do not fall back to curl or unit tests. Report: "E2E gate cannot be satisfied without a browser MCP."
- **Auth fails repeatedly**: STOP after 2 attempts. Do not retry with different credentials. Report to user and request guidance — this is usually a cookie/session misconfiguration, not a credential issue.
- **Dev server unreachable**: STOP. Invoke `/start-qa` to bring it up, then resume. Do not assume it is "probably running."

## Iron Laws

1. **A real browser must load the real app.** No simulated DOM, no jsdom, no headless emulation that bypasses the network.
2. **Authentication must go through the real login flow.** No token injection, no pre-seeded session cookies, no test-only auth backdoors.
3. **Every user-facing AC gets its own walkthrough entry.** No batching ACs into a single composite entry.
4. **A failed step halts the walkthrough.** Do not cascade to the next AC after a failure.
5. **Evidence is the `tasks/e2e-log.md` entry with screenshots, not a summary claim.** If the log entry does not exist, the walkthrough did not happen.

## Integration

- **Invoked by**: `/build` Phase 4 (automatic for user-facing ACs), `/wrap-up-session` Step 6.3 (gate before push)
- **Invokes**: `/start-qa` (to bring up the dev server if needed), `/debug` (on walkthrough failure)
- **Writes**: `tasks/e2e-log.md` (append-only evidence log)
- **Read by**: `/wrap-up-session` Step 6.3 (matches commit short-sha against e2e log entries)
