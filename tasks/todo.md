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

## Plan: Separate Project Config from Synced CLAUDE.md
> Spec: specs/separate-project-config.md
> Branch: claude/separate-project-config-7rywh
> Status: Pending user confirmation

### Task 1 — Add "Routing Table Schema" section to deployments README (AC: schema docs relocated)

[ ] VERIFY: `grep -E "^## Routing Table Schema" .claude/deployments/README.md` returns 1 match AND the section documents the four columns (Service, Runbook, Triggers on branch, Project ID), the optional Config block (Max fix iterations, Build timeout, Preferred status source), and includes a worked example -> Edit `.claude/deployments/README.md` to append the schema section ported from CLAUDE.md's "Inactive Example" block. Use fenced code blocks (no need for the indented-block hack — README is not scanned by the activation regex).

### Task 2 — Create `.claude/project.md` template stub (AC: project.md exists as clean stub)

[ ] VERIFY: `test -f .claude/project.md` exits 0 AND `head -20 .claude/project.md` shows: H1 title "Project-Specific Configuration", a blockquote explaining "Imported by CLAUDE.md, safe to edit, /sync never touches this file", and a `## Deployment Targets` placeholder block using indented (NOT fenced) code so the activation regex stays unmatched in the template repo -> Write `.claude/project.md`. Pattern after the existing inactive-example trick: section heading must NOT be the literal `^## Deployment Targets[[:space:]]*$` in this template; use something like `## Deployment Targets (placeholder — run /setup-deployment to populate)` so the template repo stays inactive.

[ ] VERIFY: `grep -E '^## Deployment Targets[[:space:]]*$' .claude/project.md` returns ZERO matches AND running `.claude/hooks/session-start.sh` produces no Deployment Targets nudge after this file exists -> Confirm the template stub does not accidentally activate verification.

### Task 3 — Update `.gitignore` to exclude `CLAUDE.local.md` (AC: gitignore covers CLAUDE.local.md)

[ ] VERIFY: `grep -F "CLAUDE.local.md" .gitignore` returns 1 match AND `git check-ignore CLAUDE.local.md` exits 0 (when the file would exist) -> Edit `.gitignore` to add `CLAUDE.local.md` with a brief comment explaining its purpose.

### Task 4 — Refactor `CLAUDE.md`: strip schema example, add banner + imports (AC: CLAUDE.md is template-only)

[ ] VERIFY: `grep -F "## Deployment Verification — Schema Reference" CLAUDE.md` returns ZERO matches AND `grep -F "@.claude/project.md" CLAUDE.md` returns 1 match in the first 30 lines AND `grep -F "@CLAUDE.local.md" CLAUDE.md` returns 1 match in the first 30 lines AND `grep -F "DO NOT EDIT" CLAUDE.md` returns 1 match preceding the imports -> Edit `CLAUDE.md` to: (a) delete the "Deployment Verification — Schema Reference (Inactive Example)" section entirely, (b) insert the DO NOT EDIT banner + two `@import` lines directly after the H1 title and intro blockquote, before the "Session Start Checklist" section.

[ ] VERIFY: All other content in CLAUDE.md (Session Start Checklist, Workflow, Agents table, Model Routing, Skills table, Core Principles, Tool Preference Ladder, Observability Discipline, Quality Gate, Key Directories) is byte-identical to before — checked via `git diff CLAUDE.md` showing only the schema-section deletion and the banner+imports insertion -> Run `git diff` and confirm no incidental edits.

### Task 5 — Update `/setup-deployment` skill to write into `.claude/project.md` (AC: setup-deployment writes to project.md)

[ ] VERIFY: `grep -F "CLAUDE.md" .claude/skills/setup-deployment/SKILL.md` returns ZERO matches in instructional contexts that talk about *writing* the table (some prose mentions are fine where they describe the historical/template relationship) AND `grep -F ".claude/project.md" .claude/skills/setup-deployment/SKILL.md` returns matches in: the description frontmatter, the "Step 4 — Check existing state" section heading and body, the abort-on-missing message, and the "Writes are confined to" guarantee -> Edit `setup-deployment/SKILL.md` to swap all write-target references from `CLAUDE.md` to `.claude/project.md`. Update the abort case: if `.claude/project.md` cannot be created or written, abort with a clear message — do NOT fall back to writing CLAUDE.md.

[ ] VERIFY: `grep -F "auto-create" .claude/skills/setup-deployment/SKILL.md` OR `grep -F "create if missing" .claude/skills/setup-deployment/SKILL.md` returns at least 1 match in Step 4 -> Add explicit instruction: if `.claude/project.md` does not exist, create it from a known stub before writing the Deployment Targets table.

### Task 6 — Update `/verify-deployment` to read from `.claude/project.md` with CLAUDE.md fallback (AC: verify-deployment reads new path)

