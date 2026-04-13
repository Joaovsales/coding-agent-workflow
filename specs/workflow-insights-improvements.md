# Spec: Workflow Insights Improvements

## Behavior

Apply six targeted improvements to the coding-agent-workflow template, derived from a 78-session insights analysis on a downstream TypeScript/Next.js project. The improvements close gaps that caused premature completion claims, inline (non-persisted) specs, generic-CLI-before-MCP friction, and stale plan blocks. Each improvement is a documentation/configuration edit on existing markdown skill files plus one new skill file.

## Inputs

- Existing skill files: `.claude/skills/{plan,build,wrap-up-session,sync}/SKILL.md`
- Existing rules file: `CLAUDE.md`
- Insights report (analyzed in prior turn) identifying the friction patterns

## Outputs

- New file: `.claude/skills/verify-e2e/SKILL.md`
- Modified: `.claude/skills/plan/SKILL.md` (Step 2 + Step 3 hard echo gate)
- Modified: `.claude/skills/build/SKILL.md` (Phase 4 AC classification + e2e routing, Pre-Flight Step 6)
- Modified: `.claude/skills/wrap-up-session/SKILL.md` (Step 2 duplicate sweep, new Step 6.3 e2e gate)
- Modified: `.claude/skills/sync/SKILL.md` (legacy `.claude/commands/` migration step)
- Modified: `CLAUDE.md` (Tool Preference Ladder, Observability Discipline, Quality Gate amendment, Wrap Up amendment)
- New evidence log convention: `tasks/e2e-log.md` (created on first use by `/verify-e2e`, not committed empty)

## Edge Cases

- **Downstream project has no `.claude/commands/` dir** — `/sync` migration step must no-op silently.
- **Downstream project has BOTH `.claude/commands/` and `.claude/skills/`** with overlapping names — `/sync` must surface the conflict, not auto-resolve.
- **`/verify-e2e` invoked without a browser MCP available** — must STOP and report, not silently downgrade to unit tests.
- **`/build` Phase 4 with all-logic ACs (no user-facing criteria)** — must NOT invoke `/verify-e2e`; e2e is conditional on classification.
- **`/wrap-up-session` Step 6.3 with no specs touched this session** — gate becomes a silent no-op.
- **`/plan` cannot write to `specs/`** (permission, missing dir) — must STOP and report, not fall back to inline.
- **CLAUDE.md already has a `## Quality Gate` section in a downstream project that diverges** — amendment must use exact-match insertion to avoid clobbering.

## Acceptance Criteria

### AC-1 — `/verify-e2e` skill exists and is structurally valid
- [ ] AC-1.1: File `.claude/skills/verify-e2e/SKILL.md` exists
- [ ] AC-1.2: File contains valid YAML frontmatter with `name: verify-e2e`, a `description:`, and `disable-model-invocation: false`
- [ ] AC-1.3: File documents Pre-Flight, Walkthrough Protocol, Evidence Format (writes `tasks/e2e-log.md`), Failure Handling, and Iron Laws sections
- [ ] AC-1.4: Iron Laws explicitly forbid token injection, simulated DOM, and batching ACs
- [ ] AC-1.5: Skill listed alongside other skills in `CLAUDE.md` Skills table

### AC-2 — `/plan` enforces spec persistence
- [ ] AC-2.1: `/plan` Step 2 contains the literal phrase "MUST persist to disk"
- [ ] AC-2.2: Step 2 requires printing the absolute path in the form `✓ Spec written: /absolute/path/...`
- [ ] AC-2.3: Step 2 explicitly forbids inline-only presentation
- [ ] AC-2.4: Step 3 (plan write) has the same echo-or-fail pattern for `tasks/todo.md`

### AC-3 — `/build` Phase 4 routes user-facing ACs through e2e
- [ ] AC-3.1: Pre-Flight Checks include a new step that classifies every AC as `logic | integration | user-facing`
- [ ] AC-3.2: Phase 4 contains a classification table mapping AC type to required evidence
- [ ] AC-3.3: Phase 4 invokes `/verify-e2e` when any AC is classified `user-facing`
- [ ] AC-3.4: Status marks distinguish `✅` (logic/integration) from `✅✅` (e2e walkthrough)

### AC-4 — `/wrap-up-session` sweeps duplicates and gates on e2e coverage
- [ ] AC-4.1: Step 2 contains a "Duplicate Plan Block Detection" subsection
- [ ] AC-4.2: Detection covers (a) duplicate `## Plan:` headings, (b) orphan unchecked subtasks, (c) stale plan blocks whose spec file no longer exists
- [ ] AC-4.3: New Step 6.3 "E2E Coverage Gate" exists between Step 6 and Step 6.5
- [ ] AC-4.4: Step 6.3 STOPs and prompts the user when a user-facing AC has no `tasks/e2e-log.md` entry for the current commit range
- [ ] AC-4.5: Done banner mentions e2e coverage status

### AC-5 — `CLAUDE.md` adds tool ladder, observability, quality-gate row, wrap-up note
- [ ] AC-5.1: New section `## Tool Preference Ladder` exists with rows for Supabase, Vercel, GitHub, Library Docs, Browser E2E
- [ ] AC-5.2: Section contains the rule: "If a CLI asks for a password or fails auth twice, STOP and use the MCP"
- [ ] AC-5.3: New section `## Observability Discipline` exists with the failure-only reporting rule
- [ ] AC-5.4: `## Quality Gate` checklist contains a row about user-facing AC e2e walkthroughs
- [ ] AC-5.5: `### 4. Wrap Up` section mentions running `/verify-e2e` before `/wrap-up-session` when applicable

### AC-6 — `/sync` handles legacy `.claude/commands/` directory
- [ ] AC-6.1: `/sync` Procedure has a new step (before "Show What Changed") titled "Legacy Directory Migration"
- [ ] AC-6.2: Step detects presence of `.claude/commands/` in the target project
- [ ] AC-6.3: When detected, prompts the user with options: archive (rename to `.claude/commands.legacy/`), delete, or skip
- [ ] AC-6.4: When BOTH `.claude/commands/` and `.claude/skills/` contain entries with overlapping basenames, surfaces the conflict list and refuses to auto-resolve
- [ ] AC-6.5: When `.claude/commands/` is absent, the step is a silent no-op (no log line)

### AC-7 — Cross-cutting integrity
- [ ] AC-7.1: `git diff` shows changes to exactly the 6 files listed under Outputs (plus the new `verify-e2e/SKILL.md`)
- [ ] AC-7.2: No skill file is left with broken markdown structure (frontmatter intact, headings hierarchy preserved)
- [ ] AC-7.3: All cross-references between skills resolve (e.g., `/build` referencing `/verify-e2e` matches the actual skill name)

## Files Likely Involved

- `.claude/skills/verify-e2e/SKILL.md` — NEW skill file
- `.claude/skills/plan/SKILL.md` — Step 2 + Step 3 hard gate
- `.claude/skills/build/SKILL.md` — Pre-Flight + Phase 4
- `.claude/skills/wrap-up-session/SKILL.md` — Step 2 + new Step 6.3 + Done banner
- `.claude/skills/sync/SKILL.md` — Legacy migration step
- `CLAUDE.md` — Tool Ladder, Observability, Quality Gate, Wrap Up, Skills table

## Out of Scope

- Hooks to enforce the new rules (mentioned as secondary recommendations in analysis — separate spec)
- Automated migration script for downstream projects (one-off; users will run `/sync` interactively)
- Updating downstream project repos (this spec only modifies the template)
