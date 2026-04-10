# Spec: Deployment Verification

## Problem

`/wrap-up-session` declares "session wrapped up" after `git push`, but the work isn't actually done — Railway, Vercel, and similar PaaS providers then run their own builds in the cloud. If that build fails, the user discovers it later, out-of-band, with no loop back into the coding workflow. There is no mechanism in the current template to:

1. Know which deployment services a project uses
2. Wait for the post-push build
3. Fetch build logs on failure
4. Iterate a fix loop until the build succeeds

The routing must not hardcode service names — adding Fly.io, Render, or Netlify later should be a drop-in change, not a rewrite.

## Behavior

Introduce a **Deployment Verification** layer with four mechanisms:

1. **Declarative routing in `CLAUDE.md`** — a `## Deployment Targets` section lists which services this project uses, which branches trigger each, and points to per-service runbook files. This is the project-level source of truth.
2. **Adapter runbooks in `.claude/deployments/<service>.md`** — each deployment service is a self-contained markdown file with YAML frontmatter declaring detection files, status source, auth check, log fetch, and common failure hints. Adding a new service = drop in a new file.
3. **New skill `/verify-deployment`** — reads the CLAUDE.md routing table, filters by current branch, waits for each applicable service's build to resolve (primary source: GitHub Checks API via GitHub MCP; fallback: per-service CLI when the runbook declares it), fetches logs on failure, delegates fixes to the `code-debugger` agent, commits each fix as a new commit, and loops up to 3 iterations before escalating.
4. **New skill `/setup-deployment`** — one-time interactive bootstrap that scans the project for deployment signal files, asks the user to confirm detected services and project IDs, writes the `## Deployment Targets` section into `CLAUDE.md`, and copies starter runbook files from the template.

`/wrap-up-session` grows a new **Step 8: Deployment Verification** that invokes `/verify-deployment` after the push succeeds. `/build` is unchanged — it does not push, so deployment is strictly a wrap-up concern.

## Design

### 1. `CLAUDE.md` — `## Deployment Targets` section

Added as an optional section near the end of `CLAUDE.md`. When absent, `/verify-deployment` is a no-op (with a nudge if signal files exist). When present:

```markdown
## Deployment Targets

> Populated by `/setup-deployment`. Read by `/verify-deployment`.
> Delete this section to disable deployment verification for this project.

| Service | Runbook                          | Triggers on branch | Project ID    |
|---------|----------------------------------|--------------------|---------------|
| Railway | .claude/deployments/railway.md   | main               | my-api-prod   |
| Vercel  | .claude/deployments/vercel.md    | main               | my-frontend   |

**Config:**
- Max fix iterations: 3
- Build timeout: 15m
- Preferred status source: github-checks
```

Rules:
- A target row whose `Triggers on branch` does not match the current branch is skipped silently.
- `Project ID` is free-form — its only consumer is the runbook's `dashboard_url_template`.
- Config values at the bottom override runbook defaults.

### 2. Runbook schema — `.claude/deployments/<service>.md`

Every runbook is a markdown file with YAML frontmatter. The frontmatter is the machine-readable contract; the body is human-readable troubleshooting notes.

```yaml
---
name: railway                                    # lowercase identifier
display_name: Railway                            # for reports
detect_files:                                    # any match = this service is present
  - railway.json
  - railway.toml
  - .railway/
status_source: github-checks                     # or: cli
check_contexts:                                  # GitHub check run names (status_source=github-checks)
  - Railway
  - railway/deployment
auth_check_command: railway whoami               # must exit 0 before wait begins
cli_status_command: railway status --json        # used only if status_source=cli
log_fetch_command: railway logs --deployment {deployment_id}
dashboard_url_template: https://railway.app/project/{project_id}
default_timeout_minutes: 15
common_failure_patterns:
  - match: "npm ERR! peer dep"
    hint: "Peer dependency mismatch — check package.json"
  - match: "Nixpacks build failed"
    hint: "Check buildCommand in railway.json"
---

# Railway Deployment Runbook

## Manual troubleshooting
...
```

**Contract rules** (enforced by `/verify-deployment` on read):
- `name`, `detect_files`, `status_source`, `auth_check_command`, `dashboard_url_template` are required
- If `status_source: github-checks` → `check_contexts` is required
- If `status_source: cli` → `cli_status_command` is required
- `common_failure_patterns` is optional; when present, matches add hints to the debugger's context

### 3. `/verify-deployment` skill

**Inputs**: current commit SHA (`git rev-parse HEAD`), current branch (`git rev-parse --abbrev-ref HEAD`), CLAUDE.md contents, `.claude/deployments/*.md` runbooks.

**Flow**:

