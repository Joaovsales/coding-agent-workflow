---
title: PID-keyed double-invocation guard silently suppresses the SessionStart banner
date: 2026-08-18
problem_type: bug
module: .claude/hooks/session-start.sh
tags: [hooks, session-start, guard, pid-reuse, silent-failure, jq]
symptoms: "SessionStart produces no banner at all for a session -- no error, exit 0. Downstream, any consumer that parses the hook's stdout sees an empty payload; tests/test-codex-install.sh failed this way for four days with its root cause recorded as unknown."
root_cause: "The double-invocation guard derives its key from .session_id only when jq is installed, and falls back to $PPID otherwise. Sentinels are written to a shared ${TMPDIR:-/tmp} and honoured for 300s, so any recycled PID inside that window makes an unrelated, legitimate invocation exit 0 in silence. jq is absent on this machine, so the fallback is the only path taken here."
resolution: "open. tests/test-codex-install.sh was made hermetic with CCW_SESSION_GUARD=0 on 2026-08-18, which removes the test flake but not the defect for real sessions."
needs_review: true
---

## Symptoms

The banner simply does not appear, with no diagnostic and exit 0. Because the
guard's whole purpose is to suppress a *duplicate* banner, a suppressed *first*
banner is indistinguishable from correct behaviour at the call site.

Observed on this box minutes apart with no code change between: the same hook
script produced 2568 bytes of stdout under one parent process and zero under
another.

## Root cause

`.claude/hooks/session-start.sh:43-65`:

- `GUARD_KEY` comes from `.session_id` **only if `jq` is on PATH** and the payload
  carries that field.
- Otherwise it falls back to `$PPID`.
- The sentinel path is `${TMPDIR:-/tmp}/.ccw-session-start-<key>-<source>`, with a
  300-second freshness window.

Two conditions make the fallback wrong rather than merely approximate:

1. **`jq` is optional and frequently absent** (it is absent on this machine), so
   the PID path is not a rare degradation -- it is the normal path here.
2. **PIDs are reused, and the sentinel directory is shared and long-lived.**
   `/tmp` on this box holds hundreds of `.ccw-session-start-*` files dating back
   days. Only a 300s window matters, but that window is easily hit by a second
   session, a test run, or a cron job started around the same time.

The comment at line 46 states the assumption plainly -- "without jq (or without a
session_id) both registrations still share a parent" -- and that is true of the
two registrations it targets. The unstated half is that *unrelated* processes can
share a recycled PID too, and nothing distinguishes the two cases.

## Why it is recorded rather than fixed

Fixing it means changing the identity the guard keys on, which is a design
decision about a hook that runs at the start of every session in every project.
The candidates are not equivalent:

- Include the PID's start time (`/proc`-style) so a recycled PID is a different
  key -- not portable to this Git Bash environment.
- Require `session_id` and skip guarding when it is absent -- restores the double
  banner for jq-less machines, which is the annoyance the guard exists to remove.
- Parse `session_id` with `sed` as the surrounding script already does for
  `source`, dropping the `jq` dependency entirely -- most promising, and closest
  to the file's existing convention, but it changes guard behaviour for every
  user and wants its own test.

Doing this inside a session scoped to a text-encoding defect would break the
Trace test in `.claude/project.md` § *Surgical Changes*.

## Related

- [[codex-session-start-hook-emits-nothing]] -- the test failure this defect
  produced, jointly with an unrelated encoding bug that shared its exact symptom.
