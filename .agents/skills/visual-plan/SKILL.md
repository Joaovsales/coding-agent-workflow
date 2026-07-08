---
name: visual-plan
description: Turn an existing text spec into a rich, self-contained HTML visual plan — narrative, file map, architecture sketch, and open questions — for review before implementation. Use after /plan has already written specs/<feature>.md.
argument-hint: "[path/to/spec.md]"
disable-model-invocation: false
---

# /visual-plan — Visual Plan Generator

## Overview

`/plan` writes a text spec. `/visual-plan` does not re-plan — it reads a spec
that already exists and renders it into a self-contained HTML document at
`specs/<feature>.plan.html` for richer human review than a chat-only spec
supports. It never runs planning itself and never edits source.

The visual plan is the **approval gate**: reviewers look at the rendered file,
not the raw markdown, before implementation starts.

## When to Use / When Not

- **Use** after `/plan` has produced `specs/<feature>.md`, for any change
  non-trivial enough that a file map, an architecture sketch, or an
  open-questions block would help a reviewer catch a bad assumption early.
- **Don't use** for a typo fix, a config tweak, a one-line change, or a
  single well-specified function — see the skip gate below.
- **Don't use** to write or revise the spec itself — that's `/plan`'s job.
  This skill only visualizes a spec that's already on disk.

## Skip when trivial (gate)

Before building anything, check the change's actual size and risk against the
spec:

- Typo / config value / one-line change / a single well-specified function →
  **skip**. Emit one line: `Skipping visual-plan: <reason>` and stop. Produce
  no file.
- Otherwise, proceed to the process below.

## Inputs

- **Required**: a path to an existing spec, `specs/<feature>.md`. If the
  argument is missing, ask for it — do not guess a spec to visualize.
- The real codebase, read for grounding (file paths, symbol names) — **not**
  for planning new ones.

## Read-Only Rule

This skill reads the spec and the real files/symbols it references to ground
the file map and architecture sketch. It makes **no source edits** of any
kind. The visual plan is the review artifact; if the review surfaces changes,
they go back through `/plan`, not through direct edits from this skill.

## Process

1. **Read the spec** at the given path, plus any real files/symbols it names,
   read-only.
2. **Build the content model** — a JSON document in the `html-presentation`
   schema (`title`, `subtitle`, `takeaway`, `meta`, `summary_cards`,
   `sections[]`, `references`, `reflection`), with these blocks as ordered
   sections:
   - **Narrative** — 1–3 paragraphs, concrete, with real product examples
     (not abstract placeholders). What is being built and why, in plain
     language.
   - **File map** — an annotated list of every file the spec touches, each
     with a one-line role. Verify each path against the real repo; files
     that don't yet exist are marked `NEW` instead of a false-positive path.
   - **Architecture / data-flow sketch** — an ASCII box-and-arrow diagram in
     a fenced code block. No Mermaid, no external diagramming — plain text
     that renders anywhere.
   - **Open questions** — hard-to-reverse decisions called out explicitly:
     wire formats, data shapes, ownership boundaries, anything expensive to
     change later. If the spec already answers a question, state the answer
     and why it's hard to reverse; don't invent open questions for their own
     sake.
   - **Wireframe** (optional) — only when the change has a user-facing UI
     surface. ASCII wireframe for v1; omit entirely for backend-only or
     data-only changes.
3. **Render** via the shared post-processor (owned by `visual-recap`, called
   by relative path — do not duplicate its logic here):

   ```bash
   python3 ../visual-recap/scripts/visual-render.py \
       --input <model.json> \
       -o specs/<feature>.plan.html
   ```

4. **Print the artifact path** — `specs/<feature>.plan.html` — and stop. That
   file is the source of truth for review; do not also paste the content
   model inline as a substitute for opening it.

## Outputs

- `specs/<feature>.plan.html` — self-contained, opens with no network, legible
  in light and dark mode.
- No source changes. No edits to the spec that was read.

## Key Principles

- **Visualize, don't re-plan.** The spec is the input; this skill never
  originates requirements.
- **Read-only, always.** Grounding reads real files; nothing here writes to
  them.
- **True to the repo.** Every file map entry is a real path or explicitly
  `NEW` — never a guess presented as fact.
- **Skip readily.** A visual plan for a one-line change is noise, not rigor.
- **The HTML is the gate.** Reviewers approve the rendered plan, not the raw
  JSON or a chat summary of it.

## Integration

- **Calls**: `../visual-recap/scripts/visual-render.py` (shared post-processor;
  owned by the `visual-recap` skill, not duplicated here).
- **Follows**: `/plan` (consumes its `specs/<feature>.md` output).
- **Precedes**: implementation (`/build` or manual coding) — the visual plan
  is the approval checkpoint before code is written.
