---
title: An unquoted YAML plain scalar containing ": " silently deregisters an agent persona
date: 2026-08-14
problem_type: bug
module: .agents/agents/, .claude/agents/, tests/test-agents.sh
tags: [yaml, frontmatter, agents, registration, silent-failure]
symptoms: dispatching `code-reviewer` failed with "Agent type 'code-reviewer' not found" while the file sat on disk with the correct name and the whole test suite stayed green
root_cause: the `description:` value was an unquoted YAML plain scalar containing ": " (auto-generated "Context: ..." / "user: ..." example prose); YAML reads that as a nested mapping, the frontmatter parse aborts, and the harness drops the persona without a diagnostic
resolution: rewrote the three descriptions as colon-free single lines and added tests/test-agents.sh § 4, which classifies the frontmatter constructs that break registration (colon-in-plain-scalar, unbalanced quote, reserved indicator, inline-comment truncation, missing block, name/filename mismatch)
---

## Symptoms

`code-reviewer`, `context-document-optimizer`, and `frontend-design-validator`
were documented in `CLAUDE.md` § Agents and dispatched by name from
`/wrap-up-session` and `/quality-gate`, but the harness reported
`Agent type 'code-reviewer' not found` and omitted all three from the available
types. The other seven personas registered normally.

Everything that could have caught it looked healthy: the files existed in both
trees, `name:` was correct, `tests/test-agents.sh` passed, and skill parity held.
That is the whole difficulty of this bug — **only the parse was broken, and
nothing parsed.**

## Root cause

YAML forbids `": "` inside a plain (unquoted) scalar; it reads as the start of a
nested mapping. The three descriptions were auto-generated blobs carrying
`<example>` blocks full of exactly that:

```
description: Use this agent for code review ... Examples:\n\n<example>\nContext: The user
wants code reviewed...\nuser: "Please write a function that validates email addresses"
```

`yaml.safe_load` raises `mapping values are not allowed here` on all three. The
loader drops the persona and emits nothing — a silent failure in the strict sense
of `CLAUDE.md` § *No Silent Failures*, but one that lives in the harness rather
than in our code, so the only place it could be caught was on disk.

The seven working personas all had short, colon-free descriptions, which is why
the failure looked persona-specific rather than structural.

## Resolution

Descriptions rewritten as colon-free single sentences carrying a proactive-dispatch
clause in the repo's house style (`.agents/agents/code-reviewer.md:3` and the two
siblings, mirrored into `.claude/agents/`). Verified live: all three appeared in the
agent registry on the next session start.

A lossless alternative was checked and rejected. The original 1597-char string can
be preserved in a single-quoted scalar, but only by doubling its 5 apostrophes —
naive single-quoting raises `ParserError`. A 1600-char quoted scalar whose validity
depends on hand-escaping is the same fragility in a new costume, so the concise
form won.

Guard added at `tests/test-agents.sh` § 4. It classifies rather than merely
detects, because the failure class is wider than the one construct that bit us:

| Emitted problem | Why it breaks registration |
|---|---|
| `colon-in-plain-scalar` | `": "` or a trailing `:` opens a mapping — the original bug |
| `unbalanced-quote` | the shape a half-applied "just quote it" fix produces |
| `reserved-indicator` | a plain scalar may not open with `@ \` % * & ! , [ ] { } #` |
| `inline-comment-truncation` | ` #` truncates the value *silently* — it parses, but registers mangled |
| `no-frontmatter` | no block at all, incl. behind a UTF-8 BOM or a leading blank line |
| `name-filename-mismatch` | the harness registers the `name:` **value**, not the filename |

## Prevention

Three rules, each learned from a way this nearly stayed broken:

1. **A guard must fail when its input disappears.** The first version of both new
   checks passed vacuously — an empty extraction produced zero assertions and a
   green run. `§ 5` now pins the extracted name count against the files on disk,
   and the detector emits `no-frontmatter` instead of nothing. A test that
   quietly stops testing is worse than no test, because it retires the concern.
2. **Give a detector negative fixtures.** `§ 4a` self-tests nine shapes through
   the real helper. Without them every assertion is an `ok` on a healthy file and
   a detector reduced to a no-op still reports green.
3. **"Exists" is not "loads".** `tests/test-agents.sh` already asserted file
   existence, canonical parity, and required keys, and all of it passed while the
   agent was unusable. When a registry is keyed on parsed content, assert the
   parse and assert the key it registers under.

Note the residual limit, stated in the test itself: this is static. It proves a
file *can* register; only a live session proves it *did*.

## Related

- [A parity `cp` can clobber a legitimate harness divergence](../patterns/a-parity-cp-can-clobber-a-legitimate-harness-divergence.md) — the same
  two-tree structure, a different way for the copy to be wrong.
- [The bash test suite enforces `.agents/` ↔ `.claude/` byte-identical skill parity](../patterns/the-bash-test-suite-enforces-agents-claude-byte-identical-sk.md)
- [grep with zero matches aborts hooks under set -eo pipefail](grep-zero-matches-aborts-hooks-under-set-e-pipefail.md) — the other silent-truncation
  bug in this repo; same lesson about testing the empty path.

**Deployment note**: the fix lands in the repo. `~/.claude/agents/` holds installed
copies that `install.sh:127` refreshes; until that runs, the three personas remain
broken in *other* projects on the machine, where no project-level `.claude/agents/`
shadows them.
