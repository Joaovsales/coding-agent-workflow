---
name: writing-skills
description: Author new skills with proper structure, iron laws, and reference docs. Use when creating or improving skills for the workflow.
argument-hint: "[skill name or purpose]"
---

# /writing-skills — Skill Authoring Guide

## Overview

Skills are the building blocks of the workflow. A well-written skill makes the agent consistently follow a process. A poorly-written skill gets ignored or misapplied.

## Skill File Structure

Every skill lives in `.claude/skills/<skill-name>/SKILL.md`:

```
.claude/skills/
  my-skill/
    SKILL.md              # Main skill file (required)
    reference-doc.md      # Supporting reference (optional)
    template.md           # Templates for output (optional)
    helper-script.sh      # Automation scripts (optional)
```

### YAML Frontmatter (Required)

```yaml
---
name: skill-name                    # Kebab-case, matches directory name
description: One-line purpose.      # When to invoke this skill
argument-hint: "[what to pass]"     # Optional — shown in help
disable-model-invocation: true      # Optional — prevents Skill tool invocation
---
```

**`disable-model-invocation`**: Set to `true` for skills that need the main context (e.g., /plan, /build). Omit for skills that can run independently.

### Markdown Body

Follow this structure for consistency:

```markdown
# /skill-name — Short Title

## Overview
One paragraph: what it does, why it matters.

## The Iron Law (if applicable)
A non-negotiable rule in a code block. Use sparingly — only for critical behavioral constraints.

## The Process
Numbered steps with clear actions. Each step should be:
- Specific enough that the agent can't misinterpret it
- Small enough to complete in one action
- Verifiable — you can tell if it was done correctly

## Common Rationalizations (if applicable)
| Excuse | Reality | table for anticipated shortcuts

## Red Flags — STOP (if applicable)
Bulleted list of signals the process is being violated

## Integration
- Called by: [which skills invoke this one]
- Pairs with: [complementary skills]

## Key Principles
3-5 bullet points capturing the spirit of the skill
```

## When to Use Iron Laws

Add an iron law when:
- The agent has a known tendency to skip the step
- Skipping causes significant downstream problems
- The rule is truly non-negotiable (no valid exceptions)

**Examples of good iron laws:**
- "NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST" (TDD)
- "NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST" (Debug)
- "NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE" (Verify)

**Don't overuse them.** If everything is an iron law, nothing is.

## When to Add Rationalization Tables

Add when the agent commonly talks itself out of following the process. Each row pairs an excuse with its factual rebuttal.

Good rationalization tables:
- Address the specific excuses the agent actually generates
- Keep "Reality" responses short and direct
- Cover 7-12 rationalizations (enough to be comprehensive, not so many they're ignored)

## When to Add Reference Documents

Add companion files when:
- A technique needs detailed examples (code samples, scripts)
- Content would make the main SKILL.md too long (>150 lines)
- The reference is useful across multiple skills
- You have executable scripts (shell, Python) that automate part of the process

Keep reference docs focused on ONE technique each.

## Quality Checklist

Before finalizing a skill:

- [ ] Name matches directory name (kebab-case)
- [ ] Description clearly states WHEN to use the skill
- [ ] Process steps are specific and verifiable
- [ ] No vague instructions ("consider", "think about", "maybe")
- [ ] Iron laws used only for truly non-negotiable rules
- [ ] Integration section documents skill relationships
- [ ] No placeholder text ("TBD", "add later")
- [ ] Tested by reading through as if you had no context — could you follow it?

## Naming Conventions

| Element | Convention | Example |
|---------|-----------|---------|
| Skill directory | kebab-case | `receive-review/` |
| Main file | Always `SKILL.md` | `SKILL.md` |
| Reference docs | kebab-case `.md` | `root-cause-tracing.md` |
| Scripts | kebab-case with extension | `find-polluter.sh` |
| Templates | `*-template.md` | `bug-report-template.md` |

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Vague process steps | Make each step a concrete action with clear output |
| Too many iron laws | Reserve for truly non-negotiable rules (max 1 per skill) |
| Missing integration section | Always document which skills call or pair with this one |
| Monolithic SKILL.md | Extract techniques into reference docs at >150 lines |
| No "When NOT to use" section | Add off-ramps so the skill scales to actual complexity |
