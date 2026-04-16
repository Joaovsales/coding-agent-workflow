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

---

## Plan: Workflow Insights Improvements
> Spec: specs/workflow-insights-improvements.md
> Branch: claude/analyze-session-insights-LGeul
> Status: Pending user confirmation

### Task 1 — Create `/verify-e2e` skill (AC-1)

[x] VERIFY: `ls .claude/skills/verify-e2e/SKILL.md` exits 0 AND `head -5` shows YAML frontmatter with `name: verify-e2e` -> Create directory `.claude/skills/verify-e2e/` and write `SKILL.md` with sections: frontmatter, When to Invoke, Pre-Flight, Walkthrough Protocol, Evidence Format (writes `tasks/e2e-log.md`), Failure Handling, Iron Laws, Integration

[x] VERIFY: `grep -E "(token injection|simulated DOM|batching)" .claude/skills/verify-e2e/SKILL.md` returns 3+ matches across Iron Laws -> Ensure Iron Laws section explicitly forbids each

[x] VERIFY: `grep -E "verify-e2e" CLAUDE.md` returns a row in the Skills table -> Add `/verify-e2e` row to CLAUDE.md Skills table

### Task 2 — `/plan` spec-persistence hard gate (AC-2)

[x] VERIFY: `grep -F "MUST persist to disk" .claude/skills/plan/SKILL.md` returns 1 match in Step 2 -> Rewrite Step 2 with the hard echo-or-fail pattern

[x] VERIFY: `grep -E "^✓ Spec written:" .claude/skills/plan/SKILL.md` AND `grep -E "Forbidden:" .claude/skills/plan/SKILL.md` both return matches -> Include the required output format and forbidden-actions block

[x] VERIFY: `grep -F "MUST persist" .claude/skills/plan/SKILL.md` returns matches in BOTH Step 2 and Step 3 -> Apply same echo-or-fail pattern to Step 3 for `tasks/todo.md`

### Task 3 — `/build` Phase 4 AC classification + e2e routing (AC-3)

[x] VERIFY: `grep -E "logic.*integration.*user-facing|user-facing.*logic" .claude/skills/build/SKILL.md` returns matches in BOTH Pre-Flight and Phase 4 -> Add new Pre-Flight Check step "Classify acceptance criteria"; modify Phase 4 to add classification table

[x] VERIFY: `grep -F "/verify-e2e" .claude/skills/build/SKILL.md` returns at least 1 match in Phase 4 -> Phase 4 invokes `/verify-e2e` when any AC is `user-facing`

[x] VERIFY: `grep -F "✅✅" .claude/skills/build/SKILL.md` returns at least 1 match -> Add the `✅✅` status mark for e2e-walkthrough-verified ACs

### Task 4 — `/wrap-up-session` duplicate sweep + Step 6.3 (AC-4)

[x] VERIFY: `grep -F "Duplicate Plan Block Detection" .claude/skills/wrap-up-session/SKILL.md` returns 1 match in Step 2 -> Add the subsection covering duplicate headings, orphan subtasks, stale plan blocks

[x] VERIFY: `grep -E "^## Step 6.3" .claude/skills/wrap-up-session/SKILL.md` returns 1 match -> Insert new Step 6.3 "E2E Coverage Gate" between Step 6 and Step 6.5

[x] VERIFY: `grep -F "tasks/e2e-log.md" .claude/skills/wrap-up-session/SKILL.md` returns matches in Step 6.3 -> Step 6.3 references the e2e log as evidence source

[x] VERIFY: `grep -E "e2e|E2E" .claude/skills/wrap-up-session/SKILL.md | grep -i "done\|banner\|coverage"` shows banner mention -> Update Done banner to include e2e coverage status

### Task 5 — `CLAUDE.md` ladder + observability + quality gate + wrap-up (AC-5)

[x] VERIFY: `grep -E "^## Tool Preference Ladder" CLAUDE.md` returns 1 match AND `grep -F "fails auth twice" CLAUDE.md` returns 1 match -> Insert `## Tool Preference Ladder` section after Core Principles with table covering Supabase/Vercel/GitHub/Library Docs/Browser E2E and the password-twice-stop rule

