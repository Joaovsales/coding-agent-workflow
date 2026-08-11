# tests/test-migrate-learning-store.sh — fixture-driven tests for
# scripts/migrate-learning-store.py, the standalone converter from the
# monolithic tasks/memory.md + tasks/lessons.md + tasks/bugs.md learning
# store to the typed tasks/solutions/<category>/<slug>.md store.
#
# Zero external dependencies beyond git + python. Builds throwaway fixture
# repos under a temp dir per scenario and cleans them up on exit.
. "$(dirname "$0")/lib.sh"

REPO="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$REPO/scripts/migrate-learning-store.py"

if command -v python3 >/dev/null 2>&1; then
  PY=python3
elif command -v python >/dev/null 2>&1; then
  PY=python
elif command -v py >/dev/null 2>&1; then
  PY=py
else
  printf '  FAIL no python interpreter found (python3/python/py)\n'
  exit 1
fi

TMP_DIRS=()
cleanup() {
  local d
  for d in "${TMP_DIRS[@]:-}"; do
    [ -n "$d" ] && rm -rf "$d"
  done
}
trap cleanup EXIT

new_fixture() {
  local d
  d="$(mktemp -d "${TMPDIR:-/tmp}/migrate-test.XXXXXX")"
  TMP_DIRS+=("$d")
  mkdir -p "$d/tasks"
  printf '%s' "$d"
}

git_init() {
  local d="$1"
  git -C "$d" init -q
  git -C "$d" config user.email "test@example.com"
  git -C "$d" config user.name "Test"
}

git_commit_all() {
  local d="$1"
  git -C "$d" add -A
  git -C "$d" commit -q -m "$2"
}

run_migrate() {
  "$PY" "$SCRIPT" "$@"
}

# ---------------------------------------------------------------------------
# 1. Absent inputs — nothing to migrate
# ---------------------------------------------------------------------------
F1="$(new_fixture)"
out1="$(run_migrate --repo "$F1" 2>&1)"
code1=$?
assert_eq "0" "$code1" "Scenario 1: absent inputs exits 0"
assert_contains "$out1" "Nothing to migrate" "Scenario 1: reports nothing to migrate"
assert_eq "no" "$([ -d "$F1/tasks/solutions" ] && echo yes || echo no)" \
  "Scenario 1: no tasks/solutions/ created"

# ---------------------------------------------------------------------------
# 2. 8-column bugs.md — fully mapped row
# ---------------------------------------------------------------------------
F2="$(new_fixture)"
cat > "$F2/tasks/bugs.md" <<'EOF'
# Bug Register

| ID | Date | Description | Root Cause | Fix | Files | Status | Regression Test |
|----|------|-------------|------------|-----|-------|--------|-----------------|
| BUG-1 | 2026-01-01 | Login fails on retry | Race condition in token refresh | Added mutex lock | src/auth.py | Fixed | tests/test-auth.sh |
EOF
out2="$(run_migrate --repo "$F2" --apply 2>&1)"
code2=$?
assert_eq "0" "$code2" "Scenario 2: 8-column bugs.md migration exits 0"
bugs2_agg="$(cat "$F2"/tasks/solutions/bugs/*.md 2>/dev/null)"
assert_contains "$bugs2_agg" 'root_cause: Race condition in token refresh' "Scenario 2: root_cause filled"
assert_contains "$bugs2_agg" 'resolution: Added mutex lock' "Scenario 2: resolution filled"
assert_contains "$bugs2_agg" '**ID**: BUG-1' "Scenario 2: unmapped ID column carried into body"
assert_contains "$bugs2_agg" '**Status**: Fixed' "Scenario 2: unmapped Status column carried into body"
assert_contains "$bugs2_agg" '**Regression Test**: tests/test-auth.sh' "Scenario 2: unmapped Regression Test column carried into body"
assert_not_contains "$bugs2_agg" 'needs_review' "Scenario 2: fully-mapped row is not flagged needs_review"

