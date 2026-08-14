---
title: Codex SessionStart hook emits nothing so its JSON assertion fails
date: 2026-08-14
problem_type: test-failure
module: codex/hooks/session_start.py
tags: [codex, hooks, tests, red-baseline, windows]
symptoms: "tests/test-codex-install.sh — 1/22 assertions FAILED: `hook: SessionStart output validates as Codex JSON`, with a JSONDecodeError at line 1 column 1 (char 0), i.e. the hook produced no stdout at all"
root_cause: not established; the hook shells out to a sibling script and produced no output in this environment — reproduced on a pristine detached worktree of origin/master @ 23f0d7d, so it is not caused by any local edit
resolution: none yet — open. Recorded here so the next session does not mistake it for its own regression.
needs_review: true
---

## Symptoms

`bash tests/run.sh` on `origin/master` @ `23f0d7d` reports `RESULT: 1/16 test
files FAILED`. The failing file is `tests/test-codex-install.sh`; every other
assertion in it passes.

The assertion is at `tests/test-codex-install.sh:107-119`: it pipes
`{"source":"startup"}` into the installed
`$CODEX_HOME/hooks/coding-agent-workflow-session-start.py` and parses the result
as JSON. The parse fails at `char 0` — the hook wrote nothing to stdout.

## Root cause

**Not established.** What is established:

- It reproduces on a **pristine** detached worktree of `origin/master` @ `23f0d7d`
  with no local modifications, so it is not caused by branch work.
- Invoking `codex/hooks/session_start.py` directly in that tree fails with
  `coding-agent-workflow-session-start.sh: No such file or directory` (exit 127) —
  the hook delegates to a sibling shell script by path. That path resolution is
  the first thing to check, but the direct invocation used a `CODEX_HOME` the test
  does not, so it is a lead rather than the diagnosis.

The Codex adapter landed in `23f0d7d` (feat: add Codex harness adapter) with this
test included, so the suite has been red since that commit rather than regressing
later.

## Why it is recorded rather than fixed

Found during the pre-flight baseline of an unrelated branch
(`feat/review-context-contract`, review dispatch contract). Fixing another
subsystem inside that branch would violate the Trace test in `.claude/project.md`
§ *Surgical Changes* — every changed line must trace to the current task.

The cost of *not* recording it is concrete: a red baseline that nobody has written
down gets attributed to whoever notices it next, and `/yolo`'s pre-flight halts on
a red baseline without knowing whose red it is.

## Prevention note

The first baseline run of that session was itself worthless: it was launched and
then the tree was edited while it ran, so the run picked up a test file that was
still deliberately red. A baseline must be taken on an unmodified tree, or it
measures a mixture. See `../process/baseline-must-precede-tree-edits.md`.
