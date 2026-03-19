## Plan: Migrate Commands to Skills Format
> Spec: specs/commands-to-skills-migration.md

[ ] Create skill directories and SKILL.md for: build, checkpoint, learn, plan, security-scan, simplify, start-qa, sync, tdd, wrap-up-session (add YAML frontmatter, preserve prompt content)
[ ] Update sync skill to reference `.claude/skills/` instead of `.claude/commands/`
[ ] Update CLAUDE.md to replace all `.claude/commands/` references with `.claude/skills/`
[ ] Remove `.claude/commands/` directory
[ ] Verify debug skill is unchanged
[ ] Verify all skills are listed in system and invokable
