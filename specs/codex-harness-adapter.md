# Codex Harness Adapter

## Problem

The workflow repository keeps skills and agent personas in a harness-neutral
`.agents/` tree, but its installer currently provisions Claude Code and Pi
directly. Codex users need an explicit, repeatable installation path that
adapts those same sources to Codex's user-level configuration without copying
Claude-only imports or overwriting personal configuration.

## Design

Add a standalone Bash entry point, `scripts/install-codex.sh`, plus a small
stdlib Python renderer/merger used by it:

- install `.agents/skills/` additively into `~/.agents/skills/`;
- render the shared workflow rules into a managed block in
  `${CODEX_HOME:-$HOME/.codex}/AGENTS.md`, omitting Claude import directives;
- convert canonical Markdown agent definitions into Codex TOML files under
  `${CODEX_HOME:-$HOME/.codex}/agents/`;
- install optional lifecycle hook adapters and merge their registrations into
  `${CODEX_HOME:-$HOME/.codex}/hooks.json` without removing existing hooks;
- make reruns idempotent and preserve unrelated user content;
- print the Codex hooks review step instead of silently trusting hooks.

Add a neutral `project-template/AGENTS.md` seed and include it in the existing
git-init scaffold. Update the README with the Codex install, project setup,
and update paths. Do not change the default Claude/Pi installation flow or add
project-specific rules, paths, services, or dependencies.

## Acceptance Criteria

1. A fresh isolated HOME can run `bash scripts/install-codex.sh` successfully
   from outside the repository and receives skills, global AGENTS instructions,
   agent TOMLs, hook scripts, and a valid hooks JSON file.
2. The generated global AGENTS file contains the shared workflow rules, has no
   Claude `@` imports, preserves pre-existing user text, and is idempotent.
3. Every canonical Markdown agent with valid frontmatter produces a TOML file
   with `name`, `description`, and `developer_instructions`; reruns update
   workflow-managed files without deleting unrelated user agents.
4. Hook registration preserves existing JSON keys and commands, adds each
   adapter exactly once, and remains stable after a second installation.
5. The project template seeds `AGENTS.md` alongside the existing Claude
   project rules, and the scaffold installer copies it only when absent.
6. Existing tests remain green and new tests cover isolation, preservation,
   idempotence, rendering, and malformed-input failure behavior.

## Non-goals

- Replacing or redesigning the existing Claude/Pi adapters.
- Automatically modifying project repositories during user-level Codex setup.
- Installing or trusting hooks without the user's Codex review step.
- Adding project-specific instructions to the upstream template.