# ---------------------------------------------------------------------------
# 3. 5-column bugs.md — needs_review stamped
# ---------------------------------------------------------------------------
F3="$(new_fixture)"
cat > "$F3/tasks/bugs.md" <<'EOF'
# Bug Register

| ID | Date | Description | Status | Notes |
|----|------|-------------|--------|-------|
| BUG-2 | 2026-01-02 | Crash on empty input | Open | Needs investigation |
EOF
out3="$(run_migrate --repo "$F3" --apply 2>&1)"
code3=$?
assert_eq "0" "$code3" "Scenario 3: 5-column bugs.md migration exits 0"
bugs3_agg="$(cat "$F3"/tasks/solutions/bugs/*.md 2>/dev/null)"
assert_contains "$bugs3_agg" 'needs_review: true' "Scenario 3: needs_review stamped"
assert_contains "$bugs3_agg" 'root_cause: ""' "Scenario 3: root_cause empty"
assert_contains "$bugs3_agg" 'resolution: ""' "Scenario 3: resolution empty"
assert_contains "$bugs3_agg" '**Notes**: Needs investigation' "Scenario 3: Notes column carried into body"
assert_contains "$out3" "needs_review" "Scenario 3: needs_review listed in report output"

# ---------------------------------------------------------------------------
# 4. Free-form lessons.md — blank-line blocks, all needs_review
# ---------------------------------------------------------------------------
F4="$(new_fixture)"
cat > "$F4/tasks/lessons.md" <<'EOF'
Always write a regression test before closing a bug. It prevents silent reintroduction.

Prefer composition over inheritance when extending exporters.
EOF
out4="$(run_migrate --repo "$F4" --apply 2>&1)"
code4=$?
assert_eq "0" "$code4" "Scenario 4: lessons.md migration exits 0"
lessons4_files="$(ls "$F4"/tasks/solutions/patterns/*.md 2>/dev/null | wc -l)"
assert_eq "2" "$lessons4_files" "Scenario 4: two blocks split into two documents"
lessons4_agg="$(cat "$F4"/tasks/solutions/patterns/*.md 2>/dev/null)"
assert_contains "$lessons4_agg" 'Always write a regression test' "Scenario 4: first block content present"
assert_contains "$lessons4_agg" 'Prefer composition over inheritance' "Scenario 4: second block content present"
review_count4="$(grep -l 'needs_review: true' "$F4"/tasks/solutions/patterns/*.md 2>/dev/null | wc -l)"
assert_eq "2" "$review_count4" "Scenario 4: both blocks flagged needs_review"

# ---------------------------------------------------------------------------
# 5. Slug collision — numeric suffix
# ---------------------------------------------------------------------------
F5="$(new_fixture)"
cat > "$F5/tasks/bugs.md" <<'EOF'
# Bug Register

| ID | Date | Description | Root Cause | Fix | Files | Status | Regression Test |
|----|------|-------------|------------|-----|-------|--------|-----------------|
| BUG-3 | 2026-01-03 | Duplicate error | First cause | First fix | src/a.py | Fixed | tests/a.sh |
| BUG-4 | 2026-01-04 | Duplicate error | Second cause | Second fix | src/b.py | Fixed | tests/b.sh |
EOF
out5="$(run_migrate --repo "$F5" --apply 2>&1)"
code5=$?
assert_eq "0" "$code5" "Scenario 5: slug collision migration exits 0"
assert_eq "yes" "$([ -f "$F5/tasks/solutions/bugs/duplicate-error.md" ] && echo yes || echo no)" \
  "Scenario 5: first document uses base slug"
assert_eq "yes" "$([ -f "$F5/tasks/solutions/bugs/duplicate-error-2.md" ] && echo yes || echo no)" \
  "Scenario 5: second document gets -2 suffix"