[x] VERIFY: `grep -E "^## Observability Discipline" CLAUDE.md` returns 1 match AND `grep -F "failure-only reporting" CLAUDE.md` returns 1 match -> Insert `## Observability Discipline` section with the failure-only rule

[x] VERIFY: `grep -F "user-facing acceptance criterion" CLAUDE.md` returns 1 match in `## Quality Gate` -> Add e2e walkthrough row to Quality Gate checklist

[x] VERIFY: `grep -B2 -A5 "### 4. Wrap Up" CLAUDE.md | grep -F "/verify-e2e"` returns 1 match -> Amend Wrap Up section to mention `/verify-e2e` precondition

### Task 6 — `/sync` legacy `.claude/commands/` migration (AC-6)

[x] VERIFY: `grep -F "Legacy Directory Migration" .claude/skills/sync/SKILL.md` returns 1 match -> Insert new step before "Show What Changed" titled "Legacy Directory Migration"

[x] VERIFY: `grep -E "archive|delete|skip" .claude/skills/sync/SKILL.md | wc -l` shows the three options documented -> Step prompts user with archive/delete/skip options when `.claude/commands/` exists

[x] VERIFY: `grep -F "overlapping basenames" .claude/skills/sync/SKILL.md` returns 1 match -> Step surfaces conflict list when both dirs contain overlapping entries; refuses auto-resolve

[x] VERIFY: `grep -F "silent no-op" .claude/skills/sync/SKILL.md` returns 1 match in the legacy migration step -> Step is silent no-op when `.claude/commands/` is absent

### Task 7 — Cross-cutting integrity (AC-7)

[x] VERIFY: `git diff --name-only main...HEAD` lists exactly: `.claude/skills/verify-e2e/SKILL.md`, `.claude/skills/plan/SKILL.md`, `.claude/skills/build/SKILL.md`, `.claude/skills/wrap-up-session/SKILL.md`, `.claude/skills/sync/SKILL.md`, `CLAUDE.md`, `specs/workflow-insights-improvements.md`, `tasks/todo.md` -> Confirm scope did not leak into other files

[x] VERIFY: For each modified SKILL.md, `head -6` shows valid frontmatter (`---` open, `name:`, `description:`, `disable-model-invocation:`, `---` close) -> Spot-check each file's frontmatter integrity

[x] VERIFY: `grep -F "/verify-e2e" .claude/skills/build/SKILL.md .claude/skills/wrap-up-session/SKILL.md CLAUDE.md` returns matches in all three AND the skill name in `verify-e2e/SKILL.md` frontmatter matches exactly -> Cross-references resolve consistently

---

## Plan: Trim Session-Start Token Footprint
> Spec: specs/trim-session-start-tokens.md
> Branch: claude/analyze-token-usage-LS6wm
> Status: Pending user confirmation

### Task 1 — Capture pre-change baselines (for AC-8 measurement)

[ ] VERIFY: `wc -c CLAUDE.md` returns 14254 AND `bash .claude/hooks/session-start.sh 2>/dev/null | wc -c` returns 2802 -> Record both numbers in this todo block as "Baseline: CLAUDE.md=14254, hook-output=2802" before any edit

### Task 2 — Append moved schema to `.claude/deployments/README.md` (AC-3)

[ ] VERIFY: `grep -c "Schema Reference for Downstream Projects" .claude/deployments/README.md` returns 0 BEFORE the edit (no collision) AND returns 1 AFTER -> Append a new section `## CLAUDE.md Deployment Targets — Schema Reference for Downstream Projects` to the end of the file, containing the exact preamble warning, indented code block schema example, schema rules, and config block currently at the bottom of CLAUDE.md

[ ] VERIFY: `grep -F "Triggers on branch" .claude/deployments/README.md` AND `grep -F "Max fix iterations" .claude/deployments/README.md` AND `grep -F "Preferred status source" .claude/deployments/README.md` all return ≥1 match -> Confirm the moved schema reference includes the indented table example and the config block

### Task 3 — Replace the inactive section in `CLAUDE.md` (AC-1, AC-2, AC-4)

