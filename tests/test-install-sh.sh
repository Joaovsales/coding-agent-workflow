# tests/test-install-sh.sh — install.sh must never destroy user skills, and must
# not write invalid keys into ~/.claude/settings.json.
#
# The functional cases run install.sh for real against a throwaway $HOME and a
# throwaway CWD, so nothing touches the developer's own ~/.claude.
. "$(dirname "$0")/lib.sh"

REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"

INSTALL="$REPO/install.sh"
USER_SKILL="my-personal-skill"

# ── Static checks ────────────────────────────────────────────────────────────
src="$(cat "$INSTALL")"

# Match live commands only — prose mentioning the old bug must not trip these.
count_matching() { grep -c -E "$1" "$INSTALL" 2>/dev/null || true; }

assert_eq "0" "$(count_matching '^[[:space:]]*rm -rf "\$CLAUDE_HOME/skills"[[:space:]]*$')" \
  "install.sh: no live 'rm -rf ~/.claude/skills' command"
assert_contains "$src" 'cp -r "$REPO_DIR/.claude/skills/." "$CLAUDE_HOME/skills/"' \
  "install.sh: copies skills INTO the dir (non-destructive)"
assert_contains "$src" "--prune-skills" \
  "install.sh: pruning is behind an explicit --prune-skills flag"

# The invalid key is a Claude Code concern only. Pi has its own schema where a
# `skills` array IS valid, so that write must survive.
assert_eq "0" "$(count_matching 'jq .*\.skills.*\$SETTINGS_FILE')" \
  "install.sh: never writes a 'skills' key into ~/.claude/settings.json"
assert_eq "0" "$(count_matching 'jq .*\.skills.*> /tmp/settings_tmp.json')" \
  "install.sh: no leftover Claude-side skills-path jq write"
assert_contains "$src" '$PI_SETTINGS' \
  "install.sh: Pi skill-path configuration retained"

# ── Functional harness ───────────────────────────────────────────────────────
# Run install.sh with an isolated HOME. Plants a user-owned skill first so we can
# prove it survives. Echoes the temp HOME path; caller inspects it.
run_install() {
  local confirm="$1"; shift
  local sandbox home
  sandbox="$(mktemp -d)"
  home="$sandbox/home"
  mkdir -p "$home/.claude/skills/$USER_SKILL"
  printf 'name: %s\n' "$USER_SKILL" > "$home/.claude/skills/$USER_SKILL/SKILL.md"
  # Empty confirm means a closed stdin (true EOF), not a blank line.
  local stdin=/dev/null
  if [ -n "$confirm" ]; then
    stdin="$sandbox/stdin.txt"
    printf '%s\n' "$confirm" > "$stdin"
  fi
  # Run from inside the sandbox: install.sh's optional graphify step writes to CWD.
  ( cd "$sandbox" && HOME="$home" bash "$INSTALL" "$@" ) > "$sandbox/out.log" 2>&1 < "$stdin"
  printf '%s\n' "$sandbox"
}

exists() { [ -e "$1" ] && echo present || echo missing; }

# ── Case 1: default run is additive ──────────────────────────────────────────
box="$(run_install "")"
h="$box/home"

assert_eq "present" "$(exists "$h/.claude/skills/$USER_SKILL/SKILL.md")" \
  "default run: user's own skill survives installation"
assert_eq "present" "$(exists "$h/.claude/skills/build/SKILL.md")" \
  "default run: template skills are installed"
assert_eq "present" "$(exists "$h/.claude/settings.json")" \
  "default run: settings.json created"
assert_not_contains "$(cat "$h/.claude/settings.json")" '"skills"' \
  "default run: settings.json contains no invalid 'skills' key"
assert_file_contains "$h/.claude/settings.json" "session-start.sh" \
  "default run: SessionStart hook still registered"
rm -rf "$box"

# ── Case 2: retired template skills also survive a default run ───────────────
# A skill the template dropped (e.g. deslop) is indistinguishable from a personal
# skill, so the additive default must keep it too.
box="$(run_install "")"
h="$box/home"
mkdir -p "$h/.claude/skills/retired-skill"
touch "$h/.claude/skills/retired-skill/SKILL.md"
( cd "$box" && HOME="$h" bash "$INSTALL" ) > "$box/out2.log" 2>&1 < /dev/null
assert_eq "present" "$(exists "$h/.claude/skills/retired-skill/SKILL.md")" \
  "re-run: retired template skill is not silently removed"
assert_contains "$(cat "$box/out2.log")" "--prune-skills" \
  "re-run: reports kept non-template entries and how to prune them"
rm -rf "$box"

# ── Case 3: --prune-skills refuses without confirmation ──────────────────────
box="$(run_install "" --prune-skills)"
h="$box/home"
assert_eq "present" "$(exists "$h/.claude/skills/$USER_SKILL/SKILL.md")" \
  "--prune-skills with no confirmation (EOF): nothing deleted"
assert_contains "$(cat "$box/out.log")" "$USER_SKILL" \
  "--prune-skills: lists what it would delete before asking"
rm -rf "$box"

box="$(run_install "no" --prune-skills)"
h="$box/home"
assert_eq "present" "$(exists "$h/.claude/skills/$USER_SKILL/SKILL.md")" \
  "--prune-skills answered 'no': nothing deleted"
rm -rf "$box"

# ── Case 4: --prune-skills deletes only on explicit confirmation ─────────────
box="$(run_install "delete" --prune-skills)"
h="$box/home"
assert_eq "missing" "$(exists "$h/.claude/skills/$USER_SKILL")" \
  "--prune-skills confirmed: non-template entry deleted"
assert_eq "present" "$(exists "$h/.claude/skills/build/SKILL.md")" \
  "--prune-skills confirmed: template skills untouched"
rm -rf "$box"

# ── Case 5: unknown flags are rejected, not ignored ──────────────────────────
box="$(mktemp -d)"
( cd "$box" && HOME="$box/home" bash "$INSTALL" --bogus ) > "$box/out.log" 2>&1 < /dev/null
assert_eq "1" "$?" "unknown flag: exits non-zero instead of installing"
rm -rf "$box"

finish
