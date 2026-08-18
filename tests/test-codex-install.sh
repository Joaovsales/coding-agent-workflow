# tests/test-codex-install.sh — isolated Codex adapter contract.
. "$(dirname "$0")/lib.sh"

REPO="$(cd "$(dirname "$0")/.." && pwd)"
INSTALL="$REPO/scripts/install-codex.sh"
RENDERER="$REPO/scripts/render-codex.py"

assert_file_contains "$RENDERER" "coding-agent-workflow:begin" \
  "renderer: managed global block marker exists"
assert_file_contains "$INSTALL" "CODEX_HOME" \
  "installer: supports CODEX_HOME override"
assert_file_contains "$INSTALL" ".agents/skills/." \
  "installer: installs canonical skills additively"
assert_file_contains "$INSTALL" "Review installed hooks with /hooks" \
  "installer: tells users to review hook registrations"
assert_file_contains "$REPO/install.sh" 'copy_if_missing "AGENTS.md"' \
  "git scaffold: copies neutral AGENTS.md"
assert_file_contains "$REPO/project-template/AGENTS.md" "Project-Specific Rules" \
  "project template: carries a neutral rules section"
assert_file_contains "$REPO/README.md" "bash scripts/install-codex.sh" \
  "README: documents the Codex adapter command"
assert_file_contains "$REPO/README.md" "project-template/AGENTS.md" \
  "README: documents the neutral project seed"

BOX="$(mktemp -d)"
HOME_DIR="$BOX/home"
CODEX_HOME="$HOME_DIR/.codex"
PROJECT="$BOX/project"
mkdir -p "$HOME_DIR/.agents/skills/personal" "$CODEX_HOME/agents" "$PROJECT"
printf 'personal skill\n' > "$HOME_DIR/.agents/skills/personal/SKILL.md"
printf '# Personal Codex instructions\n' > "$CODEX_HOME/AGENTS.md"
printf 'name = "personal-agent"\ndescription = "Keep me"\ndeveloper_instructions = "Do not remove me"\n' \
  > "$CODEX_HOME/agents/personal-agent.toml"
cat > "$CODEX_HOME/hooks.json" <<'JSON'
{
  "hooks": {
    "SessionStart": [
      {"hooks": [{"type": "command", "command": "echo existing"}]}
    ]
  },
  "userSetting": true
}
JSON

( cd "$PROJECT" && HOME="$HOME_DIR" CODEX_HOME="$CODEX_HOME" bash "$INSTALL" ) \
  > "$BOX/install.log" 2>&1

assert_eq "present" "$([ -f "$HOME_DIR/.agents/skills/build/SKILL.md" ] && echo present || echo missing)" \
  "install: canonical skills are available to Codex"
assert_eq "present" "$([ -f "$CODEX_HOME/AGENTS.md" ] && echo present || echo missing)" \
  "install: global AGENTS.md is created"
assert_file_contains "$CODEX_HOME/AGENTS.md" "# Personal Codex instructions" \
  "install: existing AGENTS content is preserved"
assert_file_contains "$CODEX_HOME/AGENTS.md" "Session Start Checklist" \
  "install: shared workflow rules are rendered"
assert_not_contains "$(cat "$CODEX_HOME/AGENTS.md")" "@.claude/project.md" \
  "install: Claude project import is not copied into Codex"
assert_not_contains "$(cat "$CODEX_HOME/AGENTS.md")" "@CLAUDE.local.md" \
  "install: Claude local import is not copied into Codex"
assert_eq "present" "$([ -f "$CODEX_HOME/agents/planner.toml" ] && echo present || echo missing)" \
  "install: canonical agents become Codex TOML"
assert_eq "present" "$([ -f "$CODEX_HOME/agents/personal-agent.toml" ] && echo present || echo missing)" \
  "install: unrelated personal agent is preserved"
assert_eq "present" "$([ -f "$CODEX_HOME/hooks/coding-agent-workflow-session-start.py" ] && echo present || echo missing)" \
  "install: SessionStart adapter is installed"
assert_contains "$(cat "$BOX/install.log")" "Review installed hooks with /hooks" \
  "install: hook trust remains an explicit user action"

