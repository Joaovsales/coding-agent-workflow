---
title: Codex SessionStart hook emits nothing so its JSON assertion fails
date: 2026-08-18
problem_type: test-failure
module: codex/hooks/session_start.py, .claude/hooks/session-start.sh, tests/test-codex-install.sh
tags: [codex, hooks, tests, red-baseline, windows, encoding, cp1252]
symptoms: "tests/test-codex-install.sh -- 1/22 assertions FAILED: `hook: SessionStart output validates as Codex JSON`, with a JSONDecodeError at line 1 column 1 (char 0), i.e. the hook produced no stdout at all"
root_cause: "Two independent defects with one shared symptom. (1) session-start.sh's double-invocation guard keys on $PPID when the payload carries no session_id, and its sentinels live 300s in a shared TMPDIR, so a recycled PID silently suppresses the banner. (2) session_start.py wrote its JSON with a text-mode print(), which encodes with the platform default (cp1252 on Windows) and raises UnicodeEncodeError on the banner's box-drawing rules and emoji, emitting nothing."
resolution: "fixed -- 2026-08-18. session_start.py pins sys.stdout.reconfigure(encoding='utf-8'); the test sets CCW_SESSION_GUARD=0 (the guard is not what it checks) and PYTHONIOENCODING=cp1252 so the encoding half is pinned on Linux CI too. Suite green; removing the reconfigure line turns it red again."
---

## Symptoms

`bash tests/run.sh` reported `RESULT: 1/19 test files FAILED` from `23f0d7d`
(the commit that added the Codex adapter) until 2026-08-18. The failing
assertion pipes `{"source":"startup"}` into the installed
`$CODEX_HOME/hooks/coding-agent-workflow-session-start.py` and parses the result
as JSON. The parse failed at `char 0` -- the hook wrote nothing to stdout.

## Root cause

Two defects, stacked, both producing *empty stdout*. That shared symptom is why
this stayed unestablished: fixing either one alone leaves the test red, so each
fix looks wrong when tested in isolation.

**1. The double-invocation guard suppressed the banner.**
`.claude/hooks/session-start.sh:43-65` exists to stop the banner printing twice
when the hook is registered both globally and per-project. It derives its key
from `.session_id`, but only when `jq` is available; otherwise it falls back to
`$PPID`. The test payload is `{"source":"startup"}` -- it carries no
`session_id`, so the key is always the PID-based one. Sentinels are written to a
shared `${TMPDIR:-/tmp}` and honoured for 300 seconds, and that directory holds
hundreds of them from previous runs. Any recycled PID inside that window makes
the hook `exit 0` in silence.

This is why the failure looked deterministic while actually being
environment-dependent: it reproduces reliably *just after* another run has
populated fresh sentinels, and not at all from a cold `/tmp`. Evidence from the
same box, minutes apart: the shell hook produced `STDOUT bytes: 2568` under one
parent and zero bytes under another, with no code change between.

**2. The Codex adapter could not encode what the banner contains.**
`codex/hooks/session_start.py` was already careful with bytes on the paths it
had fixed -- `sys.stdin.buffer.read()` for input, `sys.stderr.buffer.write()` for
child stderr -- and then wrote its own payload through a text-mode
`print(json.dumps(payload, ensure_ascii=False))`. Codex always pipes this hook's
stdout, so the stream takes the platform default (cp1252 here, confirmed via
`sys.stdout.encoding`). The banner it wraps carries `=`-rules (U+2550), `->`
(U+2192) and emoji, none of them cp1252-encodable: the write raises
`UnicodeEncodeError` and the process emits nothing.

The `errors="replace"` on the *decode* at line 23 made this worse rather than
safer -- it manufactures U+FFFD, which is also unencodable.

## Resolution

- `codex/hooks/session_start.py`: `sys.stdout.reconfigure(encoding="utf-8")` in
  `main()`, chosen over a `sys.stdout.buffer.write` because the file keeps its
  `print()` call site readable.
- `tests/test-codex-install.sh`: the hook invocation sets `CCW_SESSION_GUARD=0`
  (the documented escape hatch -- this assertion is about the Codex JSON
  envelope, not about the guard) and `PYTHONIOENCODING=cp1252`, which makes the
  encoding half a real pin on Linux CI rather than a Windows-only one.
- Its JSON check now records an assertion on both paths. It previously asserted
  only inside its `else`, so the suite total moved between 21 and 22 depending on
  the result.

Verified: green on three consecutive runs; deleting the `reconfigure` line
returns `1/22 assertions FAILED` on the same assertion.

## What is NOT fixed

The guard defect itself. See [[pid-keyed-hook-guard-suppresses-the-banner]] --
making one test hermetic does not fix the hook for real sessions on a machine
without `jq`.

## Prevention

- This is one instance of a class; see
  [[explicit-encoding-at-every-python-io-boundary]] for the other four found in
  the same sweep.
- A first baseline run of the earlier session was worthless because the tree was
  edited while it ran. See `../process/baseline-must-precede-tree-edits.md`.
- Two dispatched reviewers independently root-caused defect 2 and both missed
  defect 1, because each reproduced `UnicodeEncodeError` in isolation rather than
  through the installed hook. Agreement between reviewers is evidence about the
  defect they both found, not about the absence of another one behind the same
  symptom.
