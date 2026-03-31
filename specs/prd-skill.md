# Spec: /prd Skill — Product Requirements Document Generator

## Behavior

A new `/prd` skill that interviews the user about a greenfield project, produces a structured PRD document, and decomposes it into an ordered backlog. Also generates a compressed project-context file for agent consumption.

This skill fills the gap between "I have a project idea" and "I have a backlog of work items to plan and build." It is the entry point for greenfield projects.

## Flow Integration

```
GREENFIELD:   /prd → specs/prd-<name>.md + tasks/backlog.md + tasks/project-context.md
              → pick item → /plan (spec + TDD tasks) → /build → mark backlog item done

EXISTING:     tasks/backlog.md already exists
              → pick item → /plan → /build → mark done
```

### Skill Interactions

- **`/brainstorm`**: Use *before* `/prd` when the project idea itself is unclear and needs divergent exploration. `/prd` assumes you know what you want to build.
- **`/plan`**: Updated to optionally accept a backlog item argument. Reads `tasks/project-context.md` for broader project context when writing a spec. Works independently when no backlog exists.
- **`/build`**: Updated with role-based context injection — reads `tasks/project-context.md` and passes relevant sections to each sub-agent type.

## Inputs

- User's project idea (via argument or interview)
- Existing codebase context (if any — package.json, directory layout, CLAUDE.md)
- User answers to interview questions

## Outputs

| File | Purpose | Audience |
|------|---------|----------|
| `specs/prd-<name>.md` | Full PRD document | Humans + planning agents |
| `tasks/backlog.md` | Ordered work items grouped by phase | Humans + `/plan` |
| `tasks/project-context.md` | Compressed, section-labeled agent briefing | Sub-agents only |

## PRD Document Structure

The PRD balances traditional product requirements (sections 1-8) with agent-optimization (sections 9-11).

### Section 1: Overview
- Project name and one-line description
- Problem statement: what pain exists today
- Vision: what the world looks like after this is built
- Target users / personas (brief — name, role, key need)

### Section 2: Goals & Success Criteria
- 3-5 measurable project goals
- Definition of "done" for the overall project
- Key metrics or outcomes that indicate success

### Section 3: User Stories
- Grouped by feature area / persona
- Format: `As [persona], I want [action], so that [benefit]`
- Priority: Must-have / Should-have / Nice-to-have (MoSCoW)

### Section 4: Functional Requirements
- Organized by module or feature area
- Each requirement has:
  - Description (what it does)
  - Acceptance criteria using EARS notation: `WHEN [condition] THE SYSTEM SHALL [behavior]`
  - Priority (Must / Should / Nice)

### Section 5: Non-Functional Requirements
- Performance targets (response times, throughput)
- Security requirements (auth, data protection, compliance)
- Scalability expectations
- Accessibility standards
- Browser/device/platform support

### Section 6: Technical Architecture
- Tech stack (languages, frameworks, databases, infra)
- System boundaries and integrations
- Data model overview (key entities and relationships)
- Key architectural decisions and rationale

### Section 7: Out of Scope / Non-Goals
- Explicit list of what this project does NOT include
- Things that might seem implied but are deliberately excluded
- Future considerations parked for later

### Section 8: Dependencies & Assumptions
- External services, APIs, third-party tools
- Team/resource assumptions
- Technical assumptions (e.g., "users have modern browsers")

### Section 9: Phases & Dependency Order
- Ordered phases, each ending in something verifiable
- Each phase lists which functional requirements it addresses
- Explicit dependencies: "Phase 2 requires Phase 1's API endpoints"
- Phase sizing: each phase should be 1-3 specs worth of work

### Section 10: Protection List
- Files, systems, or patterns that must NOT be modified
- Existing functionality that must be preserved
- External contracts or APIs that cannot change

### Section 11: Risks & Mitigations
- Technical risks (new technology, complex integrations)
- Scope risks (requirements likely to change)
- Mitigation strategy for each