```
1. Read CLAUDE.md, locate "## Deployment Targets" section.
   - If missing:
       - Scan project root for any detect_files from runbooks in .claude/deployments/
       - If signals found: print nudge "Deploy signals found (railway.json). Run /setup-deployment to enable."
       - Exit 0 (nothing to verify).
   - If present: parse the target table.

2. Resolve current commit SHA and branch.

3. Filter targets: keep rows where the current branch matches "Triggers on branch".
   - Empty set: report "No deployment targets trigger on branch <X>". Exit 0.

4. For each applicable target:
   a. Load its runbook. Validate frontmatter against the contract.
   b. Run auth_check_command. Non-zero exit:
        → STOP this target, report "<service>: auth check failed — run <command> manually".
        → Do not count as a fix iteration.
   c. Poll for build status:
        - github-checks path: call mcp__github__get_commit for the SHA, filter check runs by check_contexts names
        - cli path: run cli_status_command, parse output per runbook
        - Poll intervals: 15s for first 2min, then 30s. Cap at default_timeout_minutes (or CLAUDE.md config override).
   d. Resolve status:
        - pending / in_progress / queued → keep waiting
        - success → record ✓ and move to next target
        - failure → enter fix-loop (step e)
        - cancelled → STOP this target, ask user "Build was cancelled — deploy intentionally? (y/n)"
        - timeout (no resolution within window) → STOP this target, escalate with dashboard URL
   e. Fix-loop (max 3 iterations; counter persisted in tasks/deploy-state.json per-service):
        i.   Fetch logs:
                - github-checks: extract the check run's details_url, fetch via webfetch or fallback to runbook's log_fetch_command if set
                - cli: run log_fetch_command with deployment_id from the status response
        ii.  Scan logs against runbook.common_failure_patterns — collect matching hints.
        iii. Delegate to code-debugger agent (model: sonnet) with:
                - Full logs (or tail if > 500 lines)
                - Matched hints
                - Runbook body (troubleshooting section)
                - Current commit SHA
                - git diff origin/main...HEAD for context
        iv.  Code-debugger applies the fix and runs the local test suite (existing debug flow).
        v.   Commit as a NEW commit (never amend): "fix(deploy): <one-line summary> [deploy-retry N/3]"
        vi.  Push (reuses wrap-up-session's push failure handling: retry on network, pull --rebase on non-FF).
        vii. Restart step c (wait for new SHA) with incremented iteration counter.
   f. After 3 failed iterations: STOP this target.
        - Write tasks/deploy-report.md with: iteration history, final logs, matched hints, dashboard URL, suggested manual remediation steps (env vars, quotas, infra).
        - Flag the session as "deployment failed".

5. Report per-target status and overall outcome.
```

**Output states** (per target): `SUCCESS`, `AUTH_FAILED`, `TIMEOUT`, `CANCELLED`, `FAILED_MAX_ITERATIONS`.

**State file**: `tasks/deploy-state.json` — tracks `{ service, iteration, last_sha, started_at }` per active verification. Cleaned up on terminal state. Not committed (added to `.gitignore` via a note in setup-deployment).

### 4. `/setup-deployment` skill

**Flow**:

```
1. Scan project root for detect_files across all runbooks in .claude/deployments/
   (e.g., vercel.json, railway.json, netlify.toml, fly.toml, render.yaml).
2. Present detected services to user:
     "I detected: Railway (railway.json), Vercel (vercel.json). Confirm? (y/n)"
3. For each confirmed service:
     - Ask: "Which branch triggers <service>? [default: main]"
     - Ask: "Project ID for <service>? (used for dashboard links)"
4. If CLAUDE.md has no "## Deployment Targets" section, append it.
   If it has one, offer to replace or merge.
5. For each confirmed service, ensure .claude/deployments/<service>.md exists.
   If missing (new project using /sync), copy from template.
6. Ensure tasks/deploy-state.json is in .gitignore.
7. Report: "Deployment verification configured for: Railway, Vercel. Run /verify-deployment after a push to test."
```

### 5. `/wrap-up-session` — new Step 8

Inserted between the current Step 7 (Commit & Push) and the "Done" report. Invoked only if Step 7 completed with a successful push.

```markdown
## Step 8 — Deployment Verification

If `CLAUDE.md` contains a `## Deployment Targets` section, invoke `/verify-deployment`.

Otherwise:
- Scan project root for deployment signal files (railway.json, vercel.json, etc.)
- If found: print a one-line nudge recommending /setup-deployment, but do not block
- If not found: skip silently

Outcomes from /verify-deployment:
| Result | Action |
|--------|--------|
| All targets SUCCESS | Proceed to Done |
| Any AUTH_FAILED | STOP — user must fix credentials; do not claim success |
| Any TIMEOUT | STOP — report with dashboard URL; ask user "Check deployment manually? (y/n)" |
| Any FAILED_MAX_ITERATIONS | STOP — point to tasks/deploy-report.md; do NOT claim session success |
| Skipped (no targets for branch) | Proceed to Done |

Opt-out: `/wrap-up-session --skip-deploy` bypasses Step 8 entirely (for WIP pushes).
```

Session summary gains a new line:

```
- Deployments: [Railway ✓ (1 attempt), Vercel ✓ (2 attempts)]
```

or on failure:

```
- Deployments: [Railway ✗ FAILED after 3 attempts — see tasks/deploy-report.md, Vercel ✓]
```

### 6. `session-start.sh` nudge

If `CLAUDE.md` has no `## Deployment Targets` section but the project root contains any deployment signal file, print one line at session start:

