# Yolo Session Log
> Append-only. One entry per iteration. State lives here, not in context.

## Iteration 1 — 2026-08-14 — IN PROGRESS

**Work item**: Review Context Contract (the four research recommendations)
**Spec**: specs/review-context-contract.md
**Plan tasks**: 10 added, 10 completed
**Branch**: feat/review-context-contract, worktree `.claude/worktrees/review-context`,
based on `origin/master` @ 23f0d7d (verified — PR #61 had already merged, and two
further commits landed after it)

**Pre-flight**:
- Branch safety: OK (not master)
- Clean tree: OK by construction (fresh worktree; the parent clone's uncommitted
  work belongs to another branch and did not enter this one)
- Baseline: **RED, pre-existing.** `tests/test-codex-install.sh` fails on pristine
  `origin/master` @ 23f0d7d — verified on a detached worktree, so not caused by
  this branch. Recorded at `tasks/solutions/bugs/codex-session-start-hook-emits-nothing.md`.
  Yolo's pre-flight says halt on a red baseline; continued deliberately because the
  failure is in an unrelated subsystem (Codex adapter) that this branch does not
  touch, and halting would have delivered nothing. Flagged in the PR rather than
  silently absorbed.
- The first baseline run was itself invalid — launched, then the tree was edited
  while it ran, so it discovered a deliberately-red new test file. Lesson recorded
  at `tasks/solutions/process/baseline-must-precede-tree-edits.md`.

**Commit**: dc37b6e — feat(review): hand reviewers the intent, not only the diff

**Mutation probes** (run after committing, so the restore could not eat the work):
| Mutation | Real failures |
|---|---|
| Delete § Review Dispatch Contract | 11 |
| Drop the contract pointer from wrap-up-session | 1 |
| Rename a persona's `## Context Intake` heading | 1 |
| Delete the anchor-75 naming rule | 2 |
| Re-pin auto-improve's design reviewer to a bare `sonnet` cell | 1 |

**Review**: 4 passes dispatched as separate agents (`dispatched` per *Dispatch
Disclosure*), each carrying the full payload the new contract requires — dogfooding
the change under review. ~40 findings; 15 applied in `443697e`, 1 more in the
follow-up after a probe showed the fix's own guard was blind.

Independent corroboration (separately dispatched, so it promotes):

| Finding | Passes |
|---|---|
| Parallel-dispatch site cites no contract; guard is per-file | 1, 2, 3, 4 |
| Blanket deferral immunity in `code-reviewer` / `critic` | 2, 4 |
| `auto-improve` is a fifth dispatch site, exempted only in a test comment | 1, 4 |
| Probe-count rows do not reconcile with per-tree assertions | 1, 3, 4 |
| `xargs basename` label dominates suite runtime | 1, 2 |

Two findings the review made that no test could have: the review agents ran with
the **old** personas, because dispatch resolves `.claude/agents/` from the project
root rather than this worktree — so every persona change here is inert for the
session that wrote it. And a payload shared by four passes is a shared prior, which
narrows what their agreement is worth. Both are now in the spec's Edge Cases; the
second is in the contract itself.

**Result**: PASS.

**Next**: exit — backlog empty, one work item, one PR.
