---
name: visual-recap
description: Turn a completed branch's git diff into a self-contained HTML visual recap — narrative, file-tree, and annotated key changes. Use after implementation to produce a richer review artifact than a plain diff.
argument-hint: "[git-ref-range]"
disable-model-invocation: false
---

# /visual-recap — Visual Diff Recap

Turn a branch's `git diff` into a polished, self-contained HTML review document — rendered locally, no external service, no MCP. Companion to `/visual-plan` (before implementation); this one runs after.

## The Iron Law

```
EVERY STRUCTURED BLOCK MUST BE true by construction.
```

`file-tree`, `data-model`, and `api-endpoint` blocks are derived **mechanically** from actual `git diff` lines — never inferred, never invented. If a field or route isn't visible in the diff, it does not go in a structured block. The narrative is the *only* place interpretation is allowed. If you catch yourself paraphrasing a diff hunk into a structured field instead of quoting it, stop and quote it.

## When to Use / When Not

Use for branches with schema changes, new/changed API surface, multi-file features, or architectural shifts — anything a reviewer would otherwise have to reconstruct by scrolling a long `git diff`.

Do **not** use for a typo fix, a one-line config change, or a single well-contained function — plain `git diff` reviews faster than an HTML artifact for those.

## Skip when trivial

Before building anything, check the diff shape:

1. Compute `git diff --name-status <base>...HEAD` and `git diff --stat <base>...HEAD`.
2. If the diff touches a single file with a small, self-explanatory hunk (typo, comment, config value, one small function), **skip**:
   - Emit a one-line reason, e.g. `Skip: single-file diff (config/settings.py, 3 lines) — plain git diff is faster to review.`
   - Produce no file. Stop here.
3. Otherwise proceed to the process below.

## Process

### 1. Compute the range mechanically

- Default range: merge-base of the current branch vs. the default branch, through `HEAD` — `git diff <merge-base>...HEAD`.
- If `$ARGUMENTS` supplies a git ref range, use that instead.
- Also pull `git diff --name-status <range>` (per-file add/modify/delete flags) and `git diff --stat <range>` (churn per file). These two commands are the mechanical source of truth for the `file-tree` block — never hand-summarize them.

### 2. Build the content model (JSON)

Emit the `html-presentation` schema (`title`, `takeaway`, `meta`, `summary_cards`, `sections[]`, …) with sections in this order:

1. **Narrative** — 1–3 paragraphs: what changed, why, and risk notes. This is the only section where interpretation is allowed.
2. **`file-tree` block** — every changed file with its add/modify/delete flag and churn (lines added/removed), copied straight from `--name-status` / `--stat`. Every entry must be spot-checkable against those two commands.
3. **`data-model` block** — *conditional*: include only if schema, migration, or model files changed. Fields quoted verbatim from the diff (before/after), never paraphrased.
4. **`api-endpoint` block** — *conditional*: include only if route or handler signatures changed. Method, path, and signature quoted verbatim from the diff.
5. **Key changes** — 3–8 sections, one per meaningful change cluster. Each:
   - `id: keychange-<n>` (the `keychange-` prefix is the sentinel `scripts/visual-render.py` uses to group these sections into a client-side tabset).
   - Title ≤70 characters.
   - `body_md` containing a focused, annotated ```diff``` block, ≤~150 lines. If a cluster's diff is bigger, trim to the representative hunk and note in prose what was cut.

### 3. Render

```bash
python3 .claude/skills/visual-recap/scripts/visual-render.py \
    --input <model.json> \
    -o tasks/recaps/<branch-slug>.recap.html
```

`visual-render.py` wraps `html-presentation`'s generator, then post-processes the output to color `+`/`−` diff lines and wire up the `keychange-*` tabset — no CDN, no external assets.

### 4. Report

Print the artifact's absolute path (`tasks/recaps/<branch-slug>.recap.html`) so the caller can open or attach it.

## Budgets

| Element | Budget |
|---------|--------|
| Key-change tabs | 3–8 |
| Lines per key-change diff | ~150 |
| Key-change title length | ~70 characters |
| `data-model` / `api-endpoint` blocks | Only when the diff actually touches that surface |

## Key Principles

- true by construction: structured blocks are extracted from `git diff --name-status` / `--stat` / hunks, never reconstructed from memory or intent.
- Prose carries interpretation; structured blocks carry facts.
- Skip the gate honestly — a recap nobody needed is clutter, not diligence.
- Self-contained output: `tasks/recaps/` artifacts open with no network, in light and dark mode.
- Does not touch `/sync`-managed files; `scripts/visual-render.py` is owned by this skill.

## Integration

- **Calls**: `.claude/skills/visual-recap/scripts/visual-render.py`, which in turn calls `html-presentation`'s generator.
- **Pairs with**: `/visual-plan` (pre-implementation counterpart), `/wrap-up-session` (recap can be generated before or alongside wrap-up).
- **Output**: `tasks/recaps/<branch-slug>.recap.html` — gitignored by default (transient artifact).