## Backlog Structure (`tasks/backlog.md`)

```markdown
# Backlog: [Project Name]
> PRD: specs/prd-<name>.md
> Generated: YYYY-MM-DD

## Phase 1: [Phase Name]
> Dependencies: none
> Verifiable outcome: [what you can demo/test when phase is done]

- [ ] [Feature/module name] — [one-line description]
- [ ] [Feature/module name] — [one-line description]

## Phase 2: [Phase Name]
> Dependencies: Phase 1
> Verifiable outcome: [what you can demo/test when phase is done]

- [ ] [Feature/module name] — [one-line description]
- [ ] [Feature/module name] — [one-line description]
```

Each backlog item is "spec-sized" — big enough to need `/plan` but small enough to be one coherent feature. Target: 3-8 items per phase, 2-5 phases per project.

## Project Context Structure (`tasks/project-context.md`)

Compressed, section-labeled file for selective agent injection.

```markdown
# Project Context: [Project Name]
> Source PRD: specs/prd-<name>.md
> Generated: YYYY-MM-DD — regenerate with /prd if PRD changes

## [ARCHITECTURE]
Tech stack, system boundaries, data model overview.
Kept concise — no rationale, just facts.

## [PROTECTION]
Files and systems that must not be modified.

## [NON-FUNCTIONAL]
Performance, security, scalability, accessibility targets.

## [CURRENT-PHASE]
Which phase is active, what's been completed, what's next.

## [CONVENTIONS]
Naming conventions, patterns, coding standards specific to this project.
```

### Role-Based Context Injection

`/build` uses these sections selectively when delegating to sub-agents:

| Agent Type | Sections Injected |
|---|---|
| Backend/Frontend developer | `[ARCHITECTURE]` + `[PROTECTION]` + relevant functional requirements from spec |
| Code reviewer | Feature spec + coding standards only — no project-context needed |
| Code debugger | Failing test + relevant code only — no project-context needed |
| Security reviewer | `[ARCHITECTURE]` + `[NON-FUNCTIONAL]` (security subsection) |
| Planner (`/plan`) | Full PRD + backlog item (reads PRD directly, not compressed context) |

## The /prd Process

### Step 1 — Explore Existing Context
- Read codebase structure if any exists
- Read `.claude/memory.md` for prior decisions
- Check if a PRD or backlog already exists (offer to update vs. create new)

### Step 2 — Hybrid Draft + Interview
- From the user's initial prompt, draft a skeleton PRD covering as many sections as possible
- Identify gaps — sections where information is missing or ambiguous
- Interview the user on the gaps only, one question at a time
- Prefer multiple-choice questions when possible

### Step 3 — Write the PRD
- Write `specs/prd-<name>.md` with all 11 sections
- Self-review before presenting:
  - No placeholders or "TBD" items
  - All acceptance criteria are boolean-testable (EARS notation)
  - Non-goals section is populated (not empty)
  - Phases have clear dependency ordering
  - Protection list is populated (even if minimal)

### Step 4 — User Review
- Present the full PRD
- Ask: "Does this PRD capture your requirements? I can adjust any section. Confirm with 'y' to generate the backlog."
- Iterate on feedback until approved

### Step 5 — Generate Backlog
- Decompose the PRD into `tasks/backlog.md`
- Each phase from Section 9 becomes a phase in the backlog
- Each functional requirement cluster becomes a backlog item
- Order respects dependency chain

### Step 6 — Generate Project Context
- Compress the PRD into `tasks/project-context.md`
- Strip rationale, keep facts
- Label sections for selective extraction

### Step 7 — Present Summary
Show the user:
- PRD location
- Backlog with item count per phase
- Suggested first item to `/plan`

## Changes to Existing Skills

