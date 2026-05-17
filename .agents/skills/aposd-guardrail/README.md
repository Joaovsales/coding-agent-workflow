# APOSD Guardrail — Agent-Agnostic Design

## What Was Built

The `session-design-review` skill was a **post-hoc report generator** — it produced
pretty HTML *after* a session ended. We needed something different: a **blocking gate**
that runs *before* a task is marked "done", enforcing APOSD principles and catching
the refactors we'd been skipping (like the hash/upload mismatch we left behind).

We built a **two-tier, agent-agnostic system**:

```
┌─────────────────────────────────────────────────────────────┐
│  ANY AI agent harness (pi, Claude Code, Codex, Cursor, ...) │
│                                                             │
│  ┌──────────────────┐    ┌──────────────────────────────┐  │
│  │ SKILL (agnostic) │    │ SUBAGENT (harness-specific)  │  │
│  │                  │    │                                │  │
│  │ aposd-guardrail  │◄──►│ aposd-design-guardian        │  │
│  │   SKILL.md       │    │   .md file in agent format   │  │
│  │   references/    │    │                                │  │
│  │   templates/     │    │ Knows harness conventions:   │  │
│  │   scripts/       │    │   - pi → /skill:name         │  │
│  │                  │    │   - Claude Code → /agent     │  │
│  └──────────────────┘    │   - Codex → @agent mentions  │  │
│                          └──────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## File Inventory

### Tier 1: Agnostic Skill (any harness can read this)

| File | Purpose |
|------|---------|
| `~/.agents/skills/aposd-guardrail/SKILL.md` | Main entry point. Defines the 4-phase blocking gate (Evidence → Principles → Red Flags → Verdict). |
| `references/principles.md` | Full APOSD principles catalog with code examples |
| `references/red-flags-catalog.md` | Each red flag with symptoms + concrete refactor recipes |
| `templates/review-report.md` | Skeleton for a complete review output |
| `templates/checklist-pre-commit.md` | Go/no-go checklist for manual or CI gating |

### Tier 2: Harness-Specific Subagent Files

| File | Harness Format |
|------|---------------|
| `~/.deepagents/global/agents/aposd-design-guardian.md` | Claude Code / OpenAI agent format (frontmatter + system prompt) |
| Can also be: `~/.pi/agent/skills/aposd-guardrail/` | pi directory format (already works, see Tier 1) |

---

## The 4-Phase Blocking Gate

### Phase 0 — Gather Evidence
- `git diff` (or `--file` / `--scope` argument)
- For each file: public interface size, test coverage status

### Phase 1 — Structured Design Review (7 Principles)
1. **Deep vs Shallow** — Is the interface simpler than the implementation?
2. **Information Hiding** — Are DB schema, state enums, lock types hidden?
3. **Pull Complexity Downward** — Did the caller get a simpler API at implementation's expense?
4. **General vs Special-Purpose** — Could this be reused for a similar feature?
5. **Define Errors Out of Existence** — Are there exceptions a better design would prevent?
6. **Design It Twice** — Was an alternative sketched and rejected?
7. **Naming** — Is every public name self-explanatory?

### Phase 2 — Red Flags Checklist (10 Flags)
R1 Repetition | R2 Pass-Through | R3 Info Leakage | R4 Vague Names | R5 Temporal Decomposition | R6 Change Amplification | R7 Cognitive Load | R8 Unknown Unknowns | R9 Shallow | R10 Conjoined Methods

Each flag, if found, gets:
- **WHO**: file:line
- **WHY**: principle violated
- **IMPACT**: what happens as the codebase grows
- **FIX**: concrete refactor (not vague)

### Phase 3 — Blocking Verdict
- 🟢 **GO** — Zero red flags ≥ MEDIUM. Task can be marked done.
- 🟡 **HOLD** — Non-trivial flags found. Refactor checklist required. Task stays in-flight.
- 🔴 **STOP** — Critical flag found. Do NOT mark done. Redesign first.

**The skill enforces this verdict. A user cannot override by saying "it's good enough."**

---

## Real-World Output: Our Own Code Reviewed

We ran the guardrail against the circuit breaker + incremental PDF work from this session.

### Verdict: 🟡 HOLD

**Found**:

| Flag | Severity | Location | Problem |
|------|----------|----------|---------|
| **R1 Repetition** | 🟡 MEDIUM | `circuit_breaker.py` | Reject hook block repeated 4× |
| **R3 Info Leakage** | 🟡 MEDIUM | `pipeline_orchestrator.py` | 14 DB column names copied inline |
| **R5 Temporal Decomp** | 🟡 MEDIUM | `pipeline_orchestrator.py` | Steps numbered inside orchestrator |
| **R8 Unknown Unknown** | 🔴 HIGH | `upload_service.py` | Hash computed on stream, not S3 bytes |

### The Exact Refactors We Skipped

1. **Hash-before-upload bug**: `_compute_file_hash(file)` runs before `upload_file()`. If upload adds compression, dedup silently breaks. The APOSD principle at play: **"Define errors out of existence"** — we designed away the duplicate-processing error but created a silent hash-mismatch error.

2. **Repeated rejection logic**: `if self.on_reject: self._safe_call(self.on_reject)` appears in `_sync_decorator`, `_async_decorator`, `__enter__`, `__aenter__`. The APOSD principle: **"Repetition means a missing abstraction"** — extract `_maybe_reject()`.

3. **Information leakage in deduplication**: `PipelineOrchestrator` knows the exact DB column names (`"embedding_model"`, `"parse_completed_at"`, etc.) that should belong to `PDFCrud`. The APOSD principle: **"Information hiding"** — if you rename a column, how many files break?

---

## Integration Patterns

### In pi (this harness)

```bash
# After tests pass, before marking "done"
/skill:aposd-guardrail --scope circuit-breaker
/skill:aposd-guardrail --file src/backend/services/upload_service.py
```

Or in a plan file:
```markdown
### Phase 5 — Design Gate (Blocking)
- [ ] Run `/skill:aposd-guardrail` on all changed files
- [ ] Must reach 🟢 GO before backlog item is marked complete
```

### In Claude Code

```bash
/orchestrate feature "Add user authentication"
# Workflow: planner -> tdd-guide -> code-reviewer -> aposd-design-guardian
```

The `aposd-design-guardian.md` agent file is placed in `~/.deepagents/global/agents/`
as a first-class citizen alongside `code-reviewer.md`.

### In CI/CD (Pre-Merge Gate)

Add to `.github/workflows/pr-check.yml`:

```yaml
- name: APOSD Design Gate
  run: |
    python scripts/aposd_guardrail.py --diff HEAD~1
    # Exit 1 on STOP or HOLD (with findings)
    # Exit 0 on GO
