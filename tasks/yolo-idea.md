# Yolo Idea — verbatim

> Captured 2026-08-14. Source-of-truth prompt; survives context resets.

"right those as specs and do a /yolo cycle (on top of this branch if possible but
I already merged to main) so plan, build and wrap up and give me the PR to review"

"those" = the four recommendations from the preceding research turn, which asked:
*"how do the reviewers receive context from what was built? And what are the best
practices? do a research"*

The four recommendations, verbatim from that turn:

1. **Add a "Review dispatch prompt must include" block** mirroring
   `build/SKILL.md`'s implementer contract, and reference it from all three
   dispatch sites: base..HEAD diff (path, not inlined), spec path + the AC list
   verbatim, the completed `tasks/todo.md` entries, any `[AMBIGUITY]` lines and
   `TODO(shortcut):` markers from the session, the boundary sentence ("issues
   introduced by this session; pre-existing patterns out of scope" — currently
   stated to the *orchestrator*, never to the agent), and the four-axis output
   format.

2. **Pass the deferral list explicitly.** Two mechanisms already produce it — the
   Ambiguity Protocol and the shortcut ledger in wrap-up Step 3.7. A reviewer that
   doesn't see them re-litigates decisions the user already made.

3. **Make the 75→100 promotion depend on call-chain verification, not agreement.**
   The `75` anchor is literally "correctness turns on a caller outside the reviewed
   scope." Instructing reviewers to go read that caller converts anchor-75 findings
   into proven or dropped ones, without touching Independence Accounting.

4. **Give each persona an intake contract.** One paragraph per file: what you will
   be given, what to fetch yourself, what is out of scope. Only
   `security-reviewer` says it today.

Research basis (see the spec's Sources section): Anthropic's multi-agent task
description requirements, Anthropic's just-in-time context engineering, Cognition's
share-full-context principle, and the industry finding that diff-only review is the
dominant false-positive source.

Base: `origin/master` @ 23f0d7d (PR #61 already merged; #62 and the Codex adapter
landed after it). Branch: `feat/review-context-contract`.