# ---------------------------------------------------------------------------
# 6. Missing date, non-git fixture — date_source: today
# ---------------------------------------------------------------------------
F6="$(new_fixture)"
cat > "$F6/tasks/lessons.md" <<'EOF'
A single unsplittable lesson block with no heading and no blank-line breaks
still becomes exactly one document.
EOF
out6="$(run_migrate --repo "$F6" --apply 2>&1)"
code6=$?
assert_eq "0" "$code6" "Scenario 6: non-git lessons.md migration exits 0"
lessons6_agg="$(cat "$F6"/tasks/solutions/patterns/*.md 2>/dev/null)"
assert_contains "$lessons6_agg" 'date_source: today' "Scenario 6: date_source recorded as today in non-git fixture"

# ---------------------------------------------------------------------------
# 7. Re-run idempotency
# ---------------------------------------------------------------------------
F7="$(new_fixture)"
cat > "$F7/tasks/bugs.md" <<'EOF'
# Bug Register

| ID | Date | Description | Root Cause | Fix | Files | Status | Regression Test |
|----|------|-------------|------------|-----|-------|--------|-----------------|
| BUG-5 | 2026-01-05 | Idempotency check | Some cause | Some fix | src/c.py | Fixed | tests/c.sh |
EOF
run_migrate --repo "$F7" --apply >/dev/null 2>&1
listing_before="$(cd "$F7" && find . -type f | sort)"
out7b="$(run_migrate --repo "$F7" --apply 2>&1)"
code7b=$?
listing_after="$(cd "$F7" && find . -type f | sort)"
assert_eq "0" "$code7b" "Scenario 7: second --apply run exits 0"
assert_contains "$out7b" "Nothing to migrate" "Scenario 7: second run reports nothing to migrate"
assert_eq "$listing_before" "$listing_after" "Scenario 7: second run changes nothing on disk"

# ---------------------------------------------------------------------------
# 8. Dirty-tree refusal
# ---------------------------------------------------------------------------
F8="$(new_fixture)"
cat > "$F8/tasks/bugs.md" <<'EOF'
# Bug Register

| ID | Date | Description | Root Cause | Fix | Files | Status | Regression Test |
|----|------|-------------|------------|-----|-------|--------|-----------------|
| BUG-6 | 2026-01-06 | Dirty tree check | Some cause | Some fix | src/d.py | Fixed | tests/d.sh |
EOF
git_init "$F8"
git_commit_all "$F8" "init"
printf 'scratch\n' > "$F8/scratch.txt"
out8a="$(run_migrate --repo "$F8" --apply 2>&1)"
code8a=$?
assert_eq "1" "$code8a" "Scenario 8: dirty tree without --force exits non-zero"
assert_eq "no" "$([ -d "$F8/tasks/solutions" ] && echo yes || echo no)" \
  "Scenario 8: dirty tree without --force writes nothing"
out8b="$(run_migrate --repo "$F8" --apply --force 2>&1)"
code8b=$?
assert_eq "0" "$code8b" "Scenario 8: dirty tree with --force exits 0"
assert_eq "yes" "$([ -d "$F8/tasks/solutions/bugs" ] && echo yes || echo no)" \
  "Scenario 8: dirty tree with --force proceeds and writes"

# ---------------------------------------------------------------------------
# 9. Existing tasks/project-context.md — conflict
# ---------------------------------------------------------------------------
F9="$(new_fixture)"
printf 'EXISTING PROJECT CONTEXT MARKER\n' > "$F9/tasks/project-context.md"
cat > "$F9/tasks/memory.md" <<'EOF'
# Project Memory

## Project Context

NEW CONTEXT FROM MEMORY

## Architecture Decisions

| Decision | Rationale |
|----------|-----------|
| Use SQLite for storage | Simplicity for small datasets |
EOF
out9="$(run_migrate --repo "$F9" --apply 2>&1)"
code9=$?
assert_eq "0" "$code9" "Scenario 9: project-context conflict still exits 0"
assert_contains "$out9" "CONFLICT" "Scenario 9: conflict named in report"
assert_file_contains "$F9/tasks/project-context.md" "EXISTING PROJECT CONTEXT MARKER" \
  "Scenario 9: original project-context.md untouched"