### `/plan` SKILL.md Changes
1. Accept optional argument: `/plan <backlog-item-name>`
2. Pre-flight: check for `tasks/project-context.md` — if exists, read it for broader context
3. Pre-flight: check for `tasks/backlog.md` — if exists and argument provided, validate the item exists
4. When planning a backlog item: mark it as `[~]` (in progress) in `tasks/backlog.md`
5. When planning without a backlog: behave as today (interview from scratch)

### `/build` SKILL.md Changes
1. Pre-flight: check for `tasks/project-context.md` — if exists, load it
2. When delegating to sub-agents: inject context sections based on agent role (see table above)
3. After completing all tasks for a feature: if `tasks/backlog.md` exists, mark the corresponding item as `[x]`

## Living Document — Divergence Detection & Updates

The PRD and project-context are living documents that evolve as the project is built. Two mechanisms keep them in sync with reality.

### Rule: `project-context.md` can be auto-updated. `specs/prd-*.md` requires user confirmation.

### Divergence Check in `/plan`

After writing a spec for a backlog item, `/plan` compares key decisions against `tasks/project-context.md`:
- New dependencies or libraries not in the architecture section
- Data model changes (new entities, changed relationships)
- Contradictions with stated technical architecture
- New non-functional requirements (e.g., "this feature needs WebSocket support")

If divergence is detected, prompt the user:
> "This spec introduces [specific change]. Update the PRD and project context? (y/n)"

If yes:
1. Update only the affected sections in `specs/prd-<name>.md`
2. Regenerate `tasks/project-context.md` from the updated PRD
3. Log the change in the PRD's revision history

### Staleness Check in `/wrap-up-session`

Before committing, `/wrap-up-session` performs a quick diff:
- Compare `package.json` / `pyproject.toml` dependencies against `[ARCHITECTURE]`
- Check for new directories or modules not reflected in context
- Look for pattern changes (new middleware, changed auth approach)

If divergence found:
- Auto-update `tasks/project-context.md` (agent-facing, no approval needed)
- Flag PRD sections that may need updating and ask user for confirmation

### PRD Revision History

Append to the bottom of the PRD when updated:

```markdown
## Revision History
| Date | Section | Change | Trigger |
|------|---------|--------|---------|
| YYYY-MM-DD | Technical Architecture | Added Redis for caching | /plan: caching-layer spec |
| YYYY-MM-DD | Non-Functional | Added WebSocket requirement | /plan: real-time-updates spec |
```

## Edge Cases
- **Multiple PRDs**: A project should have one PRD. If `/prd` finds an existing PRD, ask: "Update existing PRD or create a new one?"
- **PRD changes after backlog exists**: Warn user that backlog may be stale. Offer to regenerate backlog (preserving `[x]` items).
- **No backlog item matches `/plan` argument**: List available items and ask user to pick one.
- **Empty protection list**: Acceptable for greenfield. Note: "No protected files — greenfield project."
- **Massive project**: If the interview reveals >5 phases or >30 backlog items, suggest splitting into multiple PRDs or explicitly calling out an MVP phase.

## Acceptance Criteria
- [ ] `/prd` skill file exists at `.claude/skills/prd/SKILL.md`
- [ ] Running `/prd` with a project idea produces all 3 output files
- [ ] PRD contains all 11 sections with no TBD placeholders
- [ ] Backlog items are ordered by phase with dependency annotations
- [ ] Project context file has labeled sections extractable by `/build`
- [ ] `/plan` reads `tasks/project-context.md` when it exists
- [ ] `/plan` accepts a backlog item argument and marks it `[~]` in backlog
- [ ] `/build` injects role-appropriate context sections into sub-agent prompts
- [ ] `/build` marks backlog items `[x]` on completion
- [ ] Existing `/plan` behavior (no backlog) is unchanged
- [ ] `/plan` performs divergence check against project-context after writing spec
- [ ] `/wrap-up-session` performs staleness check against project-context before commit
- [ ] PRD includes revision history section, updated on changes
- [ ] `project-context.md` can be auto-updated; PRD changes require user confirmation
- [ ] CLAUDE.md updated with `/prd` skill and new file locations