if python3 - "$CODEX_HOME" "$REPO" <<'PY'
import json
import sys
import tomllib
from pathlib import Path

codex_home = Path(sys.argv[1])
repo = Path(sys.argv[2])
agents = sorted((codex_home / "agents").glob("*.toml"))
expected = sorted(p.stem for p in (repo / ".agents" / "agents").glob("*.md") if p.name != "README.md")
assert [p.stem for p in agents if p.stem != "personal-agent"] == expected
for path in agents:
    data = tomllib.loads(path.read_text())
    if path.stem != "personal-agent":
        assert {"name", "description", "developer_instructions"} <= data.keys(), path
hooks = json.loads((codex_home / "hooks.json").read_text())
assert hooks["userSetting"] is True
assert any("echo existing" in h.get("command", "") for g in hooks["hooks"]["SessionStart"] for h in g["hooks"])
for event in ("SessionStart", "PreCompact", "SessionEnd"):
    commands = [h["command"] for g in hooks["hooks"][event] for h in g["hooks"]]
    adapter_commands = [command for command in commands if "coding-agent-workflow" in command]
    assert len(adapter_commands) == 1, (event, commands)
PY
then
  :
else
  assert_eq "0" "1" "install: generated Codex configuration validates"
fi

cp "$CODEX_HOME/AGENTS.md" "$BOX/agents.before"
cp "$CODEX_HOME/hooks.json" "$BOX/hooks.before"
( cd "$PROJECT" && HOME="$HOME_DIR" CODEX_HOME="$CODEX_HOME" bash "$INSTALL" ) \
  > "$BOX/install-again.log" 2>&1
assert_files_identical "$BOX/agents.before" "$CODEX_HOME/AGENTS.md" \
  "install: global AGENTS rendering is idempotent"
assert_files_identical "$BOX/hooks.before" "$CODEX_HOME/hooks.json" \
  "install: hook registration is idempotent"

# Two env vars, each closing a way this assertion fails on something other than
# the Codex JSON envelope it is meant to check:
#   CCW_SESSION_GUARD=0 -- session-start.sh's double-invocation guard keys on
#     $PPID when the payload carries no session_id (this one does not), and its
#     sentinels live 300s in a shared TMPDIR. A recycled PID from any unrelated
#     recent invocation silently suppresses the banner, leaving an empty envelope.
#   PYTHONIOENCODING -- the banner carries box-drawing rules and emoji, and Codex
#     pipes this stdout, so a text-mode write encodes with the platform default
#     and emits nothing. Forcing it makes that a real pin on Linux CI, not just
#     on Windows.
HOOK_RESULT="$(printf '%s\n' '{"source":"startup"}' | HOME="$HOME_DIR" CODEX_HOME="$CODEX_HOME" \
  CCW_SESSION_GUARD=0 PYTHONIOENCODING=cp1252 python3 "$CODEX_HOME/hooks/coding-agent-workflow-session-start.py")"
if python3 - "$HOOK_RESULT" <<'PY'
import json
import sys
data = json.loads(sys.argv[1])
assert data["hookSpecificOutput"]["hookEventName"] == "SessionStart"
assert "additionalContext" in data["hookSpecificOutput"]
PY
then HOOK_JSON_OK="valid"; else HOOK_JSON_OK="invalid"; fi
# Counted on both paths. Asserting only inside `else` (the surrounding
# convention in this file) records nothing when the check passes, so the
# suite total silently moves depending on the result.
assert_eq "valid" "$HOOK_JSON_OK" "hook: SessionStart output validates as Codex JSON"

BAD="$BOX/bad-agents"
mkdir -p "$BAD"
printf '# malformed\n' > "$BAD/broken.md"
if python3 "$RENDERER" --agents "$BAD" "$BOX/bad-output" > "$BOX/bad.log" 2>&1; then
  assert_eq "failure" "success" "renderer: malformed agent input is rejected"
else
  assert_contains "$(cat "$BOX/bad.log")" "broken.md" \
    "renderer: malformed input identifies the source file"
fi

rm -rf "$BOX"
finish
