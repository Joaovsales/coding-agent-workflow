---
title: A null probe result needs a control run before it becomes a conclusion
date: 2026-08-18
problem_type: pattern
module: general — investigation method
tags: [investigation, evidence, probe, false-negative]
applies_when: A diagnostic probe returns nothing, and the emptiness itself is about to be read as the finding.
---

## A null probe result needs a control run before it becomes a conclusion

**Pattern**: When a probe returns nothing, there are two explanations — the
subject produced nothing, or the *channel* carried nothing — and they are
indistinguishable from the empty output alone. Before reporting emptiness as a
property of the subject, run a control that would definitely produce output if
the channel worked.

While probing whether lightpanda implements element geometry, the first probe
emitted `console.log` and returned nothing. Read at face value that supports
"the API is absent" — a clean, quotable, **wrong** conclusion. A control run
showed `console.log` output does not reach stdout in `fetch` mode at all
(`tasks/e2e-log.md:138-139`). Re-probing by writing results into the DOM instead
returned real numbers, and those numbers reversed the finding: the API is not
absent, it is stubbed — the opposite conclusion, with the opposite design
consequence
([a-stubbed-web-api-is-more-dangerous-than-an-absent-one.md](a-stubbed-web-api-is-more-dangerous-than-an-absent-one.md)).

**Why this is worth a rule**: a false negative from a broken channel is
*self-confirming*. It arrives looking exactly like a successful measurement, it
agrees with the prior that motivated the probe ("the cheap browser probably lacks
this"), and nothing downstream contradicts it. Cost asymmetry favours the
control: one extra run, versus a spec written around an inverted premise.

**Prevention rule**: an absence claim needs two runs — the probe, and a positive
control on the same channel. Record both. If only the probe exists, the finding
is at confidence `50` regardless of how clean the output looked, because no line
proves the channel worked.

**Evidence**: the method note appended to the walkthrough that produced the
finding (`tasks/e2e-log.md:138-139`) records that the first probe was faulty
rather than quietly publishing the corrected result.
