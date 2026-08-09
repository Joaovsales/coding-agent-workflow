# Sub-Agent Resilience

How to dispatch sub-agents so a failure surfaces as a **degraded result you can act on** instead of
a phase that sits dead until a human notices.

Applies to every skill that dispatches sub-agents: `/build`, `/auto-improve`, `/yolo`,
`/auto-push`, `/quality-gate`, `/debug`.

---

## The failure that matters: a hang is not an error

An agent that **crashes** returns null and your fallback catches it. An agent that **hangs**
returns nothing at all — no result, no error, no event. Every null-check fallback is downstream of
a return that never happens, so none of them fire.

This is worse under parallel dispatch, because "wait for all to return" is a **barrier**: one hung
agent holds the whole phase, including its own fallback, forever.

> **Field incident.** Three agents dispatched in parallel; two returned in ~5 minutes, the third
> hung. The phase sat dead for ~20 minutes. The orchestrator had a `.filter(Boolean)` fallback *and*
> automatic retry — neither fired, because both live downstream of a return. The user was the only
> liveness detector in the system.

### Rule 1 — Give every agent a tool-call budget with an escape hatch

This is the single highest-value line you can add to a sub-agent prompt. It converts a hang into a
degraded return, which your existing fallbacks *can* see:

```
You have ~35 tool calls. If you approach that limit, STOP exploring and write your artifact
immediately with what you have, listing what you could not verify under a "## Not verified"
heading. A partial, honest artifact is SUCCESS. Hanging is the only failure.
```

Tune the number to the task (15 for a focused edit, 50 for a broad audit). The number matters less
than the explicit permission to return incomplete work.

### Rule 2 — Never put a risky agent inside a barrier

Barrier (`parallel` / "wait for all to return") is correct only when the next step genuinely needs
every prior result at once — dedup across a full set, an early-exit on a zero count, a merge.

If a step only needs results *individually*, pipeline them so each flows on as it lands. When a
barrier is genuinely required, keep the highest-risk agent (usually the one reading the most
source) **outside** it, and let the barrier close on the predictable agents.

### Rule 3 — Retry must vary the strategy, not repeat the prompt

Retry helps **transient** faults: rate limits, network blips, provider errors. It does nothing for a
**deterministic** one — an identical prompt against an identical environment fails identically, and
three attempts cost 3× for the same outcome.

Before retrying, ask: *what will be different this time?* If the answer is "nothing", change the
approach instead — narrower scope, different tools, split into two agents.

### Rule 4 — Arm a stall monitor, not a status poll

The harness already notifies on **completion** and **error**. Polling "is it done yet?" is
redundant and burns tokens. The uncovered case is silence.

Arm a monitor at dispatch time that stays quiet while healthy and speaks only on trouble:

```bash
D=<transcript-dir>          # the workflow/agent transcript directory
prev=-1; stalled=0
for i in $(seq 1 70); do
  n=$(cat "$D"/journal.jsonl 2>/dev/null | wc -l)
  errs=$(grep -c '"type":"error"' "$D"/journal.jsonl 2>/dev/null || echo 0)
  newest=$(ls -t "$D"/agent-*.jsonl 2>/dev/null | head -1)
  idle=$(( $(date +%s) - $(stat -c %Y "$newest") ))
  [ "$n" != "$prev" ] && { prev=$n; stalled=0; }
  [ "$errs" -gt 0 ] && [ "$stalled" -ne 2 ] && { echo "ERROR entries: $errs"; stalled=2; }
  [ "$idle" -gt 240 ] && [ "$stalled" -eq 0 ] && { echo "STALL: no write for ${idle}s"; stalled=1; }
  sleep 20
done
```

- **~240s threshold** — long enough that a slow model call or a large grep doesn't cry wolf, short
  enough that a dead phase surfaces in minutes.
- **Latch the flag** so one stall episode emits once. A monitor that fires every tick gets
  auto-stopped for noise, which silently removes your only detector.
- Use an event-driven monitor, **not** a cron/wakeup poll — polling harness-tracked work is waste.

### Rule 5 — Report what was dropped

A degraded run that reports "done" is indistinguishable from a clean one. Whenever a fallback fires,
say so explicitly: which agent failed, what artifact is missing, what the downstream step ran
without. Silent truncation reads as full coverage.

---

## Conflicts with compaction and compression layers

Many setups run token-optimizing layers — output compressors, MCP proxies, harness autocompact.
They are cheap for the orchestrator and hostile to sub-agents that read a lot of source.

**The mechanism.** A large tool result is replaced by a placeholder such as
`[N items compressed to M. Retrieve more: hash=…]`. The agent calls the retrieval tool to recover
the text; retrieval can fail (`"Content not found. It may have expired or the hash may be
incorrect."`); the agent retries; it loops until it is killed. It never errors — it **hangs**,
which is exactly the case Rule 1 exists to catch.

**It is not uniform.** The failure selects agents doing heavy *text* reads. Agents reading images
(not text-compressed) or web results (small) are unaffected. So the agent that dies is usually the
one doing the most load-bearing work, and the phase looks "mostly fine".

> **Field incident.** A capabilities-documenting agent burned 17, then 22, then 4 retrieval calls
> across three attempts and never returned, while its image-reading and web-searching siblings both
> completed normally.

**Do not fix this by disabling the layer.** It is the user's environment and it is saving them real
tokens. Fix it by never generating a result large enough to trip it:

| Instead of | Use |
|---|---|
| `Read` on a 2000-line source file | `mcp__serena__get_symbols_overview` (compact symbol map) |
| `Read` to find one function | `mcp__serena__find_symbol` with `include_body` |
| `Read` to understand file structure | `smart_outline` (signatures, bodies folded) |
| `grep -r` across the repo | The `Grep` tool with a specific pattern |
| Reading a file "to be safe" | `sed -n '1,120p'` on the range you actually need |

Put these rules **verbatim** in the sub-agent prompt. They are never inferred:

```
- NEVER use Read on a file longer than ~400 lines. Use symbol-level tools or explicit line ranges.
- NEVER call retrieval/decompression tools. If a result looks like a compression placeholder, do
  NOT try to retrieve it — re-issue the SAME read at narrower scope. Retrieval will fail and burn
  your budget.
- NEVER grep generated index directories unscoped (graph/AST/embedding caches). A single unscoped
  grep there can exhaust your context.
```

**Corollary — keep artifacts on disk, not in the reply.** Have each agent write its output to a
file and return only a short summary plus a structured result. The orchestrator's context then holds
pointers and deltas rather than file bodies, which keeps the whole run below the threshold that
triggers compaction in the first place.

---

## Dispatch checklist

Before dispatching any sub-agent:

- [ ] Tool-call budget with an explicit "write partial work and stop" escape hatch
- [ ] Compaction-layer rules pasted verbatim if the agent will read source
- [ ] Artifact written to disk; only a summary + structured result returned
- [ ] Risky agents kept out of barriers; barriers used only where all results are genuinely needed
- [ ] Retry (if any) varies the strategy rather than repeating the prompt
- [ ] Stall monitor armed for anything running unattended
- [ ] Fallback path reports what was dropped instead of failing silently
