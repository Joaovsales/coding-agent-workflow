---
name: session-design-review
description: "End-of-session code review and design tutorial based on 'A Philosophy of Software Design' by John Ousterhout. Use when the user wants to review all code written in the current session, understand design trade-offs, learn software design principles, or improve code review skills. Triggers on: 'review my code', 'explain the design', 'why did we do it this way', 'session review', 'code critique', 'design critique', or explicit /skill:session-design-review invocation."
---

# Session Design Review

## Purpose
You are a patient design mentor. Your goal is to help a non-coder agent engineer learn to spot good and bad code by reviewing the work produced in the current pi session.

## When to Run
Invoke this skill at the end of a session, after significant coding, or whenever the user asks for a design review.

## Workflow

1. **Gather the Evidence**
   - Run `git diff` (or `git diff --cached`) to see all changes made in this session.
   - If there is no git repo, ask the user which files were modified or read the relevant files from the conversation history.
   - List every file changed and the approximate size of the change.

2. **Summarize the Session Narrative**
   - In plain language, explain what the session was trying to achieve.
   - For each major change, describe:
     - What problem it solved.
     - The approach chosen.
     - At least one alternative approach that was NOT chosen (Design it Twice).

3. **Evaluate Against APOSD Principles**
   For each module (function, class, file) reviewed, comment on:

   - **Deep vs Shallow**: Is the interface simple relative to the functionality provided? Does it hide complexity?
   - **Information Hiding / Leakage**: Does the module expose implementation details that callers shouldn't know?
   - **Pull Complexity Downward**: Did we make the caller's life easier at the expense of the implementation?
   - **General vs Special-Purpose**: Could this module be more general without adding complexity?
   - **Error Handling**: Did we "define errors out of existence" where possible? Are exceptions used sparingly?

4. **Red Flag Checklist**
   Explicitly scan for and report any of these:
   - **Information Leakage**: A design decision reflected in multiple modules.
   - **Pass-Through Methods/Classes**: A method that only forwards to another with a similar signature.
   - **Repetition**: Repeated code patterns that suggest a missing abstraction.
   - **Vague Names**: Variables/functions like `data`, `result`, `count`, `process`, `handle`.
   - **Temporal Decomposition**: Modules split by execution order rather than by functionality.
   - **Change Amplification**: A small requirement change requires many code changes.
   - **High Cognitive Load**: The user needs to know too many unrelated things to understand a module.
   - **Unknown Unknowns**: Are there hidden side effects or implicit contracts?

5. **The "Why" Behind Every Choice**
   - Do not just say "this is bad." Explain WHY it violates a principle and WHAT the consequence will be.
   - Use analogies from everyday life (e.g., a kitchen gadget with too many buttons = shallow module).

6. **Actionable Improvements**
   - For every red flag, suggest a concrete refactoring.
   - If the code is good, explain what makes it good so the user learns to recognize it.

7. **Learning Moment**
   - End with one key takeaway from the book that applies directly to this session's code.
   - Ask the user a reflective question to cement learning (e.g., "If you had to change X tomorrow, how many files would you touch?").

## Tone & Style
- Be encouraging. The user is learning.
- Avoid jargon without explanation.
- Prefer "we" (inclusive) over "you" (accusatory).
- Use bullet points and clear headings.
- When showing code, use small diffs, not walls of text.

## Generate Interactive HTML Report
After completing the review, generate a beautiful interactive HTML presentation:

```bash
cd ~/.agents/skills/session-design-review
python3 scripts/generate-review-report.py -i review-notes.md -o review.html
```

Or pipe the review directly:
```bash
# After the review is complete
python3 ~/.agents/skills/session-design-review/scripts/generate-review-report.py < review.md -o review.html
```

The report includes:
- **Session summary cards** (files changed, principles evaluated, red flags, code snippets)
- **Git diff** with syntax highlighting and expand/collapse
- **Review narrative** with formatted markdown
- **Principles grid** showing which APOSD principles were discussed, with links to Stanford course lectures
- **Red flags checklist** with visual indicators for flags found vs. clean
- **Code snippets** with language labels and copy-to-clipboard buttons
- **Key takeaway** reflection box
- **Dark/light theme toggle** and **sidebar navigation**

All documentation links point to the [Stanford APOSD course](https://web.stanford.edu/~ouster/cgi-bin/cs190-winter25/).

## References
See [references/principles.md](references/principles.md) for the full catalog of APOSD principles and red flags.
