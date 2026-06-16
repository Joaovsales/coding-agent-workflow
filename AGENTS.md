# Pi Project-Specific Rules

> **Pi harness only.** Claude Code uses `.claude/project.md` for project-specific rules.
> **Cursor** mirrors project rules via `.cursor/rules/project-config.mdc` (which references `.claude/project.md`).
> `CLAUDE.md` (shared rules, workflow, principles) is loaded automatically by all harnesses — this file adds on top of it for Pi.
> Safe to edit — `/sync` never touches this file.

---

## Project-Specific Rules

> Add project-specific rules for Pi here.
> Examples: tech-stack conventions, architectural constraints, domain glossary, service URLs.

### Code Economy

A **generation-time** gate that runs *before* you write code — the preventive
counterpart to the post-hoc `/simplify`, `/deslop`, and `/quality-gate` passes.
Apply to every code-writing turn. The cheapest line to review is the one never written.

**Decision hierarchy** — walk top to bottom; stop at the first that applies:

1. **Necessity (YAGNI)** — does this need to exist at all? Skip speculative
   abstractions, config knobs with one setting, and features no AC asks for.
2. **Standard library** — does the language's stdlib already provide it? Prefer
   it over a hand-rolled equivalent.
3. **Native platform** — does the OS/browser/runtime provide it? (e.g.
   `<input type="date">` over a date-picker dependency.)
4. **Existing dependency** — is it already installed? Reuse it before adding a
   new one. **Do not add a dependency for what 1–3 already cover.**
5. **One line** — if a correct one-liner exists, write the one-liner.
6. **Minimal viable code** — only then write the least code that satisfies the AC.

**Never-on-the-chopping-block** (these override the hierarchy — economy never
justifies cutting them; see `CLAUDE.md` § *No Silent Failures*): security,
accessibility, trust-boundary input validation, error handling that prevents
data loss, and anything the user explicitly requested.

**Intentional shortcuts** — when you deliberately pick a minimal solution with a
known limitation, mark it with a `TODO(shortcut):` comment stating the limit and
the upgrade path.
