# Spec — Distribute `bootstrap-worktree.sh` to downstream projects

> Status: Draft
> Branch: `fix/distribute-worktree-bootstrap`

---

## Problem

`scripts/bootstrap-worktree.sh` lives at the repo root of the template. Four
skills instruct agents to run it as the fallback when the harness-native
`EnterWorktree` tool is unavailable:

| Skill | Reference |
|---|---|
| `/build` | `.agents/skills/build/SKILL.md:55` (inside a ` ```bash ` fence) |
| `/auto-push` | `.agents/skills/auto-push/SKILL.md:30` |
| `/yolo` | `.agents/skills/yolo/SKILL.md:50` |
| `/auto-improve` | `.agents/skills/auto-improve/SKILL.md:37` |

Nothing distributes the file:

- `/sync`'s syncable-path set covers `CLAUDE.md`, `.agents/skills/`,
  `.agents/agents/`, `.claude/{skills,agents,hooks,settings.json}`. Not `scripts/`.
- `install.sh` copies `.claude/skills/`, `.agents/*`, `.claude/agents/`, one hook,
  and `.agents/git-hooks/pre-push`. Not `scripts/`.
- `project-template/` seeds `CLAUDE.md`, `.ignore`, three `tasks/*.md`, and an
  empty `specs/`. Not the script.

Consequence: in every downstream project the fallback path is a broken command.
An unattended `/yolo` or `/auto-improve` run that cannot reach `EnterWorktree`
falls through to a non-existent script. `project-template/.gitattributes:43`
compounds this by documenting a *flag* (`--detach-head`) of a script the project
does not have.

### Root cause behind the root cause

The syncable-path set is enumerated by hand in **four** places:

1. `.agents/skills/sync/SKILL.md` — the doc block (§ Syncable Paths)
2. `.agents/skills/sync/SKILL.md` — `git diff --stat` command (Step 3)
3. `.agents/skills/sync/SKILL.md` — full `git diff` command (Step 3)
4. `.claude/hooks/session-start.sh` — the template-drift check

(1–3 are duplicated again in the `.claude/skills/` parity copy, so six file
regions in total.) They have **already drifted**: the `session-start.sh` drift
check omits `.agents/agents/`, so a downstream project whose agent personas
changed upstream is never told to run `/sync`. A convention asking people to
update four lists is the actual defect; only a test can hold them equal.

---

## Decision

**Move the script into the canonical skills tree that `/sync` already ships:**

```
scripts/bootstrap-worktree.sh
  → .agents/skills/build/scripts/bootstrap-worktree.sh   (canonical)
  → .claude/skills/build/scripts/bootstrap-worktree.sh   (parity copy)
```

### Why this over the three options considered

| Option | Verdict |
|---|---|
| **A** — `.agents/scripts/` + add to the syncable set | Rejected. Adds a **fifth** entry to four hand-maintained enumerations to fix a bug caused by four hand-maintained enumerations. Also breaks `test-skill-references.sh` (see below). |
| **B** — keep `scripts/`, add `scripts/` to the set + `install.sh` + template | Rejected. `scripts/` is a broad, open-ended path; everything ever dropped there would inherit distribution silently. Handing `/sync` a directory whose future contents are unknown is a standing hazard, not a fix. |
| **C** — make the fallback conditional, lean on `EnterWorktree` | Rejected. `EnterWorktree` is Claude-Code-native. This repo is explicitly dual-harness (Pi reads `.agents/`), so C leaves Pi with *no* worktree bootstrap — the exact case `/auto-improve` calls **mandatory**. It solves a distribution bug by deleting the capability. |
| **D** — `.agents/skills/build/scripts/` ← **chosen** | Uses distribution that already works. Zero new syncable paths. |

**Tradeoff being chosen:** accept that a shared asset lives under one skill's
directory (a mild ownership smell) in exchange for zero new distribution
machinery. `/build` is the legitimate owner — it is the reference implementation
of the worktree decision, and `/auto-improve` already defines its own rule by
reference to it ("not optional here the way it is in `/build` Step 0.5"). The
other three skills reach into `/build`'s directory, which this repo already
treats as legitimate: `tests/test-skill-references.sh` (on `feat/compound-
engineering-tier-1`) documents `.agents/skills/...` in an executed fence as
"how a skill legitimately reaches a shared script in a sibling skill."

Supporting evidence for the shape: skill-local `scripts/` directories are an
**established pattern** here — `.agents/skills/html-presentation/scripts/` and
`.agents/skills/visual-recap/scripts/` already exist and already reach
downstream through the same mechanism.

### Interaction with PR #53

`tests/test-skill-references.sh` does **not** exist on `master`; it is introduced
by commit `bc41516` on `feat/compound-engineering-tier-1` (PR #53). It cannot be
edited from this branch without conflicting with that PR. Option D is chosen
partly because it needs **no** edit to that guard:

- Its token regex matches `\.(agents|claude)/skills/[A-Za-z0-9_./-]+`, which
  consumes `.agents/skills/build/scripts/bootstrap-worktree.sh` whole and routes
  it to the `.agents/skills/*` case — allowed in executed fences, existence
  checked from repo root. Passes.
- Option A's `.agents/scripts/...` would instead be tokenised as the substring
  `scripts/bootstrap-worktree.sh` (the `skills/` alternative cannot match), then
  fail skill-dir-then-repo-root resolution. Red suite, on a branch that cannot
  fix it.

The two PRs therefore merge in either order. One stale *comment* is left behind
in #53 (line 34's "`scripts/bootstrap-worktree.sh` — repo-root shared scripts are
legitimate here"); it is prose, not a code whitelist — the `*)` branch resolves
generically — so nothing breaks. Flagged for #53 rather than edited here.

---

## Behaviour

### Inputs
The template repo tree; a downstream project running `/sync` or `install.sh`.

### Outputs
1. `bootstrap-worktree.sh` present in both skill trees, executable.
2. All 8 skill references (4 skills × 2 trees) name the canonical path.
3. `project-template/.gitattributes` names the canonical path.
4. `session-start.sh`'s drift check covers the same path set as `/sync`.
5. Two new guards (below) fail on regression.

### New guard — `tests/test-syncable-paths.sh`
Extracts the syncable-path set from all four enumerations and asserts they are
equal as sets:

| # | Source | Extraction |
|---|---|---|
| 1 | `.agents/skills/sync/SKILL.md` § Syncable Paths | fenced block, `path → description` lines |
| 2 | same file, `git diff --stat` line | `--` argument list |
| 3 | same file, full `git diff` line | `--` argument list |
| 4 | `.claude/hooks/session-start.sh` drift check | `git diff --name-only` `--` argument list |

Plus the `.claude/skills/sync/SKILL.md` copies of 1–3.
Paths are normalised (trailing `/` stripped) before comparison.

### New guard — reachability
`tests/test-syncable-paths.sh` also asserts that
`.agents/skills/build/scripts/bootstrap-worktree.sh` exists, is executable, and
its path is a descendant of a declared syncable path. This is the direct
regression test for the bug: a shared script that a skill executes must live
somewhere `/sync` ships.

### Edge cases
- The two `git diff` commands in `/sync` legitimately carry extra flags
  (`--stat`); extraction must key off the `--` separator, not position.
- `session-start.sh` splits its arg list across a line continuation (`\`).
- `.claude/settings.json` is a file, not a directory — the descendant check must
  handle both.
- `.claude/worktrees/` holds full copies of both skill trees; every scan must
  exclude it (existing tests already do).
- Git does not preserve the executable bit on Windows checkouts by default; the
  executable assertion must read the git index mode (`git ls-files -s`), not the
  filesystem, or it will fail on Windows for reasons unrelated to the change.

---

## Acceptance Criteria

- [ ] **AC1** `scripts/bootstrap-worktree.sh` no longer exists; the file is at
      `.agents/skills/build/scripts/bootstrap-worktree.sh` with git mode `100755`,
      byte-identical content apart from its own usage comments.
- [ ] **AC2** `.claude/skills/build/scripts/bootstrap-worktree.sh` is
      byte-identical to the canonical copy (`test-skill-parity.sh` green).
- [ ] **AC3** All 8 skill references name
      `.agents/skills/build/scripts/bootstrap-worktree.sh`.
- [ ] **AC4** `project-template/.gitattributes` names the canonical path.
- [ ] **AC5** `session-start.sh`'s drift check lists the same set as `/sync`,
      including the previously-omitted `.agents/agents`.
- [ ] **AC6** `tests/test-syncable-paths.sh` exists, passes, and **fails** when
      any one enumeration is perturbed (demonstrated, not asserted).
- [ ] **AC7** `bash tests/run.sh` green; file and assertion counts recorded.
- [ ] **AC8** Downstream reachability demonstrated with evidence — a scratch
      clone receiving the file via the `/sync` diff path **and** via
      `install.sh`'s `cp -r .agents/*`.
- [ ] **AC9** No changes to `feat/compound-engineering-tier-1` or
      `.claude/worktrees/`.
