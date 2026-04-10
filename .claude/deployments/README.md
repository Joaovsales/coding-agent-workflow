# Deployment Adapters

> Adapter contract for `/verify-deployment`. Each file in this directory describes one deployment service. Adding a new service = drop in a new `<service>.md` file. No changes to skills or hooks required.

This directory is read by:

- **`/verify-deployment`** — loads the runbook for each row in `CLAUDE.md` § Deployment Targets, validates frontmatter against this contract, then drives the wait/log/fix loop.
- **`/setup-deployment`** — scans every runbook's `detect_files` to figure out which services this project uses, then writes the routing table into `CLAUDE.md`.
- **`.claude/hooks/session-start.sh`** — uses `detect_files` to print a one-line nudge when signal files exist but no Deployment Targets section is configured.

The frontmatter is the **machine-readable contract**. The body is **human-readable troubleshooting notes** that get fed to the `code-debugger` agent on failure.

---

## Frontmatter Contract

### Required fields (always)

| Field | Type | Description |
|---|---|---|
| `name` | string | Lowercase identifier. Must match the filename (`railway.md` → `name: railway`). Used internally as a stable key. |
| `display_name` | string | Human-readable name for reports and the Done banner (e.g. `Railway`, `Vercel`, `Fly.io`). |
| `detect_files` | list[string] | Files or directories at the project root whose presence signals this service is in use. Any single match is sufficient. Trailing `/` indicates a directory. |
| `status_source` | enum | Either `github-checks` or `cli`. Determines how `/verify-deployment` polls for build status. |
| `auth_check_command` | string | A shell command that exits 0 when credentials are present and valid. Run **once before polling** so we fail fast instead of waiting on a build we can't read. |
| `dashboard_url_template` | string | URL template for the service's dashboard. Supports `{project_id}` interpolation from the CLAUDE.md table. Used in escalation messages and the deploy report. |
| `default_timeout_minutes` | integer | Maximum wait time per build attempt before declaring TIMEOUT. Overridable from `CLAUDE.md` config block. |

### Required when `status_source: github-checks`

| Field | Type | Description |
|---|---|---|
| `check_contexts` | list[string] | GitHub check run names this service publishes against the commit SHA. `/verify-deployment` matches against this list when calling `mcp__github__get_commit`. **All** matching contexts must resolve to success. |

### Required when `status_source: cli`

| Field | Type | Description |
|---|---|---|
| `cli_status_command` | string | Shell command that returns the latest deployment status for the current commit SHA. Should be JSON-friendly when possible — `/verify-deployment` parses `state` / `status` fields. |

### Optional (always)

| Field | Type | Description |
|---|---|---|
| `log_fetch_command` | string | Shell command template that fetches build logs. Supports `{deployment_id}` interpolation. Used as a fallback for `github-checks` mode when the check run details URL doesn't expose full logs, and as the primary log source for `cli` mode. |
| `common_failure_patterns` | list[object] | Substring patterns paired with hints. When a pattern matches the fetched logs, the hint is added to the `code-debugger` agent's context. See format below. |

### `common_failure_patterns` format

```yaml
common_failure_patterns:
  - match: "npm ERR! peer dep"
    hint: "Peer dependency mismatch — check package.json versions"
  - match: "Nixpacks build failed"
    hint: "Check the buildCommand field in railway.json"
```

- `match` is a literal substring (not a regex). Case-sensitive.
- `hint` is a one-line actionable suggestion that becomes part of the debugger's context window.
- Multiple patterns can match the same log; all matching hints are passed through.
- Optional. Omit the field entirely if you have no curated failure modes for this service.

---

## Contract Validation

`/verify-deployment` validates each runbook on read. A runbook is **invalid** if:

- Any required field is missing
- `status_source` is neither `github-checks` nor `cli`
- `status_source: github-checks` and `check_contexts` is missing or empty
- `status_source: cli` and `cli_status_command` is missing
- `name` does not match the filename stem (`railway.md` → `name: railway`)
- `common_failure_patterns` is present but any entry lacks both `match` and `hint`

**On invalid runbook**: `/verify-deployment` skips that target with a clear report (e.g. `"railway: malformed runbook — missing required field 'check_contexts'"`) and continues with other targets. **Never crashes the whole verification.**

---

## Worked Example

```yaml
---
name: railway
display_name: Railway
detect_files:
  - railway.json
  - railway.toml
  - .railway/
status_source: github-checks
check_contexts:
  - Railway
  - railway/deployment
auth_check_command: railway whoami
log_fetch_command: railway logs --deployment {deployment_id}
dashboard_url_template: https://railway.app/project/{project_id}
default_timeout_minutes: 15
common_failure_patterns:
  - match: "npm ERR! peer dep"
    hint: "Peer dependency mismatch — check package.json versions"
  - match: "Nixpacks build failed"
    hint: "Check the buildCommand field in railway.json"
  - match: "ECONNREFUSED"
    hint: "Service tried to connect during build — check for top-level await on a network resource"
---

# Railway Deployment Runbook

## Manual troubleshooting

When the agent gives up after 3 iterations, check the dashboard for:

1. **Environment variables** — missing or stale env vars are not visible in build logs but break runtime
2. **Service dependencies** — Railway only rebuilds the service whose code changed; check sibling services
3. **Build vs deploy logs** — compilation can pass and the container still fail to start
```

---

## How to Add a New Service

1. **Create `.claude/deployments/<service>.md`** with the frontmatter contract above
2. **Pick a `status_source`**:
   - **`github-checks`** if the service publishes commit check runs to GitHub (Railway, Vercel, Netlify, Render — most modern PaaS). This is the preferred path: it requires no extra auth beyond the existing GitHub MCP and works for any check-publishing service.
   - **`cli`** if the service has a CLI that can report deployment status by commit SHA but doesn't integrate with GitHub Checks (Fly.io's standard flow, self-hosted services, internal platforms).
3. **Discover the GitHub check context names** by running a deploy and inspecting the commit on github.com — the check names you see there go into `check_contexts`.
4. **Write the `auth_check_command`** to exit 0 only when credentials are present (e.g. `railway whoami`, `vercel whoami`, `flyctl auth whoami`). This runs before polling so we fail fast.
5. **Add 2–4 `common_failure_patterns`** for the most frequent build failures you've personally hit on this service. These compound across teams that `/sync` from this template — better hints lead to faster fix loops.
6. **Write a `## Manual troubleshooting` body** with the things the agent can't auto-diagnose: env var issues, quota limits, dashboard-only settings.
7. **Test the runbook** by adding a row to your project's `CLAUDE.md` § Deployment Targets that points at it, then run `/verify-deployment` after a known-good push.
8. **Open a PR back to the template** — once your runbook works for your project, others using `/sync` will benefit.

---

## Contract Stability

The frontmatter schema is the contract between runbooks and `/verify-deployment`. Adding new optional fields is non-breaking. Renaming or removing fields is breaking and requires updating every runbook in this directory plus the validation logic in `/verify-deployment`.

If you need a field that doesn't exist yet, add it as **optional** first, ship runbooks that use it, then promote it to required only when every starter runbook in this directory has been updated.
