---
name: plan
description: Interview user, write a feature spec, and create a TDD task breakdown. Use for any non-trivial feature before coding.
argument-hint: "[feature description]"
disable-model-invocation: false
---

# /plan — Structured Spec + Plan Mode

Enter plan mode to define a spec and task breakdown **before any code is written**.

## Model Routing

**This command MUST use `model: opus` for all agent delegations.**
- When spawning the `planner` agent, pass `model: "opus"` to the Agent tool
- When performing codebase exploration or searches, use `model: "haiku"` for the Explore agent
- The planning phase requires the strongest reasoning model for architecture decisions

## Steps

### 0. Pre-Flight — Context Loading

Before interviewing, load available project context:

1. **Check for `tasks/project-context.md`** — if exists, read it for broader project context (architecture, conventions, protection list)
2. **Check for `tasks/backlog.md`** — if exists and an argument was provided:
   - Match the argument against backlog item names
   - If match found: use the backlog item description as the starting point for the spec
   - Mark the item as `[~]` (in progress) in `tasks/backlog.md`
   - If no match: list available `[ ]` items and ask user to pick one
3. **If no backlog exists**: proceed normally (interview from scratch)

### 1. Interview the User
Ask clarifying questions to fully understand the feature:
- What is the desired behavior? What problem does it solve?
- What are the inputs and outputs?
- What are the edge cases and failure modes?
- What constraints exist (performance, security, backwards-compatibility)?
- Which existing files/components are likely involved?
- What does "done" look like? How will we verify it works?

If working from a backlog item, use its description and the PRD context to pre-fill known answers. Only ask about gaps.

Wait for complete answers before proceeding.

### 2. Write the Spec (MUST persist to disk)

This step is not complete until both conditions hold:

1. The file `specs/<feature-name>.md` exists on disk (verify with `ls specs/`)
2. You have printed its **absolute path** in your message output

**Forbidden:**
- Presenting the spec inline as a code block without writing the file
- Claiming the spec is "drafted" without a path to point to
- Asking the user "should I save this?" — always save, then confirm location

**Required output format at end of Step 2:**

```
✓ Spec written: /absolute/path/to/specs/<feature-name>.md
```

If you cannot write the file (permission error, directory missing), STOP and report the error — do not fall back to inline presentation.

Spec template:

```markdown
# Spec: [Feature Name]

## Behavior
[What the feature does, from the user's perspective]

## Inputs
[What data/events trigger this feature]

## Outputs
[What it produces — return values, side effects, UI changes]

## Edge Cases
- [Edge case 1 and expected behavior]
- [Edge case 2 and expected behavior]

## Acceptance Criteria
- [ ] [Verifiable criterion 1]
- [ ] [Verifiable criterion 2]
- [ ] [Verifiable criterion 3]

## Files Likely Involved
- `path/to/file.py` — [why]
- `path/to/component.tsx` — [why]
```

### 3. Write the Plan (MUST persist to disk)

Same echo-or-fail pattern as Step 2 — applied to `tasks/todo.md`:

1. The file `tasks/todo.md` exists on disk and contains the new `## Plan:` block (verify with `grep -F "## Plan:" tasks/todo.md`)
2. You have printed its **absolute path** in your message output

**Required output format at end of Step 3:**

```
✓ Plan written: /absolute/path/to/tasks/todo.md
```

**Forbidden:** presenting the plan inline only, batching plan + spec into a single "draft" without writing both files.

If `tasks/todo.md` already exists with prior content, **append** the new `## Plan:` block — do not overwrite.

Plan template:

```markdown
## Plan: [Feature Name]
> Spec: specs/[feature-name].md

[ ] TDD: [test name] -> [minimal implementation detail]
[ ] TDD: [test name] -> [minimal implementation detail]
[ ] TDD: [test name] -> [minimal implementation detail]
```

Each entry must be a single, testable behavior. Order by dependency.

### 4. Present and Confirm
Show the user both the spec and the plan. Ask:

> "Does this spec and plan meet your requirements?
> Once you confirm with **'y'**, I'll begin the TDD loop."

**Do not write any code until the user confirms.**

### 5. Divergence Check

If `tasks/project-context.md` exists, compare the new spec's decisions against it:

- New dependencies or libraries not in the `[ARCHITECTURE]` section
- Data model changes (new entities, changed relationships)
- Contradictions with stated technical architecture
- New non-functional requirements not in `[NON-FUNCTIONAL]`

**If divergence detected**, prompt the user:
> "This spec introduces [specific change, e.g., 'Redis for caching — not in current architecture']. Update the PRD and project context? (y/n)"

If yes:
1. Update only the affected sections in the source PRD (`specs/prd-*.md`)
2. Regenerate `tasks/project-context.md` from the updated PRD
3. Append the change to the PRD's Revision History table

If no: note the divergence in the spec as a conscious decision and proceed.

### 6. Hand Off to TDD
After confirmation, proceed with `/tdd` or begin the TDD loop directly.
