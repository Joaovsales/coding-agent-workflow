# Spec: Graphify Enforcement

## Problem

The workflow burns tokens re-exploring the codebase on every session: `/plan` greps to ground its spec, `/debug` greps to trace call chains, `/build` subagents grep to find integration points, and the `Explore` agent is grep-centric by design. Graphify (installed separately) builds a persistent semantic knowledge graph of the codebase that can answer the same questions with claimed ~70× token savings, but:

1. Nothing in this workflow tells skills or agents to prefer it
2. The graph goes stale the moment code changes; nothing refreshes it
3. If graphify is missing, broken, or unhelpful for a given question, the workflow still needs to function

We need graphify to be the **preferred** first step for codebase exploration in `/plan`, `/debug`, and (when applicable) `/build`, with a transparent fallback to Grep and a refresh trigger at end-of-session.

## Behavior

Wire graphify into the workflow as a **soft-dependency, logged-fallback** layer:

1. **Tool Preference Ladder (CLAUDE.md)** — add a row making graphify the preferred tool for "codebase exploration / symbol lookup / call-graph tracing", with Grep/Glob as fallback.
2. **`/plan`** — new Step 0.5 ("Ground in codebase"): attempt `graphify query` for each major component named in the feature before proposing architecture. If graphify unavailable or returns nothing useful, log one line and continue with Grep.
3. **`/debug`** — new substep in root-cause tracing: attempt `graphify path "<failing symbol>" "<suspected cause>"` and `graphify explain "<symbol>"` before opening files. Fallback identical.
4. **`/build` subagents** (`backend-developer`, `frontend-developer`, `code-debugger`) — when a task requires code not already in the agent's context, prefer a `graphify query` call first; fall back to Grep on failure. This is guidance in each agent's markdown, not a hard gate.
5. **`Explore` agent guidance (CLAUDE.md)** — document that the built-in `Explore` subagent should try graphify first for semantic questions, Grep for literal-string searches.
6. **Session-start staleness warning** — `session-start.sh` prints a one-line warning if `graphify-out/graph.json` is older than HEAD (or missing) so the user knows the graph may be outdated, but does not block.
7. **Session-end refresh** — `/wrap-up-session` gains a new step that runs `graphify --update` after the push succeeds. Failures are logged, never fatal.
8. **Logged fallback convention** — every skill/agent that tries graphify and falls back emits exactly one line: `graphify unavailable: <reason>, using Grep` (or `graphify returned no useful results, using Grep`). No other ceremony.

No hard gates. No skill refuses to run because graphify is missing. The graph is an accelerator, not a requirement.

## Design

### 1. `CLAUDE.md` — Tool Preference Ladder row

Add one row to the existing Tool Preference Ladder table:

```markdown
| Codebase exploration / symbol lookup / call-graph tracing | `graphify query`, `graphify path`, `graphify explain` | Grep/Glob raw-file sweeps |
```

Plus one paragraph below the table:

> **Graphify fallback policy**: graphify is a soft dependency. If the binary is missing, `graphify-out/` is absent, or a query returns no useful results, log one line (`graphify unavailable: <reason>, using Grep`) and fall back to Grep. Never fail a skill because graphify is unavailable.

### 2. `.claude/skills/plan/SKILL.md` — new Step 0.5

Inserted between context-gathering and spec-writing:

```markdown
### Step 0.5 — Ground in codebase (graphify-first)

Before proposing architecture, for each major component or subsystem named in the feature request:

1. Try `graphify query "<component>"` to get a semantic summary.
2. If the query fails or returns nothing useful, log:
   `graphify unavailable: <reason>, using Grep`
   and fall back to Grep/Read for the same lookup.
3. Use the results to ground Step 1's clarifying questions in real code, not assumptions.

If `graphify-out/` is missing entirely, skip this step silently — the fallback is Grep during Step 1 anyway.
```

### 3. `.claude/skills/debug/SKILL.md` — graphify in root-cause tracing

The existing `root-cause-tracing.md` reference doc gains a new first step:

```markdown
### Step 1a — Graph-first trace

Before opening files, attempt:
- `graphify path "<failing-symbol>" "<suspected-caller-or-cause>"` — returns the call chain
- `graphify explain "<failing-symbol>"` — returns a plain-language description

If either returns a useful chain, read only the files on that chain (not the whole module).
If graphify fails or returns nothing actionable, log one line and proceed with Grep as before.
```

`SKILL.md` references this new section.

### 4. Agent files — preference directive

Add a short "Codebase exploration" section to each of `backend-developer.md`, `frontend-developer.md`, `code-debugger.md`, `code-reviewer.md`:

```markdown
## Codebase exploration

When you need code you don't already have in context, prefer:
1. `graphify query "<concept>"` — semantic lookup
2. `graphify path "A" "B"` — call-chain tracing
3. `graphify explain "<symbol>"` — symbol description

Fall back to Grep/Read when graphify is unavailable or unhelpful. Log the fallback as one line: `graphify unavailable: <reason>, using Grep`. Never block on graphify.
```

The `planner` agent gets the same section, scoped to architecture grounding.

### 5. `Explore` agent (built-in) — CLAUDE.md guidance

