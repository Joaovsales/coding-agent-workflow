# Task Plan

> Spec: specs/superpowers-practices-adoption.md
> Note: These are documentation/config tasks (skills, agents, hooks). No TDD format — each task is a file creation or edit.

## Tier 1 — High Impact, Low Effort

[ ] Create `/verify` skill — .claude/skills/verify/SKILL.md
    Iron law: "NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE"
    Gate function: IDENTIFY → RUN → READ → VERIFY → CLAIM
    Rationalization table (excuse/reality pairs)
    Common failures table (claim/requires/not sufficient)
    Red flags list (premature satisfaction, "should work", etc.)
    Integration points: required by /build, /debug, /wrap-up-session

[ ] Enhance `/tdd` skill — .claude/skills/tdd/SKILL.md
    Add iron law: "NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST"
    Add rationalization table with 12+ excuse/reality pairs
    Add "Red Flags — STOP and Start Over" section
    Add "When Stuck" troubleshooting table
    Create .claude/skills/tdd/testing-anti-patterns.md reference doc

[ ] Enhance `/debug` skill — .claude/skills/debug/SKILL.md
    Add architecture questioning: after 3 failed fixes, STOP and question architecture
    Add "User Signals You're Doing It Wrong" section
    Add rationalization table
    Add iron law: "NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST"

[ ] Enhance `/build` skill — .claude/skills/build/SKILL.md
    Add 2-stage review after each task:
      Stage 1: Spec compliance review (does impl match requirements?)
      Stage 2: Code quality review (is the code clean/maintainable?)
    Tasks proceed only when both reviews pass

## Tier 2 — High Impact, Medium Effort

[ ] Create `/brainstorm` skill — .claude/skills/brainstorm/SKILL.md
    Hard gate: NO implementation until design approved
    9-step process: context → visual aids → questions (one at a time) → 2-3 approaches → present design → write spec → self-review → user approval → hand off to /plan
    Multi-option proposals with trade-off tables
    Spec output: docs/specs/YYYY-MM-DD-<topic>-design.md or specs/<topic>.md

[ ] Create `/receive-review` skill — .claude/skills/receive-review/SKILL.md
    Response pattern: READ → UNDERSTAND → VERIFY → EVALUATE → RESPOND → IMPLEMENT
    Forbidden responses: "You're absolutely right!", "Great point!", performative agreement
    Pushback protocol: when and how to push back with technical reasoning
    YAGNI check for "professional" feature suggestions
    Source-specific handling (user vs external reviewer)
    Implementation order: blocking → simple → complex

[ ] Enhance `/build` with parallel dispatch — .claude/skills/build/SKILL.md
    Add decision logic: identify independent tasks that can run in parallel
    Dispatch pattern: one agent per independent problem domain
    Agent prompt structure: focused, self-contained, specific output
    Integration and conflict resolution after parallel agents return

[ ] Add debug reference docs:
    .claude/skills/debug/root-cause-tracing.md — backward tracing technique
    .claude/skills/debug/defense-in-depth.md — multi-layer validation
    .claude/skills/debug/condition-based-waiting.md — replace timeouts with condition polling
    .claude/skills/debug/find-polluter.sh — test pollution bisection script

## Tier 3 — Medium Impact, Medium Effort

[ ] Enhance `/wrap-up-session` — .claude/skills/wrap-up-session/SKILL.md
    Add verification gate before commit (invoke /verify pattern)
    Add worktree merge-to-main flow when working in worktree
    Add worktree cleanup after merge

[ ] Create `/writing-skills` meta-skill — .claude/skills/writing-skills/SKILL.md
    Skill file structure (YAML frontmatter + markdown body)
    Naming conventions, directory layout
    When to use iron laws, rationalization tables, reference docs
    Checklist for completeness

[ ] Enhance session-start hook — .claude/hooks/session-start.sh
    Inject available skills list into session context
    Show brief skill descriptions so agent knows when to invoke each

[ ] Update CLAUDE.md — add new skills to table:
    /verify, /brainstorm, /receive-review, /writing-skills
    Update descriptions for enhanced skills