[ ] VERIFY: `grep -F ".claude/project.md" .claude/skills/verify-deployment/SKILL.md` returns matches in: the Step 1 read instruction AND the section-heading regex documentation AND the deprecation-warning fallback AND the "section references a runbook file that doesn't exist" edge-case wording -> Edit `verify-deployment/SKILL.md` to read project.md first; if not present or section absent, fall back to CLAUDE.md and emit `⚠ Deprecation: ## Deployment Targets found in CLAUDE.md. Run /sync to migrate to .claude/project.md.` once per invocation.

[ ] VERIFY: The strict-match regex `^## Deployment Targets[[:space:]]*$` is preserved (still matches only the literal heading, not headings with extra text) -> Confirm regex unchanged.

### Task 7 — Update `session-start.sh` hook to check project.md first (AC: hook reads new path)

[ ] VERIFY: Reading `.claude/hooks/session-start.sh` shows the Deployment Targets check now greps `.claude/project.md` first (when it exists), then falls back to `CLAUDE.md` AND the nudge message updated to reference project.md as the target file ("no Deployment Targets in .claude/project.md") AND the hook still exits 0 in all paths AND running the hook in the current template repo produces no nudge (project.md stub uses non-matching heading per Task 2) -> Edit `.claude/hooks/session-start.sh:75-90` to layer the grep across both files.

### Task 8 — Update `/sync` skill: layered model docs + auto-migration procedure (AC: sync documents new model + auto-migrates)

[ ] VERIFY: `grep -F "Layered Configuration Model" .claude/skills/sync/SKILL.md` OR `grep -F "Project Config Layering" .claude/skills/sync/SKILL.md` returns 1 match -> Add a new section near the top explaining the four-layer stack and which files /sync touches.

[ ] VERIFY: `grep -F ".claude/project.md" .claude/skills/sync/SKILL.md` shows project.md added to the "Never sync" list (it is project-specific) AND removed from any "syncable paths" list -> Update the syncable-paths block.

[ ] VERIFY: `grep -F "Legacy CLAUDE.md Migration" .claude/skills/sync/SKILL.md` OR `grep -F "Migrate Deployment Targets" .claude/skills/sync/SKILL.md` returns 1 match in a new step that runs BEFORE Step 3 (Show What Changed) -> Insert new step "Step 2.6 — Legacy CLAUDE.md Migration" using the same prompt-and-confirm pattern as the existing Step 2.5 legacy commands migration.

[ ] VERIFY: The migration step documents: (a) detection via `grep -E '^## Deployment Targets[[:space:]]*$' CLAUDE.md`, (b) prompt with default-no, (c) extract block from heading through end-of-config-block, (d) append to `.claude/project.md` (creating from stub if missing), (e) remove block from CLAUDE.md, (f) add CLAUDE.local.md to .gitignore if missing, (g) idempotency note (re-running is safe), (h) conflict refusal when BOTH project.md has Deployment Targets AND CLAUDE.md has the legacy block, (i) abort-overall-sync when user declines migration (do not partially apply) -> Confirm all nine bullets in the new step.

[ ] VERIFY: The "CLAUDE.md conflicts" warning in the existing Edge Cases section is REMOVED (or rewritten to reflect that CLAUDE.md is now safe to overwrite) -> Edit Edge Cases section.

### Task 9 — Update `.claude/memory.md` with the architectural decision (AC: decision recorded)

[ ] VERIFY: `grep -F "Layered config" .claude/memory.md` OR `grep -F "project.md import" .claude/memory.md` returns 1 match in the Architecture Decisions table -> Append a row to the Architecture Decisions table: `| Layered config (CLAUDE.md template + .claude/project.md project + CLAUDE.local.md personal) | Lets /sync overwrite template safely; uses native @import; clear ownership per layer |`

### Task 10 — End-to-end consistency review (AC: all spec criteria satisfied, no regressions)

[ ] VERIFY: Walked all 13 acceptance criteria from `specs/separate-project-config.md` and confirmed each is satisfied by a Task 1-9 deliverable. Ran `.claude/hooks/session-start.sh` end-to-end and confirmed it exits 0 with no Deployment Targets nudge. Ran `grep -E '^## Deployment Targets[[:space:]]*$' CLAUDE.md .claude/project.md` and confirmed ZERO matches in either file (template repo stays inactive). Ran `git grep -l "CLAUDE.md" .claude/skills/setup-deployment/ .claude/skills/verify-deployment/ .claude/hooks/session-start.sh` to confirm only fallback / deprecation references remain in code paths (all primary read/write targets now point to project.md). Confirmed no skills outside the migration scope (build/, tdd/, wrap-up-session/, plan/, code-reviewer.md) were modified -> Document the verification in this task's checkbox before marking complete.