Since `Explore` is a built-in Claude Code subagent (no editable file in this repo), document its usage in `CLAUDE.md`:

```markdown
### Explore agent — graphify preference

When dispatching the `Explore` subagent, include in the prompt:
"Prefer `graphify query` / `graphify path` / `graphify explain` for semantic lookups; fall back to Grep for literal-string searches or when graphify returns nothing."
```

### 6. `.claude/hooks/session-start.sh` — staleness check

Append a graphify freshness check:

```bash
GRAPH_JSON=".graphify-out/graph.json"
if [ -f "$GRAPH_JSON" ]; then
  GRAPH_MTIME=$(stat -c %Y "$GRAPH_JSON" 2>/dev/null || stat -f %m "$GRAPH_JSON" 2>/dev/null)
  HEAD_MTIME=$(git log -1 --format=%ct HEAD 2>/dev/null)
  if [ -n "$GRAPH_MTIME" ] && [ -n "$HEAD_MTIME" ] && [ "$GRAPH_MTIME" -lt "$HEAD_MTIME" ]; then
    echo "⚠  graphify graph is older than HEAD — run /graphify --update or /wrap-up-session to refresh."
  fi
elif [ -d ".graphify-out" ] || command -v graphify >/dev/null 2>&1; then
  echo "ℹ  graphify installed but no graph found — run /graphify to build one."
fi
```

The check is silent on a clean, fresh graph and silent if graphify isn't installed at all.

### 7. `.claude/skills/wrap-up-session/SKILL.md` — refresh step

Add a new step after the push step:

```markdown
### Step N — Refresh graphify graph

After `git push` succeeds:

1. If `graphify` is on PATH and `graphify-out/` exists, run `graphify --update` in the foreground.
2. On success: one-line confirmation (`graphify graph updated`).
3. On failure: one-line warning (`graphify --update failed: <reason>`) — do not fail the wrap-up.
4. If `graphify` is not installed, skip silently.

This runs **after** the push so the graph reflects the exact state of the pushed commit.
```

Numbering shifts accordingly (deployment verification remains the final step).

### 8. Fallback log convention

All five touchpoints (`/plan`, `/debug`, `/build` agents, `Explore`, wrap-up) use one of these exact log strings when falling back:

- `graphify unavailable: <reason>, using Grep` — binary missing, graph missing, query errored
- `graphify returned no useful results, using Grep` — query succeeded but answer was empty/irrelevant

Reason codes (for the first form): `not installed`, `no graph`, `query error`, `stale graph`. Keep the vocabulary small so `grep graphify tasks/*.log` stays useful.

## Edge Cases

- **Graphify installed but no `graphify-out/`** — all skills proceed with Grep; session-start prints the "no graph found" hint once.
- **Graph exists but is partial** (e.g. new files not yet indexed) — graphify returns empty for those symbols; the "no useful results" fallback kicks in per-query. No global re-check.
- **`graphify --update` hangs during wrap-up** — wrap-up enforces a timeout (reuse the existing wrap-up timeout budget, e.g. 60s); on timeout, log and continue to deployment verification.
- **Repo has no code yet (greenfield)** — graphify would produce a trivial/empty graph; `/prd` and first `/plan` both work fine with the Grep fallback.
- **Private submodules not scanned by graphify** — fallback is Grep per query, which already reads submodules; no special handling.
- **Multiple graphify installs / version drift** — out of scope; treat `graphify` as opaque and trust its exit code.

## Acceptance Criteria

1. `CLAUDE.md`'s Tool Preference Ladder lists graphify as the preferred tool for codebase exploration, with the fallback policy paragraph below it.
2. `/plan` attempts `graphify query` for each major component in Step 0.5 and falls back to Grep with a one-line log on failure.
3. `/debug` (via `root-cause-tracing.md`) attempts `graphify path` / `graphify explain` before opening files and falls back to Grep with a one-line log on failure.
4. `backend-developer`, `frontend-developer`, `code-debugger`, `code-reviewer`, and `planner` agent files each contain a "Codebase exploration" section with the graphify preference and fallback log.
5. `CLAUDE.md` contains a one-paragraph directive for dispatching the built-in `Explore` subagent with graphify preference.
6. `session-start.sh` prints a one-line warning when `graphify-out/graph.json` is older than HEAD, a hint when graphify is installed but no graph exists, and is silent otherwise.
7. `/wrap-up-session` runs `graphify --update` after `git push`, logs success or failure in one line, and never fails the wrap-up because of a graphify error.
8. No skill, agent, or hook blocks, raises, or refuses to continue because graphify is missing, stale, or errored. Every failure path is a logged fallback.
9. Fallback log strings match the exact two forms specified in Design §8.
10. With graphify uninstalled entirely (no binary, no `graphify-out/`), the full workflow (`/plan` → `/build` → `/wrap-up-session`) runs to completion with exactly one fallback-log line per graphify call site and no other behavioral change.

## Out of Scope

- Running `graphify --watch` as a background daemon
- Triggering `graphify --update` from `Stop` or `PostToolUse` hooks
- Teaching the `critic`, `security-reviewer`, or `context-document-optimizer` agents about graphify (can be added later if adoption proves out)
- Metrics / adoption dashboards
- Installing graphify itself — assumed already installed per user setup