assert_file_contains "$F9/tasks/project-context.migrated.md" "NEW CONTEXT FROM MEMORY" \
  "Scenario 9: conflicting content written to .migrated.md"

# ---------------------------------------------------------------------------
# 10. Unrecognized ## section — archived verbatim, reported unmigrated
# ---------------------------------------------------------------------------
F10="$(new_fixture)"
cat > "$F10/tasks/memory.md" <<'EOF'
# Project Memory

## Random Notes

Some content nobody mapped a destination for.

## Architecture Decisions

| Decision | Rationale |
|----------|-----------|
| Adopt trunk-based development | Reduces merge conflicts |
EOF
out10="$(run_migrate --repo "$F10" --apply 2>&1)"
code10=$?
assert_eq "0" "$code10" "Scenario 10: unrecognized section still exits 0"
assert_contains "$out10" "UNMIGRATED SECTION" "Scenario 10: unrecognized section flagged"
assert_contains "$out10" "Random Notes" "Scenario 10: unrecognized section named"
assert_eq "yes" "$(find "$F10/tasks/archive" -name memory.md 2>/dev/null | grep -q . && echo yes || echo no)" \
  "Scenario 10: source file archived despite unrecognized section"

# ---------------------------------------------------------------------------
# 11. Dry-run default — writes nothing
# ---------------------------------------------------------------------------
F11="$(new_fixture)"
cat > "$F11/tasks/memory.md" <<'EOF'
# Project Memory

## Architecture Decisions

| Decision | Rationale |
|----------|-----------|
| Spec before code | Prevents scope creep |
EOF
out11="$(run_migrate --repo "$F11" 2>&1)"
code11=$?
assert_eq "0" "$code11" "Scenario 11: dry run exits 0"
assert_contains "$out11" "WOULD WRITE" "Scenario 11: dry run names target documents"
assert_contains "$out11" "tasks/solutions/architecture/" "Scenario 11: dry run names the target path"
assert_eq "no" "$([ -d "$F11/tasks/solutions" ] && echo yes || echo no)" \
  "Scenario 11: dry run creates no tasks/solutions/"
assert_eq "yes" "$([ -f "$F11/tasks/memory.md" ] && echo yes || echo no)" \
  "Scenario 11: dry run leaves source file in place"

# ---------------------------------------------------------------------------
# 12. Archive on --apply
# ---------------------------------------------------------------------------
F12="$(new_fixture)"
cat > "$F12/tasks/memory.md" <<'EOF'
# Project Memory

## Architecture Decisions

| Decision | Rationale |
|----------|-----------|
| Spec before code | Prevents scope creep |
EOF
out12="$(run_migrate --repo "$F12" --apply 2>&1)"
code12=$?
assert_eq "0" "$code12" "Scenario 12: --apply exits 0"
assert_eq "no" "$([ -f "$F12/tasks/memory.md" ] && echo yes || echo no)" \
  "Scenario 12: original memory.md gone from tasks/"
assert_eq "yes" "$(find "$F12/tasks/archive" -name memory.md 2>/dev/null | grep -q . && echo yes || echo no)" \
  "Scenario 12: original memory.md moved under tasks/archive/<stamp>/"

# ---------------------------------------------------------------------------
# 13. Full memory.md conversion — all five section kinds
# ---------------------------------------------------------------------------
F13="$(new_fixture)"
cat > "$F13/tasks/memory.md" <<'EOF'
# Project Memory

## Project Context

Demo purpose text for fixture testing.

## Architecture Decisions

| Decision | Rationale |
|----------|-----------|
| Use SQLite for storage | Simplicity for small datasets |
| Adopt trunk-based development | Reduces merge conflicts |

## Patterns & Lessons

