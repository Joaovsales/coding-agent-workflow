# shellcheck shell=bash
# Resolve the active project directory for Cursor hooks.
# Global hooks (from ~/.cursor/hooks.json) run with cwd ~/.cursor/, not the
# project root. Project hooks run with cwd = project root. Both receive JSON on
# stdin that may include workspace_roots[].

resolve_workspace_from_hook_stdin() {
  [ -n "${WORKSPACE_ROOT:-}" ] && [ -d "$WORKSPACE_ROOT" ] && cd "$WORKSPACE_ROOT" && return 0

  local input root
  # Hooks receive JSON on a pipe; manual/CI runs must not block on empty stdin.
  if [ -t 0 ]; then
    return 0
  fi

  if command -v timeout >/dev/null 2>&1; then
    input="$(timeout 0.3 cat 2>/dev/null || true)"
  else
    input="$(cat 2>/dev/null || true)"
  fi
  [ -z "$input" ] && return 0

  if ! command -v jq >/dev/null 2>&1; then
    return 0
  fi

  root="$(echo "$input" | jq -r '.workspace_roots[0] // empty' 2>/dev/null || true)"
  if [ -n "$root" ] && [ -d "$root" ]; then
    cd "$root"
  fi
}
