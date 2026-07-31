#!/usr/bin/env bash
# Create an agent worktree that can actually run the test suite.
#
# A fresh `git worktree add` gives you tracked files and nothing else. Everything
# gitignored — node_modules, .env*, build caches — is absent. That matters more
# than it sounds: a suite that gates on `.env.test` will *skip* those tests in a
# bare worktree and report green. A worktree without this bootstrap produces
# false confidence, which is worse than no worktree at all.
#
# Usage:
#   scripts/bootstrap-worktree.sh <branch> [path]
#   scripts/bootstrap-worktree.sh --detach-head <path>   # for fixture regeneration
#
# Defaults path to ../<repo>-<branch-slug>.
set -euo pipefail

die() { printf 'bootstrap-worktree: %s\n' "$1" >&2; exit 1; }

[ $# -ge 1 ] || die "usage: bootstrap-worktree.sh <branch> [path] | --detach-head <path>"

git rev-parse --git-dir >/dev/null 2>&1 || die "not a git repository"
MAIN="$(git rev-parse --show-toplevel)"
REPO="$(basename "$MAIN")"

if [ "$1" = "--detach-head" ]; then
  [ $# -ge 2 ] || die "--detach-head requires a path"
  WT="$2"; DETACHED=1; BRANCH=""
else
  BRANCH="$1"; DETACHED=0
  slug="$(printf '%s' "$BRANCH" | tr '/' '-')"
  WT="${2:-$MAIN/../$REPO-$slug}"
fi

[ -e "$WT" ] && die "path already exists: $WT"

# --- create ------------------------------------------------------------------
if [ "$DETACHED" -eq 1 ]; then
  # Pinned to HEAD with no branch. This is the only safe tree for regenerating
  # committed fixtures: a dirty working tree bakes unrelated WIP into an
  # artefact that then fails only in CI.
  git worktree add --detach "$WT" HEAD >/dev/null
elif git show-ref --verify --quiet "refs/heads/$BRANCH"; then
  git worktree add "$WT" "$BRANCH" >/dev/null
else
  git worktree add -b "$BRANCH" "$WT" >/dev/null
fi
WT="$(cd "$WT" && pwd)"   # normalise before we link into it

# --- node_modules ------------------------------------------------------------
# Symlink rather than reinstall: saves minutes and disk, and guarantees both
# trees resolve identical dependency versions. Safe because the lockfile is
# tracked, so a worktree that changes deps changes the lockfile too — and that
# case wants its own install, see the warning below.
if [ -d "$MAIN/node_modules" ]; then
  ln -s "$MAIN/node_modules" "$WT/node_modules"
  echo "  linked  node_modules -> $MAIN/node_modules"
else
  echo "  skipped node_modules (absent in $MAIN; run your install in the worktree)"
fi

# --- gitignored config -------------------------------------------------------
# The whole reason this script exists. These are never inherited by a worktree.
copied=0
for f in "$MAIN"/.env "$MAIN"/.env.*; do
  [ -e "$f" ] || continue
  case "$(basename "$f")" in *.example|*.sample|*.template) continue ;; esac
  cp "$f" "$WT/" && copied=$((copied + 1))
done
if [ "$copied" -gt 0 ]; then
  echo "  copied  $copied env file(s)"
else
  echo "  WARNING no .env* found in $MAIN — if the suite gates on one, it will"
  echo "          silently skip those tests and report green."
fi

# --- report ------------------------------------------------------------------
cat <<EOF

worktree ready: $WT
$( [ "$DETACHED" -eq 1 ] && echo "  detached at HEAD $(git rev-parse --short HEAD)" || echo "  branch: $BRANCH" )

  cd $WT

Before trusting a green run, confirm the suite is not skipping gated tests —
count the tests, not the exit code.

If this worktree changes dependencies, replace the node_modules symlink with a
real install first; writing through the link mutates the parent's tree.

Remove when done:  git worktree remove $WT
EOF