```
⚠  Deploy signals detected (railway.json) but no Deployment Targets in CLAUDE.md.
   Run /setup-deployment to enable automatic build verification.
```

Non-blocking. Suppressed if a `.claude/deploy-nudge-dismissed` marker file exists.

### 7. Starter runbooks shipped with the template

- `.claude/deployments/railway.md` — status_source: github-checks (Railway publishes check runs), CLI fallback via `railway status`
- `.claude/deployments/vercel.md` — status_source: github-checks (Vercel publishes check runs), CLI fallback via `vercel inspect`
- `.claude/deployments/README.md` — adapter contract documentation for authors adding new services

## Files Involved

- `CLAUDE.md` — add `## Deployment Targets` section template near the end; add `/setup-deployment` and `/verify-deployment` rows to the Skills table; update Workflow section to mention Step 8
- `.claude/skills/verify-deployment/SKILL.md` — NEW
- `.claude/skills/setup-deployment/SKILL.md` — NEW
- `.claude/skills/wrap-up-session/SKILL.md` — insert Step 8; update session summary format in the Done banner
- `.claude/deployments/README.md` — NEW (adapter contract)
- `.claude/deployments/railway.md` — NEW starter runbook
- `.claude/deployments/vercel.md` — NEW starter runbook
- `.claude/hooks/session-start.sh` — add deploy-signal nudge
- `.gitignore` — add `tasks/deploy-state.json`

## Edge Cases

- **No `## Deployment Targets` and no signal files** — `/verify-deployment` exits silently; wrap-up proceeds normally
- **Signal files present but no section** — nudge printed once per session (wrap-up and session-start); never blocking
- **Current branch doesn't match any target's trigger** — explicit skip message, exit clean
- **Auth check fails** — fail fast before any polling; counts as escalation, not a retry
- **Transient GitHub Checks API error** — retry the poll (network-level retry), not a fix iteration
- **Build takes longer than timeout** — escalate with dashboard URL; user decides whether to wait longer manually
- **Build succeeds on first try** — no fix loop; record and continue
- **Code-debugger produces no diff** (can't fix it) — count as failed iteration, log reason, keep iterating until counter hits 3
- **Fix iteration pushes a commit but the new build also fails on the same error** — iteration counter still advances; the hint set grows across iterations
- **User force-pushes or amends during a fix loop** — next poll sees new SHA, abort state, warn user: "Commit SHA changed during deployment verification — aborting loop"
- **Multiple check runs per service** (Vercel sometimes publishes more than one) — wait for all matching contexts to resolve; fail if any fails
- **`/verify-deployment` invoked with uncommitted changes** — reject: "Uncommitted changes present. Commit before running /verify-deployment."
- **Runbook frontmatter is malformed** — skip that target, report "<service>: malformed runbook", do not crash the whole verification
- **`tasks/deploy-state.json` stale from a previous session** — ignored; state is scoped by commit SHA
- **Project doesn't use GitHub** (local git only) — no check runs to poll; runbook must declare `status_source: cli` or verification is a no-op

## Acceptance Criteria

- [ ] `/verify-deployment` skill exists at `.claude/skills/verify-deployment/SKILL.md` with frontmatter and the flow described in Design §3
- [ ] `/setup-deployment` skill exists at `.claude/skills/setup-deployment/SKILL.md` with the interactive bootstrap in Design §4
- [ ] `.claude/deployments/README.md` documents the runbook frontmatter contract (required fields, status_source branches, common_failure_patterns format)
- [ ] `.claude/deployments/railway.md` exists with valid frontmatter matching the contract
- [ ] `.claude/deployments/vercel.md` exists with valid frontmatter matching the contract
- [ ] `.claude/skills/wrap-up-session/SKILL.md` has a new Step 8 between current Step 7 and the Done report
- [ ] Step 8 invokes `/verify-deployment` only when `## Deployment Targets` exists in `CLAUDE.md`
- [ ] The Done banner format includes a `- Deployments:` line showing per-target status and attempt counts
- [ ] `CLAUDE.md` has a `## Deployment Targets` section template (placeholder, not activated for this repo itself) and skill table entries for both new skills
- [ ] `CLAUDE.md` Workflow section mentions Step 8 in the Wrap Up description
- [ ] `.claude/hooks/session-start.sh` prints a deploy-signal nudge when applicable
- [ ] `.gitignore` contains `tasks/deploy-state.json`
- [ ] Fix loop is capped at 3 iterations with clear escalation when exhausted
- [ ] Each fix iteration produces a NEW commit (never amend) with a message of the form `fix(deploy): ... [deploy-retry N/3]`
- [ ] Auth check failure does not consume a fix-iteration slot
- [ ] Runbook contract validation: missing required fields causes that target to be skipped with a report, not a crash
- [ ] Opt-out `--skip-deploy` flag bypasses Step 8
- [ ] No hardcoded "railway" or "vercel" string anywhere in `/verify-deployment` or `/wrap-up-session` — all service behavior flows from runbook frontmatter
