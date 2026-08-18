# E2E / Evidence Log

> Append-only. Never overwrite prior entries — they form the audit trail.

---

## Downstream Delivery — worktree-bootstrap distribution — 2026-08-17 2820378

Spec: specs/worktree-bootstrap-distribution.md (AC8)
Commit: 282037822a7b946726d6506a097d43edbfce1ef0
PR: https://github.com/Joaovsales/coding-agent-workflow/pull/65

**AC8** — Downstream reachability of `bootstrap-worktree.sh` demonstrated, not asserted.

### (a) The script is an incoming file over `/sync`'s syncable path list

Diffed the branch against `origin/master` restricted to the declared syncable paths —
the same argument list `/sync` and the `session-start.sh` drift check use:

```
git diff --name-only origin/master fix/distribute-worktree-bootstrap -- \
  .agents/skills .agents/agents .claude/skills .claude/agents \
  .claude/hooks .claude/settings.json CLAUDE.md
```

11 files, including both copies of the script:

```
.agents/skills/build/scripts/bootstrap-worktree.sh
.claude/skills/build/scripts/bootstrap-worktree.sh
```

Before this change the script lived at `scripts/bootstrap-worktree.sh` and this same
command returned nothing for it — the file was invisible to `/sync` while four skills
instructed agents to run it. The remaining three files in the commit
(`specs/`, `tests/`, `project-template/.gitattributes`) correctly do **not** appear:
they are outside the syncable set by design.

### (b) `install.sh`'s `cp -r .agents/*` delivers it executable

Copied `.agents/*` into a scratch directory standing in for `~/.agents`:

```
-rwxr-xr-x  3728  fake-home-agents/skills/build/scripts/bootstrap-worktree.sh
```

Git index mode — the meaningful check on Windows, where the filesystem bit is not
authoritative — is `100755` on both trees, same blob:

```
100755 a3afbd4d118c08bd011b593d0f8ff87bbbc15f6e 0  .agents/skills/build/scripts/bootstrap-worktree.sh
100755 a3afbd4d118c08bd011b593d0f8ff87bbbc15f6e 0  .claude/skills/build/scripts/bootstrap-worktree.sh
```

### (c) It executes from the delivered location

Invoking the copy under the scratch `~/.agents` reached its `git worktree add` call and
was rejected by git on the argument, not by the shell on the file — proving the delivered
copy is runnable rather than merely present. `bash -n` reports clean syntax.

Result: PASS

### Environment note

`bash tests/run.sh` locally: 17/18 files pass. `tests/test-codex-install.sh` →
*"SessionStart output validates as Codex JSON"* fails on Windows only, and is
**pre-existing on master** — reproduced at `0064efe` in a clean detached worktree without
this commit. Cause: Python 3.13 on Windows defaults to cp1252, so `json.loads` raises
`UnicodeEncodeError` on the hook banner's non-ASCII characters before parsing. CI (Linux)
reports the full suite green for this commit.

---

## E2E Walkthrough — Lightpanda DOM tier — 2026-08-17 ad475ec

Spec: specs/lightpanda-browser-adoption.md (AC-4, AC-5)
Commit: ad475ec82e926db24ee98217bf654ed6db0432d7
Browser: lightpanda 0.3.6 (DOM-tier) — Docker `lightpanda/browser:0.3.6`, sole backend

**AC-4/AC-5** — with only a DOM-tier backend available, a VISUAL AC yields BLOCKED
and never PASS, while DOM-functional ACs still execute.

### Fixture

A checkout page served by nginx over a private Docker network (real HTTP, no host
port). Two deliberate properties:

- `#total` is filled in by JavaScript after load.
- `#submit-btn` is present and correctly labelled, but styled
  `position:absolute; left:-9999px; top:-9999px` — **DOM-correct, visually absent.**

### AC-1: "the order total is displayed on the checkout page"
Tier: DOM-FUNCTIONAL (element text content)
Journey: load the page, assert the total resolves after scripts run.

Raw HTTP, i.e. what `WebFetch` sees:
```
<p id="total">loading…</p>
```

Lightpanda `fetch --dump html`:
```
<p id="total">Order total: $42.00</p>
```

The scripts ran against a real network fetch — the distinction Iron Law 1 turns
on. Result: **PASS**

### AC-2: "the submit button is visible on the checkout form"
Tier: VISUAL (visibility is a rendering property)
Result: **BLOCKED** — requires a full-fidelity browser; only lightpanda (DOM-tier) available

Not attempted. Recorded as BLOCKED, so the run reports non-success while AC-1's
coverage is kept.

### Why BLOCKED rather than attempted-and-checked

The reflex is to attempt it defensively and let the check fail. Probing the
backend shows why that does not work — geometry is **stubbed, not missing**:

```
submit-btn=[110,110,5,5]  total=[130,130,5,5]  checkout=[80,80,5,5]  h1=[65,65,5,5]
```

Every element reports 5x5 with x == y; an `<h1>` and a `<button>` are not the same
size, and the `left:-9999px` offset is ignored entirely. So the careful assertion

```js
const r = el.getBoundingClientRect();
if (r.width > 0 && r.x >= 0) { /* "visible" */ }
```

**returns true for an element 9999px off the left edge.** A missing API throws and
its caller notices; a stubbed one answers wrong in silence. There is no runtime
signal to fail on, so the tier must be decided before execution — which is what
fail-closed classification does.

Method note: the first geometry probe returned nothing and could have been read
as "API absent". A control run showed `console.log` output does not reach stdout
in `fetch` mode — the probe was faulty, not the API. The values above were
re-obtained by writing results into the DOM, which the dump captures. An empty
result is not evidence of absence.

Result: PASS (AC-4 and AC-5 both satisfied)

### Addendum — 2026-08-18: commit reference rebased

The `Commit:` line above records `ad475ec82e926db24ee98217bf654ed6db0432d7`, the SHA
this branch carried when the walkthrough ran. The branch was later rebased onto master
`8828ba0` to pick up #66/#67/#68, so that SHA is unreachable and `git show` on it fails.
The same content is now `c91ae4a` ("feat(research): offer lightpanda fetch for
JS-rendered pages; guard the decisions").

Corrected by addendum rather than by editing the line above: the log is the audit trail,
and an entry silently rewritten to look as though it always pointed at the right commit
is worth less than one that shows what moved. Nothing about the run itself changed — same
fixture, same `lightpanda/browser:0.3.6` image, same observed values.
