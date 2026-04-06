---
name: folder-context-optimization
description: Sweep a folder to identify legacy/unused files, propose archival, and update docs. Use when a directory feels bloated or disorganized.
argument-hint: "<folder-path>"
disable-model-invocation: false
---

# /folder-context-optimization — Context Sweep

Analyze a folder, identify legacy or unused files, and propose archival to keep the codebase lean.

---

## Input

The user provides a `<FOLDER_PATH>` to sweep.

## Process

### Step 1 — Inventory

1. List all files in the target folder
2. Identify primary, runtime-relevant artifacts vs legacy/ad-hoc/unused files
3. Trace usage: search for references in code, docs, and tests using Grep/Glob

### Step 2 — Classify

Categorize each file as:
- **Core** — actively used in runtime, tests, or build
- **Legacy** — outdated, superseded, or no longer referenced
- **Ad-hoc** — one-off scripts, scratch files, temporary artifacts
- **Optional** — useful but not essential (docs, examples)

### Step 3 — Propose Archive List

Present a table to the user:

```
| File | Classification | Reason | Action |
|------|---------------|--------|--------|
| ... | legacy | No references found | archive |
| ... | core | Imported by 3 modules | keep |
```

**Wait for user approval before moving anything.**

### Step 4 — Execute (after approval)

1. Move approved files to `archive/<folder-name>/`
2. Create or update `README.md` inside the target folder describing what remains and why
3. Verify no imports or references are broken after archival

## Rules

- Do NOT automate — reason about usage and references before proposing
- Do NOT delete files — archive them so they can be recovered
- Do NOT move files without explicit user approval
- Check for indirect references (dynamic imports, config files, CI scripts)