[ ] VERIFY: `grep -F "Deployment Verification — Schema Reference (Inactive Example)" CLAUDE.md` returns 0 matches -> Delete the entire `## Deployment Verification — Schema Reference (Inactive Example)` section (heading + body, from the heading line through end of file)

[ ] VERIFY: `grep -F ".claude/deployments/README.md" CLAUDE.md` returns ≥1 match AND that match is in a section also mentioning `/setup-deployment` -> Replace the deleted section with a 2-line pointer:
  ```
  ## Deployment Verification

  This template repo has no active deployment targets. Downstream projects: run `/setup-deployment` to populate a `## Deployment Targets` section here. Schema reference: `.claude/deployments/README.md`.
  ```

[ ] VERIFY: `grep -E '^## Deployment Targets[[:space:]]*$' CLAUDE.md` returns exit code 1 (no matches) -> Confirm the new heading does NOT match the strict regex used by `/verify-deployment` and the session-start nudge logic

### Task 4 — Replace `SKILLS AVAILABLE` block in `session-start.sh` with starter trio (AC-5, AC-6)

[ ] VERIFY: `bash .claude/hooks/session-start.sh 2>/dev/null | awk '/^SKILLS AVAILABLE/,/^═/' | grep -c "^  /"` returns exactly 3 -> Replace lines 151–169 of `.claude/hooks/session-start.sh` so the SKILLS AVAILABLE section prints exactly: header, divider, three lines (`/plan`, `/build`, `/wrap-up-session`), then `(type / to see all skills)`, then a blank line

[ ] VERIFY: `bash .claude/hooks/session-start.sh; echo "exit=$?"` ends with `exit=0` -> Confirm the hook script still exits cleanly after the edit

[ ] VERIFY: `bash .claude/hooks/session-start.sh 2>/dev/null | grep -F "(type / to see all skills)"` returns 1 match -> Confirm the pointer line is present

### Task 5 — Confirm deploy-signal nudge logic still intact (AC-7)

[ ] VERIFY: `bash .claude/hooks/session-start.sh 2>&1 | grep -c "Deploy signals detected"` returns 0 in this repo (no signal files present) -> Run the hook end-to-end and confirm no spurious nudge

[ ] VERIFY: `grep -E "DEPLOY_SIGNAL=" .claude/hooks/session-start.sh | wc -l` returns ≥1 -> Confirm the nudge logic block (lines 75–93) was NOT touched by Task 4's edit

### Task 6 — Measure savings against baseline (AC-8)

[ ] VERIFY: `wc -c CLAUDE.md` returns ≤11754 (≥2500 byte reduction from baseline 14254) -> Compare new size against Task 1 baseline; if reduction is smaller than expected, investigate before claiming complete

[ ] VERIFY: `bash .claude/hooks/session-start.sh 2>/dev/null | wc -c` returns ≤2200 (≥600 byte reduction from baseline 2802) -> Compare new hook output size against Task 1 baseline

### Task 7 — Scope integrity check (AC-9)

[ ] VERIFY: `git diff --name-only` lists exactly: `CLAUDE.md`, `.claude/hooks/session-start.sh`, `.claude/deployments/README.md`, `specs/trim-session-start-tokens.md`, `tasks/todo.md` (no more, no less) -> Confirm no skill files, agent files, or unrelated files were touched

[ ] VERIFY: `git diff --name-only | grep -c "^\.claude/skills/"` returns 0 -> Explicitly confirm zero skill files modified (per Q3 user direction)

### Task 8 — End-to-end smoke test

[ ] VERIFY: Fresh `bash .claude/hooks/session-start.sh` output contains all of: `MEMORY`, `ACTIVE TASKS`, `GIT  branch:`, `SKILLS AVAILABLE`, `Ready.` headers/markers -> Confirm no section was accidentally removed

[ ] VERIFY: `grep -E "^## (Skills|Agents|Workflow|Core Principles|Quality Gate|Tool Preference Ladder|Observability Discipline|Model Routing Rules|Key Directories|Session Start Checklist|Deployment Verification)" CLAUDE.md | wc -l` returns 11 (one per major section) -> Confirm CLAUDE.md structural integrity preserved
