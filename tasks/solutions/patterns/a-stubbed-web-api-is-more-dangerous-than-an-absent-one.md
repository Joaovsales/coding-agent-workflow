---
title: A stubbed Web API is more dangerous than an absent one
date: 2026-08-18
problem_type: pattern
module: .agents/skills/verify — e2e browser tiering
tags: [browser, e2e, feature-detection, fail-closed, lightpanda]
applies_when: Adding a reduced-capability backend (headless browser, shim, emulator, mock) behind an interface that callers feature-detect.
---

## A stubbed Web API is more dangerous than an absent one

**Pattern**: When you scope a capability out of a backend, check whether the
removed API *throws* or *returns a plausible value*. An absent API throws, and
the caller notices. A stubbed one returns fiction that satisfies every guard
written to detect absence — so the check that was supposed to protect the caller
becomes the thing that green-lights it.

Lightpanda implements `getBoundingClientRect()` and `offsetWidth`/`offsetHeight`
as constants rather than layout results
(`.claude/browsers/lightpanda.md:51-74`). On a fixture whose button is styled
`position:absolute; left:-9999px`, the geometry came back as
`submit-btn=[110,110,5,5]` — positive width, non-negative x
(`.claude/browsers/lightpanda.md:58`). So the canonical visibility guard

```js
const r = el.getBoundingClientRect();
if (r.width > 0 && r.x >= 0) { /* "it's visible" */ }
```

**passes for an element 9999px off the left edge**
(`.claude/browsers/lightpanda.md:74`).

**Consequence for design**: a capability ceiling cannot be enforced by the
caller's feature detection when the gap is stubbed. It has to be enforced
*above* the backend, by refusing to route the work at all. That is why the tier
system classifies each acceptance criterion before choosing a backend and fails
closed toward the stricter tier
(`.agents/skills/verify/SKILL.md:150`), instead of letting the walkthrough try
and see what happens.

**Corollary — asymmetric treatment of the two failure shapes**: an API that
*errors* is a step failure and names the API in evidence; it must never be
re-classified as passing
(`.agents/skills/verify/SKILL.md:214`). An API that *lies* cannot be caught at
that layer at all, which is what makes pre-classification load-bearing rather
than belt-and-braces.

**Prevention rule**: before trusting a reduced backend, probe one case whose
correct answer you already know from outside the backend, and confirm the
backend gets it *wrong* in a way you can see. If it gets it plausibly wrong and
silently, the gap needs a routing gate, not a runtime check.

See also: [a-null-probe-result-needs-a-control-run.md](a-null-probe-result-needs-a-control-run.md).

**Evidence**: PR for the lightpanda e2e tier; behavioural walkthrough recorded
in `tasks/e2e-log.md` under `Browser: lightpanda 0.3.6 (DOM-tier)`.