```

Use the `templates/checklist-pre-commit.md` as a manual merge-request checklist.

### In Pre-Commit Hooks

```yaml
# .pre-commit-config.yaml (future)
- repo: local
  hooks:
    - id: aposd-guardrail
      entry: python ~/.agents/skills/aposd-guardrail/scripts/check-diff.py
      language: system
      stages: [commit]
```

---

## Key Design Decision: Why Two Tiers?

**Tier 1 (Skill)** is the universal spec. Any agent in any harness can read
`SKILL.md` and execute the 4-phase gate. It contains nothing harness-specific.

**Tier 2 (Subagent)** is the harness-specific prompt. Claude Code uses frontmatter
with `model`, `color`, and agent directives. pi uses the SKILL.md directly with
`/skill:name` invocation. Codex might use `@agent` mentions.

By separating them:
- The **core logic** is written once and lives in the skill
- The **harness adapter** is a thin wrapper that knows how to spawn the agent
- Adding a new harness (e.g. Windsurf, Continue.dev) requires only a Tier 2 file

---

## What Makes This "APOSD-Native"

Unlike generic code reviewers (security, type safety, PEP 8), this gate is built
from the ground up on APOSD principles:

| Generic Review | APOSD Guardrail |
|---------------|-----------------|
| "Fix this indentation" | "This module is shallow — merge these 3 methods" |
| "Add type hints" | "This name leaks implementation details" |
| "Handle this exception" | "Design this error out of existence instead" |
| "This function is too long" | "Who owns this knowledge? If you rename it, who breaks?" |

The guardrail is **proactive** (prevents debt) not **reactive** (finds bugs).

---

## Next Steps

1. **Apply the refactors** from the HOLD verdict on our own code:
   - Fix R8 (hash-before-upload)
   - Fix R1 (extract `_maybe_reject`)
   - Fix R3 (move column names into `PDFCrud`)

2. **Test the skill** in a fresh pi session to ensure it loads and executes correctly.

3. **Promote to project-level** by copying `.agents/skills/aposd-guardrail/` into
   `PROJETO-private-knowledge-base/.agents/skills/` so the whole team uses it.

4. **Integrate into CI/CD** by wrapping `templates/checklist-pre-commit.md` into
   a Python script that runs on PRs.
