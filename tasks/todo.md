# Task Plan

> Spec: specs/deployment-verification.md
> Branch: claude/add-deployment-logs-AXX8x
> Status: Pending user confirmation

---

## Task 1 — Define the adapter contract (`.claude/deployments/README.md`)

[ ] TDD: README documents every required frontmatter field (`name`, `detect_files`, `status_source`, `auth_check_command`, `dashboard_url_template`), the two `status_source` values (`github-checks`, `cli`), conditional required fields per source, and the `common_failure_patterns` shape — verify by reading end-to-end against spec Design §2 -> Write `.claude/deployments/README.md` with the adapter contract, a worked example, and a "How to add a new service" section

## Task 2 — Ship the Railway starter runbook (`.claude/deployments/railway.md`)

[ ] TDD: Runbook has valid YAML frontmatter with `status_source: github-checks`, `check_contexts` list, `auth_check_command: railway whoami`, `cli_status_command` and `log_fetch_command` as fallback, at least 3 `common_failure_patterns`, and a troubleshooting body — verify by reading against the contract from Task 1 -> Write `.claude/deployments/railway.md`

## Task 3 — Ship the Vercel starter runbook (`.claude/deployments/vercel.md`)

[ ] TDD: Runbook has valid YAML frontmatter with `status_source: github-checks`, `check_contexts` for Vercel's preview and production deployments, `auth_check_command: vercel whoami`, `log_fetch_command` using `vercel inspect --logs`, at least 3 `common_failure_patterns`, and a troubleshooting body — verify by reading against the contract from Task 1 -> Write `.claude/deployments/vercel.md`

## Task 4 — Write `/verify-deployment` skill (`.claude/skills/verify-deployment/SKILL.md`)

[ ] TDD: Skill file has YAML frontmatter (name, description, disable-model-invocation), steps covering (a) read CLAUDE.md targets section, (b) branch filter, (c) per-target auth check, (d) poll via GitHub Checks with CLI fallback, (e) fix-loop max 3 iterations with code-debugger delegation, (f) new-commit-per-iteration rule, (g) terminal-state escalation to `tasks/deploy-report.md`, (h) no hardcoded service names — verify against spec Design §3 end-to-end -> Create the directory and write `SKILL.md`

## Task 5 — Write `/setup-deployment` skill (`.claude/skills/setup-deployment/SKILL.md`)

[ ] TDD: Skill file has YAML frontmatter and steps covering (a) scan for detect_files across all runbooks in `.claude/deployments/`, (b) interactive confirmation of detected services, (c) prompt for branch and project ID per service, (d) append or merge `## Deployment Targets` into `CLAUDE.md`, (e) copy missing runbooks from template, (f) add `tasks/deploy-state.json` to `.gitignore`, (g) final report — verify against spec Design §4 -> Create the directory and write `SKILL.md`

## Task 6 — Add Step 8 to `/wrap-up-session`

[ ] TDD: `wrap-up-session/SKILL.md` has a new `## Step 8 — Deployment Verification` section between current Step 7 and the Done report; Step 8 invokes `/verify-deployment` only when `## Deployment Targets` exists in CLAUDE.md, prints the nudge when signal files exist without the section, has a result table mapping each outcome to a Done/STOP action, supports `--skip-deploy` opt-out; Done banner gains a `- Deployments:` line with per-target status and attempt counts — verify by reading the modified file end-to-end against spec Design §5 -> Edit `.claude/skills/wrap-up-session/SKILL.md`

## Task 7 — Update `CLAUDE.md`

[ ] TDD: `CLAUDE.md` has (a) `/setup-deployment` and `/verify-deployment` rows added to the Skills table, (b) Workflow "Wrap Up" bullet mentions Step 8 deployment verification, (c) a new `## Deployment Targets` section template near the end with the table schema and config block from spec Design §1, (d) the section template is clearly marked as "example / populate via /setup-deployment" so it does NOT activate verification for the template repo itself — verify by reading the modified CLAUDE.md end-to-end -> Edit `/home/user/coding-agent-workflow/CLAUDE.md`

## Task 8 — Add deploy-signal nudge to `session-start.sh`

[ ] TDD: `.claude/hooks/session-start.sh` prints a single-line nudge when `CLAUDE.md` lacks a `## Deployment Targets` section AND any known deploy signal file exists (railway.json, railway.toml, vercel.json, .vercel/, netlify.toml, fly.toml, render.yaml); nudge is suppressed when `.claude/deploy-nudge-dismissed` exists; nudge is non-blocking (hook still exits 0) — verify by reading the hook script -> Edit `.claude/hooks/session-start.sh`

## Task 9 — Add `tasks/deploy-state.json` to `.gitignore`

[ ] TDD: `.gitignore` contains `tasks/deploy-state.json` (check it's not already ignored by a broader pattern) — verify by reading the file -> Edit `.gitignore`

## Task 10 — End-to-end consistency review

[ ] TDD: Walk the spec's acceptance criteria list and confirm each is satisfied across all changed files; confirm no file contains a hardcoded "railway" or "vercel" branching statement in logic (only as data in runbook filenames); confirm terminology is consistent (`target`, `runbook`, `iteration`, `fix-loop`, `check run`) across README, skills, and wrap-up; confirm the Done banner format is identical in spec and in wrap-up-session — verify by reading all modified files -> Fix any drift found
