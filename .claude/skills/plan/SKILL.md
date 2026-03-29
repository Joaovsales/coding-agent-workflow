---
name: plan
description: Interview user, write a feature spec, and create a TDD task breakdown. Use for any non-trivial feature before coding.
argument-hint: "[feature description]"
---

# /plan — Structured Spec + Plan Mode

Enter plan mode to define a spec and task breakdown **before any code is written**.

## Model Routing

**This command MUST use `model: opus` for all agent delegations.**
- When spawning the `planner` agent, pass `model: "opus"` to the Agent tool
- When performing codebase exploration or searches, use `model: "haiku"` for the Explore agent
- The planning phase requires the strongest reasoning model for architecture decisions

## Steps

### 1. Interview the User
Ask clarifying questions to fully understand the feature:
- What is the desired behavior? What problem does it solve?
- What are the inputs and outputs?
- What are the edge cases and failure modes?
- What constraints exist (performance, security, backwards-compatibility)?
- Which existing files/components are likely involved?
- What does "done" look like? How will we verify it works?

Wait for complete answers before proceeding.

### 2. Write the Spec
Create `specs/[feature-name].md`:

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

### 3. Write the Plan
Write the task breakdown to `tasks/todo.md`:

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

### 5. Hand Off to TDD
After confirmation, proceed with `/tdd` or begin the TDD loop directly.
