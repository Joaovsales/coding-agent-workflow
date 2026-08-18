---
title: Command substitution forks a subshell, so $PPID varies per call and cannot be pinned
date: 2026-08-18
problem_type: pattern
module: tests/
tags: [testing, bash, ppid, subshell, false-green]
applies_when: writing or trusting a bash test that exercises behaviour keyed on process identity ($PPID, $$, process-scoped lock or sentinel files)
---

A guard keyed on `$PPID` shipped with a test suite that appeared to cover it. The
suite never once exercised the guard, because of how the test invoked it.

## The mechanism

```bash
a=$(printf '' | bash -c 'echo $PPID')   # 24428
b=$(printf '' | bash -c 'echo $PPID')   # 24435  <- different
c=$(printf '' | bash -c 'echo $PPID')   # 24444  <- different again
```

`$(...)` forks a fresh subshell per call, and that subshell is the parent. So
every invocation sees a **different** `$PPID`. Redirecting to a file instead
keeps the script's own shell as the parent:

```bash
printf '' | bash -c 'echo $PPID' > p1.txt   # 24719
printf '' | bash -c 'echo $PPID' > p2.txt   # 24719  <- same
printf '' | bash -c 'echo $PPID' > p3.txt   # 24719  <- same
```

## Why it matters

A de-duplication guard keyed on `$PPID` **can never fire** when every invocation
is captured with `$(...)`. The tests passed, and they passed *because the guard
was inert* — the exact opposite of what they appeared to prove.

Worse, this cuts both ways. Once the guard was fixed to key on something genuinely
stable, three pre-existing assertions started failing — not a regression, but the
first time those assertions ever met a working guard.

## What to do

- To pin process-identity behaviour, **redirect to a file** and read it back.
  Never capture with `$(...)`.
- Treat "the test passes" as evidence only after confirming it **fails against
  the unfixed code**. A test that passes both ways is measuring nothing.
- When a fix makes previously-green assertions go red, ask whether they were
  green for the right reason before you touch them. Here they needed
  `CCW_SESSION_GUARD=0`, because they exercise a different feature and were only
  ever isolated from the guard by accident.

## Related

- [[ppid-is-1-on-windows-so-a-ppid-keyed-guard-collapses]] — the defect this hid.
- [[a-slow-test-is-not-a-hung-test]] — the sibling trap in this suite.