### Validate inputs at the boundary
**Context**: Any function accepting external input.
**Pattern**: Validate and normalize at the edge, trust internally after.
**Evidence**: A malformed payload crashed the parser mid-pipeline.

## Session History

### [2026-05-01] — Fixture migration dry run
- Key changes: Added fixture generator for migration tests.
- Pattern: Prefer table-driven fixtures over ad hoc string building for parser tests.
- Pattern: Always assert on aggregated directory content instead of predicted slugs.
- Lessons added: 2 patterns above
EOF
out13="$(run_migrate --repo "$F13" --apply 2>&1)"
code13=$?
assert_eq "0" "$code13" "Scenario 13: full memory.md conversion exits 0"

assert_file_contains "$F13/tasks/project-context.md" "Demo purpose text for fixture testing." \
  "Scenario 13: Project Context migrated to tasks/project-context.md"

arch13_agg="$(cat "$F13"/tasks/solutions/architecture/*.md 2>/dev/null)"
assert_contains "$arch13_agg" "Use SQLite for storage" "Scenario 13: first architecture row migrated"
assert_contains "$arch13_agg" "Adopt trunk-based development" "Scenario 13: second architecture row migrated"
arch13_review_count="$(grep -l 'needs_review: true' "$F13"/tasks/solutions/architecture/*.md 2>/dev/null | wc -l)"
assert_eq "2" "$arch13_review_count" "Scenario 13: architecture rows flagged needs_review"

pattern13_entry_file="$(grep -l 'Validate and normalize at the edge' "$F13"/tasks/solutions/patterns/*.md 2>/dev/null | head -n1)"
assert_eq "yes" "$([ -n "$pattern13_entry_file" ] && echo yes || echo no)" \
  "Scenario 13: Patterns & Lessons entry migrated to patterns/"
if [ -n "$pattern13_entry_file" ]; then
  assert_not_contains "$(cat "$pattern13_entry_file")" "needs_review" \
    "Scenario 13: Patterns & Lessons entry NOT flagged needs_review (explicit applies_when)"
fi

pattern13_bullet1_file="$(grep -l 'Prefer table-driven fixtures' "$F13"/tasks/solutions/patterns/*.md 2>/dev/null | head -n1)"
pattern13_bullet2_file="$(grep -l 'Always assert on aggregated directory' "$F13"/tasks/solutions/patterns/*.md 2>/dev/null | head -n1)"
assert_eq "yes" "$([ -n "$pattern13_bullet1_file" ] && echo yes || echo no)" \
  "Scenario 13: first leaked Pattern bullet extracted to its own document"
assert_eq "yes" "$([ -n "$pattern13_bullet2_file" ] && echo yes || echo no)" \
  "Scenario 13: second leaked Pattern bullet extracted to its own document"
if [ -n "$pattern13_bullet1_file" ]; then
  assert_file_contains "$pattern13_bullet1_file" "needs_review: true" \
    "Scenario 13: first extracted bullet flagged needs_review"
fi
if [ -n "$pattern13_bullet2_file" ]; then
  assert_file_contains "$pattern13_bullet2_file" "needs_review: true" \
    "Scenario 13: second extracted bullet flagged needs_review"
fi

assert_file_contains "$F13/tasks/history.md" "Fixture migration dry run" \
  "Scenario 13: session history narrative preserved in tasks/history.md"
assert_file_contains "$F13/tasks/history.md" "Prefer table-driven fixtures over ad hoc string building" \
  "Scenario 13: first leaked bullet still present verbatim in tasks/history.md"
assert_file_contains "$F13/tasks/history.md" "Always assert on aggregated directory content instead of predicted slugs" \
  "Scenario 13: second leaked bullet still present verbatim in tasks/history.md"
history13_content="$(cat "$F13/tasks/history.md")"
extracted_link_count="$(printf '%s' "$history13_content" | grep -c '(extracted: tasks/solutions/patterns/')"
assert_eq "2" "$extracted_link_count" "Scenario 13: both leaked bullets cross-link to their extracted documents"

finish
