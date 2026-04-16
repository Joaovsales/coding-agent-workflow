# Spec: Separate Project-Specific Config from Synced CLAUDE.md

## Behavior

Restructure the workflow's configuration files so that `/sync` can overwrite the
template-managed `CLAUDE.md` freely without ever risking project-specific
content. All project-specific configuration moves to a layered stack of files,
each with a clear scope and ownership.

### Four-layer config stack

| File | Scope | Committed? | Who writes |
|---|---|---|---|
| `CLAUDE.md` | Template rules only | Yes | `/sync` only |
| `.claude/project.md` | Team-shared project config | Yes | User / `/setup-deployment` / future skills |
| `CLAUDE.local.md` | Personal per-project overrides | No (gitignored) | User |
| `~/.claude/CLAUDE.md` | Cross-project personal | N/A | User (out of scope for this work) |

### Layering mechanism

`CLAUDE.md` declares two `@import` lines near the top of the file (after the
title, before the workflow rules) that Claude Code resolves natively:

```markdown
@.claude/project.md
@CLAUDE.local.md
```

Imports are tolerant — if either file does not exist, Claude Code silently
skips the import (no error). This means new projects work without creating
either file; mature projects fill them in as needed.

### Banner in CLAUDE.md

Immediately above the imports, CLAUDE.md carries a visible banner:

```markdown
> ⚠ DO NOT EDIT — this file is template-managed and overwritten by /sync.
> Project-specific rules go in .claude/project.md (committed) or CLAUDE.local.md (personal).
```

## Inputs

- A workflow user runs `/sync` in a downstream project that previously had
  project-specific content (e.g. `## Deployment Targets`) appended to its
  `CLAUDE.md` by `/setup-deployment`.
- Or: a fresh project with no project-specific content yet.
- Or: an existing project that already has a `.claude/project.md` from a prior
  sync (idempotent re-sync).

## Outputs

### File layout after this change

```
CLAUDE.md                       # Template only. Banner + imports + workflow rules.
.claude/project.md              # NEW. Project-specific rules. Committed. Stub seed in template.
CLAUDE.local.md                 # User-created when needed. Gitignored.
.gitignore                      # Updated to include CLAUDE.local.md
.claude/deployments/README.md   # Gains a "Routing Table Schema" section (the docs that
                                # used to live in CLAUDE.md as an "inactive example")
```

### Skill / hook updates

| Component | Current behavior | New behavior |
|---|---|---|
| `/setup-deployment` | Writes `## Deployment Targets` section into `CLAUDE.md` | Writes into `.claude/project.md`. Creates project.md if missing. |
| `/verify-deployment` | Reads `## Deployment Targets` from `CLAUDE.md` | Reads from `.claude/project.md`. Falls back to `CLAUDE.md` for backward compatibility (logs deprecation warning). |
| `.claude/hooks/session-start.sh` | Greps `CLAUDE.md` for the section header | Greps `.claude/project.md` first, falls back to `CLAUDE.md` if section not yet migrated. |
| `/sync` | Overwrites `CLAUDE.md` with template version | Detects pre-migration state (legacy `## Deployment Targets` in `CLAUDE.md`); auto-migrates to `.claude/project.md` before applying template; documents new layered model. |

### Migration on first `/sync` after this change ships

When `/sync` runs in a project that has not yet migrated:

1. Detect: read project's `CLAUDE.md`. If it contains a literal
   `^## Deployment Targets[[:space:]]*$` heading, project needs migration.
2. Notify user: print a one-paragraph explanation of the new layered model and
   what's about to happen.
3. Confirm: ask user `Migrate now? [y/N]`. Default no.
4. If yes:
   - Extract everything from the `## Deployment Targets` heading through the
     end of the `**Config:**` block (or end of file if no config block).
   - Create `.claude/project.md` if missing, seeded from the template stub.
   - Append the extracted block to `.claude/project.md`.
   - Remove the same block from `CLAUDE.md`.
   - Add `CLAUDE.local.md` to `.gitignore` if missing.
   - Stage all three files for the user to review.
   - Then proceed with the normal sync flow (which now safely overwrites
     `CLAUDE.md`).
5. If no: skip migration and skip the `CLAUDE.md` overwrite (warn that the new
   template will conflict until migration runs). Do not partially apply.

## Edge Cases

- **No project.md and no legacy section**: Fresh project. `/sync` proceeds
  normally. `.claude/project.md` is not auto-created — it appears the first
  time `/setup-deployment` (or any future project-config skill) runs.
- **project.md already exists with content**: `/sync` does not touch it.
  Migration step is a no-op for the project.md side; CLAUDE.md side runs
  normally.
