#!/bin/bash
# Pre-push guard — invoked as a PreToolUse hook on Bash calls.
# Purpose:
#   1. When the command is `git push`, run typecheck + lint before allowing the push.
#   2. When the command is a "done"-signaling echo/reply (best-effort match), warn
#      the main agent if local commits have not been pushed to the tracked remote.
#
# Kill switch: SKIP_PREPUSH_GUARD=1
#
# Exit codes:
#   0      — allow the tool call
#   non-0  — block the tool call (Claude Code surfaces stderr back to the agent)

set -uo pipefail

[ "${SKIP_PREPUSH_GUARD:-0}" = "1" ] && exit 0

# Claude Code passes hook input as JSON on stdin. We extract the command.
# Fall back to empty string if jq is unavailable or input is not JSON.
INPUT=$(cat 2>/dev/null || true)
CMD=""
if command -v jq >/dev/null 2>&1; then
  CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null || true)
fi

# Fallback: treat raw stdin as the command if jq parse failed.
[ -z "$CMD" ] && CMD="$INPUT"

# Normalize whitespace for matching.
CMD_TRIM=$(printf '%s' "$CMD" | tr '\n' ' ' | sed -E 's/[[:space:]]+/ /g')

# ── Gate 1: typecheck + lint before git push ─────────────────────────────────
if printf '%s' "$CMD_TRIM" | grep -Eq '^(.*&& *)?git +push( |$)'; then
  # Allow --force push bypass ONLY if the user explicitly set ALLOW_FORCE_PUSH=1.
  if printf '%s' "$CMD_TRIM" | grep -Eq 'git +push[^#]*(--force|-f)( |$)'; then
    if [ "${ALLOW_FORCE_PUSH:-0}" != "1" ]; then
      echo "BLOCKED: force push detected. Set ALLOW_FORCE_PUSH=1 to override." >&2
      exit 2
    fi
  fi

  # Run typecheck + lint if package.json declares them. Silent no-op otherwise.
  if [ -f package.json ] && command -v jq >/dev/null 2>&1; then
    SCRIPTS=$(jq -r '.scripts // {} | keys[]' package.json 2>/dev/null || true)
    for script in typecheck lint; do
      if printf '%s\n' "$SCRIPTS" | grep -qx "$script"; then
        if ! npm run --silent "$script" >/tmp/prepush-"$script".log 2>&1; then
          echo "BLOCKED: \`npm run $script\` failed before push. See /tmp/prepush-${script}.log" >&2
          tail -30 /tmp/prepush-"$script".log >&2
          exit 2
        fi
      fi
    done
  fi
fi

# ── Gate 2: warn on unpushed commits when the agent signals completion ───────
# Best-effort detection of "done"-claims in shell output (e.g., `echo "Done"`).
# We only WARN here (exit 0 with stderr message) — we cannot reliably block
# textual replies, and the real enforcement lives in wrap-up-session.
if printf '%s' "$CMD_TRIM" | grep -Eiq '(echo|printf).*(wrapped up|session done|all done|shipped|pushed)'; then
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    BRANCH=$(git branch --show-current 2>/dev/null || echo "")
    if [ -n "$BRANCH" ]; then
      UPSTREAM=$(git rev-parse --abbrev-ref --symbolic-full-name "@{u}" 2>/dev/null || echo "")
      if [ -n "$UPSTREAM" ]; then
        AHEAD=$(git rev-list --count "$UPSTREAM"..HEAD 2>/dev/null || echo 0)
        if [ "${AHEAD:-0}" -gt 0 ]; then
          echo "WARNING: $AHEAD local commit(s) on $BRANCH not pushed to $UPSTREAM." >&2
          echo "         Do not claim 'done' — run \`git push\` first." >&2
        fi
      else
        echo "WARNING: branch $BRANCH has no upstream. Did you forget \`git push -u origin $BRANCH\`?" >&2
      fi
    fi
  fi
fi

exit 0
