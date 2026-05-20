---
name: verify
description: Enforce evidence-based verification before any completion claims. Supports --scope deployment and --scope e2e. Use before committing, creating PRs, marking tasks done, or claiming success.
argument-hint: "[--scope deployment|e2e]"
harness: universal
---

# /verify — Verification Before Completion

## Overview

Claiming work is complete without verification is dishonesty, not efficiency. Every claim of success must be backed by fresh, direct evidence obtained in the same message as the claim. Memory of a previous run is not evidence. Confidence is not evidence. Only output from a command you just ran is evidence.

## The Iron Law

```
NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE
```

---

## Default Mode (no flag)

Before making any completion claim, execute every step in sequence:

1. **IDENTIFY**: What command proves this claim? Name it explicitly before running anything.
2. **RUN**: Execute the FULL command — no truncation, no partial scope, no skipped phases.
3. **READ**: Read the complete output. Check the exit code. Count failures. Do not skim.
4. **VERIFY**: Does the output confirm the claim?
   - If NO: State the actual status with evidence. Do not claim completion.
   - If YES: State the claim WITH supporting evidence (exit code, test counts, output excerpt).
5. **ONLY THEN**: Make the claim.

Skip any step = lying, not verifying.

### Common Failures

| Claim | Requires | Not Sufficient |
|-------|----------|----------------|
| Tests pass | Full test suite with 0 failures and exit code 0 | Partial suite run, running only the new test |
| Linter clean | Linter on all changed files with 0 errors | Assuming no lint errors |
| Build succeeds | Build command exits 0 with no errors | Previous build succeeded |
| Bug fixed | Reproduction test passes AND full suite green | Reading the fix and concluding it's correct |
| Requirements met | Each AC mapped to passing test or demonstrated behavior | Reviewing the spec and believing it matches |

### Red Flags — STOP

- Using "should", "probably", "seems to", "likely", or "appears to" in a completion statement
- Expressing satisfaction before verification ("Great!", "Perfect!", "Done!")
- About to commit or push without a fresh test run in the same message
- Trusting an agent's success report without independently running verification commands
- Relying on partial verification

---

## `--scope deployment`

Wait for post-push deployment builds to resolve. On failure, fetch logs, fix, push, and loop. Maximum 3 fix iterations per service before escalation.

This scope is **service-agnostic** — all service-specific behavior comes from runbook files in `tasks/deployments/<service>.md`.

### Pre-Flight

1. Run `git status --porcelain`. If any output: STOP — uncommitted changes must be resolved first.
2. Locate the routing table: look for `^## Deployment Targets[[:space:]]*$` in `.claude/project.md` (primary, Claude Code only), then `CLAUDE.md` (legacy fallback with deprecation warning).
3. Resolve: `git rev-parse HEAD` (current SHA), `git rev-parse --abbrev-ref HEAD` (branch), confirm remote exists.
4. Filter: keep only target rows whose `Triggers on branch` matches the current branch. If empty: skip silently.

### Per-Target Verification

For each applicable target:

**A. Load and validate the runbook** from `tasks/deployments/<service>.md`. Required fields: `name`, `display_name`, `detect_files`, `status_source`, `auth_check_command`, `dashboard_url_template`, `default_timeout_minutes`.

**B. Auth check**: run `auth_check_command`. If non-zero: mark `AUTH_FAILED`, move to next target.

**C. Poll for build status**:
- `github-checks` path: poll `mcp__github__get_commit`, filter by `check_contexts`, wait for all to succeed
- `cli` path: run `cli_status_command`, parse `state` or `status` field
- Poll intervals: 15s for first 2min, then 30s. Timeout per runbook config.
- Transient errors retry at polling layer (5s → 10s → 20s backoff). Don't consume a fix iteration.

**D. Fix loop** (max 3 iterations on failure):
1. Fetch logs (via `log_fetch_command` or `details_url`)
2. Match `common_failure_patterns` hints
3. Diagnose and apply fix in main context
4. Commit fix as NEW commit: `fix(deploy): <summary> [deploy-retry N/3]`
5. Push and restart poll

**E. Escalation**: after 3 failed iterations, write `tasks/deploy-report.md` and mark `FAILED_MAX_ITERATIONS`.

### Outcomes

| State | Action |
|-------|--------|
| `ALL_GREEN` | Proceed, record attempt counts |
| `AUTH_FAILED` | STOP — report which auth check failed |
| `TIMEOUT` | STOP — report dashboard URL, ask user |
| `CANCELLED` | STOP — ask user whether to proceed |
| `FAILED_MAX_ITERATIONS` | STOP — point to `tasks/deploy-report.md` |
| `SKIPPED` | Proceed |

---

## `--scope e2e`

Force end-to-end browser validation of user-facing acceptance criteria.

Unit tests prove functions work. E2E walkthroughs prove features work.

### Pre-Flight

1. Read the active spec from `specs/` and extract **user-facing ACs**
2. Verify the app is running locally (check dev server, start via `/start-qa` if not)
3. Verify the browser MCP is available (Playwright or Chrome)
4. Load authentication state as a real user would — cookie-based session, not injected tokens

### Walkthrough Protocol

For each user-facing AC:

1. **Describe the user journey** in plain language
2. **Execute each step in the real browser** via MCP tool calls: navigate, click, type, submit, wait
3. **Assert observable state**: URL, required text/elements, network status, no console errors
4. **Negative path check**: at least one failure variant per AC

### Evidence Format

Append to `tasks/e2e-log.md`:

```markdown
## E2E Walkthrough — <Feature Name> — <YYYY-MM-DD> <short-sha>

Spec: specs/<feature>.md
Commit: <full-sha>

### AC-1: <criterion text>
Journey: <plain-language steps>
Steps executed:
  ✓ Navigate /path → 200, element visible
  ✓ Fill form, submit → 302 redirect
  ✓ Assert session state
Negative: invalid input rejected with inline error ✓
Result: PASS
```

The log is **append-only**. Never overwrite prior walkthroughs — they form the audit trail.

### Failure Handling

- **Step fails**: STOP, report exact step + evidence, hand back to `/build` or `/debug`
- **MCP browser unavailable**: STOP. Do not fall back to curl or unit tests.
- **Auth fails twice**: STOP, report to user — this is usually a session misconfiguration
- **Dev server unreachable**: STOP, invoke `/start-qa`, then resume

### Iron Laws

1. A real browser must load the real app — no jsdom, no headless emulation bypassing the network
2. Authentication must go through the real login flow — no token injection
3. Every user-facing AC gets its own walkthrough entry — no batching
4. A failed step halts the walkthrough — do not cascade to the next AC
5. Evidence is the `tasks/e2e-log.md` entry — if the entry doesn't exist, the walkthrough didn't happen

---

## Integration

- **Default mode required by**: `/build` (after each task and in Phase 4), `/debug` (Phase 3), `/wrap-up-session` (Step 6)
- **`--scope e2e` invoked by**: `/build` Phase 4 (user-facing ACs), `/wrap-up-session` Step 6.3
- **`--scope deployment` invoked by**: `/wrap-up-session` Step 8