- **CLAUDE.md has BOTH the legacy section AND `.claude/project.md` already
  exists**: ambiguous state. Refuse to auto-migrate; print conflict message
  asking user to manually consolidate, then re-run `/sync`.
- **User declines migration**: `/sync` skips the `CLAUDE.md` overwrite for
  this run. No partial state.
- **CLAUDE.local.md exists but is committed (already in git)**: `/sync` warns
  but does not auto-untrack. User must `git rm --cached CLAUDE.local.md`
  themselves.
- **Template repo itself**: This repo (the template) ships with
  `.claude/project.md` as a clean stub. The template's own `CLAUDE.md` has no
  `## Deployment Targets` section (matches current state). The "inactive
  example" schema docs move to `.claude/deployments/README.md`.
- **Imports unsupported on user's Claude Code version**: out of scope —
  `@import` syntax is a stable Claude Code feature. If a user is on a version
  that doesn't support it, they have larger compatibility issues.
- **Hook regex still matches CLAUDE.md after migration**: covered by the
  fallback behavior — hooks check project.md first, then CLAUDE.md, so a
  half-migrated state still works for one cycle.

## Acceptance Criteria

- [ ] `CLAUDE.md` in this repo contains no project-specific content (no
      Deployment Targets schema example, no project rules)
- [ ] `CLAUDE.md` declares `@.claude/project.md` and `@CLAUDE.local.md` imports
      directly under the title, preceded by the "DO NOT EDIT" banner
- [ ] `.claude/project.md` exists in this repo as a clean stub (header, layering
      explanation, pointer to deployment docs)
- [ ] `.claude/deployments/README.md` contains a new "Routing Table Schema"
      section equivalent to the example block previously in `CLAUDE.md`
- [ ] `.gitignore` contains `CLAUDE.local.md`
- [ ] `/setup-deployment` writes `## Deployment Targets` into
      `.claude/project.md`, creating the file if absent
- [ ] `/setup-deployment` aborts with a clear message if `.claude/project.md`
      cannot be written (instead of falling back to `CLAUDE.md`)
- [ ] `/verify-deployment` reads `## Deployment Targets` from
      `.claude/project.md` first; falls back to `CLAUDE.md` and emits a
      deprecation warning when found in the legacy location
- [ ] `.claude/hooks/session-start.sh` greps `.claude/project.md` first for the
      Deployment Targets header; falls back to `CLAUDE.md`
- [ ] `/sync` skill documents the new layered model (replaces the existing
      "CLAUDE.md conflicts" edge-case warning)
- [ ] `/sync` detects legacy `## Deployment Targets` in `CLAUDE.md` and
      offers automatic migration (extract → append to project.md → remove
      from CLAUDE.md)
- [ ] `/sync` migration is idempotent: running twice in a row produces no
      duplicate content and no error
- [ ] `/sync` refuses to overwrite `CLAUDE.md` if migration is needed and the
      user declined, emitting a clear "manual migration required" message
- [ ] All existing tests pass; new tests cover the migration logic and the
      fallback behavior in verify-deployment + session-start.sh

## Files Likely Involved

- `CLAUDE.md` — strip project-shaped content; add banner + imports
- `.claude/project.md` — NEW — clean stub with layering explanation
- `.gitignore` — add `CLAUDE.local.md`
- `.claude/deployments/README.md` — add "Routing Table Schema" section
- `.claude/skills/setup-deployment/SKILL.md` — change write target from
  `CLAUDE.md` to `.claude/project.md`; auto-create file if missing; update
  abort message; update step headings that say "CLAUDE.md state"
- `.claude/skills/verify-deployment/SKILL.md` — update read path; add
  fallback + deprecation-warning logic
- `.claude/hooks/session-start.sh` — update grep path; add fallback
- `.claude/skills/sync/SKILL.md` — document layered model, add migration
  procedure, remove "CLAUDE.md conflicts" warning, add `.claude/project.md`
  to syncable-paths exclusion list (project.md is project-specific, NEVER
  synced)
- `.claude/memory.md` — add architectural decision row for the layered config

## Out of Scope

- Migrating other skills or agents that *reference* `CLAUDE.md` by name in
  prose only (e.g. `code-reviewer.md`, `build/SKILL.md`) — they describe
  workflow, not project config, and don't need updates
- `~/.claude/CLAUDE.md` user-global layer — already a native Claude Code
  feature, no template work needed
- Creating a separate `/migrate-config` skill — auto-migration in `/sync`
  is sufficient (Q1 decision)
