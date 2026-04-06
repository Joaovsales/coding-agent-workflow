---
name: brainstorm
description: Explore a feature idea through divergent design thinking before committing to a spec. Use before /plan for non-trivial features requiring design decisions.
argument-hint: "[feature idea or problem statement]"
disable-model-invocation: false
---

# /brainstorm — Divergent Design Exploration

## Overview
Step back and ask what you're really trying to do. Explore the problem space before narrowing to a solution.

## The Hard Gate

```
DO NOT invoke /plan, /build, /tdd, write any code, scaffold any project, or take any implementation action until you have presented a design and the user has approved it.
```

## The Process

### Step 1 — Explore Context
- Read existing codebase structure (package.json, directory layout, key files)
- Check for related specs in specs/, prior plans in tasks/todo.md
- Read .claude/memory.md for architectural context and past decisions
- Understand what already exists before proposing anything new

### Step 2 — Offer Visual Aids
If the topic benefits from diagrams, mockups, or flowcharts:
- Offer to create ASCII diagrams, Mermaid charts, or component trees
- Visual aids help align understanding before committing to design

### Step 3 — Ask Clarifying Questions
Ask questions **one at a time** to understand the full picture:
- What problem does this solve? Who benefits?
- What are the constraints (performance, security, backwards-compat)?
- What does "done" look like?
- Are there examples of similar features in the codebase or elsewhere?

**Prefer multiple-choice questions** when possible — they're faster for the user and reduce ambiguity.

Do NOT dump all questions at once. Ask one, wait for answer, then ask the next based on the response.

### Step 4 — Propose 2-3 Approaches
Present distinct design options with trade-offs:

```markdown
## Option A: [Name]
**Approach**: [How it works]
**Pros**: [Benefits]
**Cons**: [Drawbacks]
**Complexity**: [Low/Medium/High]
**Files affected**: [Key files]

## Option B: [Name]
**Approach**: [How it works]
**Pros**: [Benefits]
**Cons**: [Drawbacks]
**Complexity**: [Low/Medium/High]
**Files affected**: [Key files]

## Recommendation
[Which option and why, with clear reasoning]
```

### Step 5 — Present Design Sections
For complex features, break the design into digestible sections:
- Present each section (architecture, data flow, error handling, testing) separately
- Wait for user feedback on each section before moving to the next
- Scale depth to complexity — simple features get a single summary

### Step 6 — Write the Design Spec
Once the user approves a direction, write a formal spec to `specs/<feature-name>.md`:
- Architecture overview
- Component breakdown
- Data flow
- Error handling strategy
- Testing approach
- Acceptance criteria

### Step 7 — Self-Review the Spec
Before presenting to the user, check the spec for:
- Placeholders or "TBD" items (remove or resolve them)
- Contradictions between sections
- Ambiguous language that could be interpreted multiple ways
- Missing edge cases
- Testability — can every criterion be verified?

### Step 8 — User Approval
Present the complete spec. Ask:
> "Does this design meet your requirements? Confirm with 'y' to proceed to planning."

**Do not proceed without explicit approval.**

### Step 9 — Hand Off to /plan
After approval, invoke `/plan` with the approved spec as input to create the task breakdown.

## Multi-System Projects
For features spanning multiple subsystems:
- Decompose into independent sub-projects
- Each sub-project gets its own design section
- Identify integration points between sub-projects
- Consider which sub-projects can be built in parallel

## When NOT to Use /brainstorm
- Trivial changes (typo fix, config update, small bug fix)
- Feature is already well-defined with clear requirements
- User explicitly says "just do it" or provides a complete spec

Go directly to /plan instead.

## Key Principles
- **Diverge before converging** — explore options before committing
- **One question at a time** — respect the user's attention
- **Show trade-offs** — never present a single option as the only way
- **Hard gate on implementation** — no code until design is approved
- **Scale to complexity** — simple features need less ceremony
