# Task Plan

> Spec: specs/deployment-verification.md
> Branch: claude/add-deployment-logs-AXX8x
> Status: Pending user confirmation

---

## Task 1 — Define the adapter contract (`.claude/deployments/README.md`)

[x] TDD: README documents every required frontmatter field (`name`, `detect_files`, `status_source`, `auth_check_command`, `dashboard_url_template`), the two `status_source` values (`github-checks`, `cli`), conditional required fields per source, and the `common_failure_patterns` shape — verify by reading end-to-end against spec Design §2 -> Write `.claude/deployments/README.md` with the adapter contract, a worked example, and a "How to add a new service" section

## Task 2 — Ship the Railway starter runbook (`.claude/deployments/railway.md`)

[x] TDD: Runbook has valid YAML frontmatter with `status_source: github-checks`, `check_contexts` list, `auth_check_command: railway whoami`, `cli_status_command` and `log_fetch_command` as fallback, at least 3 `common_failure_patterns`, and a troubleshooting body — verify by reading against the contract from Task 1 -> Write `.claude/deployments/railway.md`

## Task 3 — Ship the Vercel starter runbook (`.claude/deployments/vercel.md`)

[x] TDD: Runbook has valid YAML frontmatter with `status_source: github-checks`, `check_contexts` for Vercel's preview and production deployments, `auth_check_command: vercel whoami`, `log_fetch_command` using `vercel inspect --logs`, at least 3 `common_failure_patterns`, and a troubleshooting body — verify by reading against the contract from Task 1 -> Write `.claude/deployments/vercel.md`

## Task 4 — Write `/verify-deployment` skill (`.claude/skills/verify-deployment/SKILL.md`)

[x] TDD: Skill file has YAML frontmatter (name, description, disable-model-invocation), steps covering (a) read CLAUDE.md targets section, (b) branch filter, (c) per-target auth check, (d) poll via GitHub Checks with CLI fallback, (e) fix-loop max 3 iterations with code-debugger delegation, (f) new-commit-per-iteration rule, (g) terminal-state escalation to `tasks/deploy-report.md`, (h) no hardcoded service names — verify against spec Design §3 end-to-end -> Create the directory and write `SKILL.md`

## Task 5 — Write `/setup-deployment` skill (`.claude/skills/setup-deployment/SKILL.md`)

[x] TDD: Skill file has YAML frontmatter and steps covering (a) scan for detect_files across all runbooks in `.claude/deployments/`, (b) interactive confirmation of detected services, (c) prompt for branch and project ID per service, (d) append or merge `## Deployment Targets` into `CLAUDE.md`, (e) copy missing runbooks from template, (f) add `tasks/deploy-state.json` to `.gitignore`, (g) final report — verify against spec Design §4 -> Create the directory and write `SKILL.md`

## Task 6 — Add Step 8 to `/wrap-up-session`

[x] TDD: `wrap-up-session/SKILL.md` has a new `## Step 8 — Deployment Verification` section between current Step 7 and the Done report; Step 8 invokes `/verify-deployment` only when `## Deployment Targets` exists in CLAUDE.md (strict-match regex), prints the nudge when signal files exist without the section, has a result table mapping each outcome to a Done/STOP action, supports `--skip-deploy` opt-out; Done banner gains a `- Deployments:` line with per-target status and attempt counts — verified by reading the modified file end-to-end against spec Design §5 -> Edit `.claude/skills/wrap-up-session/SKILL.md`

## Task 7 — Update `CLAUDE.md`

[x] TDD: `CLAUDE.md` has (a) `/setup-deployment` and `/verify-deployment` rows added to the Skills table, (b) Workflow "Wrap Up" bullet mentions Step 8 deployment verification, (c) an inactive Deployment Verification schema reference section near the end with table schema and config block, (d) the section heading is intentionally NOT the literal `## Deployment Targets` (verified by `grep -E '^## Deployment Targets[[:space:]]*$' CLAUDE.md` returning zero matches and the session-start hook running without nudge) — verified by reading the modified CLAUDE.md end-to-end and running the hook -> Edit `/home/user/coding-agent-workflow/CLAUDE.md`

## Task 8 — Add deploy-signal nudge to `session-start.sh`

[x] TDD: `.claude/hooks/session-start.sh` prints a single-line nudge when `CLAUDE.md` lacks a `## Deployment Targets` section AND any known deploy signal file exists (railway.json, railway.toml, vercel.json, .vercel/, netlify.toml, fly.toml, render.yaml); nudge is suppressed when `.claude/deploy-nudge-dismissed` exists; nudge is non-blocking (hook still exits 0) — verify by reading the hook script -> Edit `.claude/hooks/session-start.sh`

## Task 9 — Add `tasks/deploy-state.json` to `.gitignore`

[x] TDD: `.gitignore` contains `tasks/deploy-state.json` (check it's not already ignored by a broader pattern) — verify by reading the file -> Edit `.gitignore`

## Task 10 — End-to-end consistency review

[x] TDD: Walked spec acceptance criteria (all 18 satisfied), confirmed `/verify-deployment` and `/wrap-up-session` contain zero "railway"/"vercel" mentions (genericized 3 prose mentions in verify-deployment + 1 in wrap-up-session line 393), confirmed terminology consistency (target, runbook, iteration, check run all consistent; fix-loop/fix loop is acceptable English compound noun variation), confirmed Done banner format matches between spec and wrap-up-session — fixes applied: section heading collision in CLAUDE.md (used `## Deployment Verification — Schema Reference (Inactive Example)` heading, indented code block instead of fenced), strict-match grep in session-start.sh and verify-deployment skill instructions. Build verified by running session-start.sh hook (no nudge printed) and `grep -E '^## Deployment Targets[[:space:]]*$' CLAUDE.md` (zero matches)

---

## Build Status

**All 10 tasks complete.** Implementation matches spec. Ready for user review or `/wrap-up-session`.
