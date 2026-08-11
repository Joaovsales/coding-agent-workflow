#!/bin/bash
# tests/test-solutions-schema.sh — validates typed learning store documents
# (tasks/solutions/<category>/<slug>.md) against the schema in
# tasks/solutions/README.md: required frontmatter, problem_type enum, category
# map, track-required fields, and no dates in filenames.
# Self-tests the validator against bad fixtures, then validates the real store.
set -uo pipefail
cd "$(dirname "$0")/.."
source tests/lib.sh

# validate_doc <file> — print one violation per line; silent when valid.
validate_doc() {
  local f="$1" base fm pt cat track dir key
  base="$(basename "$f" .md)"
  case "$base" in
    *[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]*|[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]*)
      echo "$f: date in filename (dates belong in frontmatter)" ;;
  esac
  fm="$(awk 'NR==1 && $0!="---"{exit} NR>1 && $0=="---"{exit} NR>1{print}' "$f")"
  if [ -z "$fm" ]; then echo "$f: missing frontmatter block"; return; fi
  printf '%s\n' "$fm" | grep -Eq '^title: *[^ ]'  || echo "$f: missing title"
  printf '%s\n' "$fm" | grep -Eq '^module: *[^ ]' || echo "$f: missing module"
  printf '%s\n' "$fm" | grep -Eq '^date: *[0-9]{4}-[0-9]{2}-[0-9]{2}' \
    || echo "$f: missing or malformed date (YYYY-MM-DD)"
  printf '%s\n' "$fm" | grep -Eq '^tags: *\[[^]]+\]' || echo "$f: missing or empty tags"
  pt="$(printf '%s\n' "$fm" | sed -n 's/^problem_type: *//p' | head -1)"
  case "$pt" in
    bug|build-failure|test-failure|runtime-error) cat=bugs;        track=bug ;;
    performance)                                  cat=performance; track=bug ;;
    security)                                     cat=security;    track=bug ;;
    architecture-decision)                        cat=architecture; track=knowledge ;;
    pattern)                                      cat=patterns;    track=knowledge ;;
    convention)                                   cat=conventions; track=knowledge ;;
    tooling)                                      cat=tooling;     track=knowledge ;;
    process)                                      cat=process;     track=knowledge ;;
    *) echo "$f: unknown problem_type '$pt'"; return ;;
  esac
  dir="$(basename "$(dirname "$f")")"
  [ "$dir" = "$cat" ] || echo "$f: category dir '$dir' does not match problem_type '$pt' (expected $cat)"
  if [ "$track" = bug ]; then
    for key in symptoms root_cause resolution; do
      printf '%s\n' "$fm" | grep -q "^$key:" || echo "$f: bug track missing $key"
    done
  else
    printf '%s\n' "$fm" | grep -q '^applies_when:' || echo "$f: knowledge track missing applies_when"
  fi
}

# validate_store <dir> — validate every category document under a store root.
validate_store() {
  local f
  for f in "$1"/*/*.md; do
    [ -e "$f" ] || continue
    validate_doc "$f"
  done
}

# --- Self-test: the validator must reject each violation kind ---------------
FIX="$(mktemp -d "${TMPDIR:-/tmp}/solutions-schema.XXXXXX")"
trap 'rm -rf "$FIX"' EXIT
mkdir -p "$FIX/patterns" "$FIX/bugs"

cat > "$FIX/patterns/unknown-type.md" <<'EOF'
---
title: Unknown type fixture
date: 2026-08-11
problem_type: banana
module: tests
tags: [fixture]
applies_when: never
---
Body.
EOF

cat > "$FIX/bugs/missing-root-cause.md" <<'EOF'
---
title: Bug missing track field
date: 2026-08-11
problem_type: bug
module: tests
tags: [fixture]
symptoms: it broke
resolution: restarted
---
Body.
EOF

cat > "$FIX/patterns/missing-applies-when.md" <<'EOF'
---
title: Knowledge missing track field
date: 2026-08-11
problem_type: pattern
module: tests
tags: [fixture]
---
Body.
EOF

cat > "$FIX/patterns/2026-08-11-dated-name.md" <<'EOF'
---
title: Dated filename fixture
date: 2026-08-11
problem_type: pattern
module: tests
tags: [fixture]
applies_when: never
---
Body.
EOF

cat > "$FIX/patterns/valid-doc.md" <<'EOF'
---
title: Valid knowledge doc
date: 2026-08-11
problem_type: pattern
module: tests
tags: [fixture, schema]
applies_when: validating this test
---
Body.
EOF

cat > "$FIX/bugs/valid-flagged-doc.md" <<'EOF'
---
title: Flagged bug doc with empty track values
date: 2026-08-11
problem_type: bug
module: tests
tags: [fixture, migrated]
symptoms: intermittent failure
root_cause:
resolution:
needs_review: true
---
Body.
EOF

VIOLATIONS="$(validate_store "$FIX")"
assert_contains "$VIOLATIONS" "unknown problem_type 'banana'" \
  "validator rejects unknown problem_type"
assert_contains "$VIOLATIONS" "bug track missing root_cause" \
  "validator rejects bug doc missing a track-required field"
assert_contains "$VIOLATIONS" "knowledge track missing applies_when" \
  "validator rejects knowledge doc missing applies_when"
assert_contains "$VIOLATIONS" "date in filename" \
  "validator rejects a date in the filename"
assert_not_contains "$VIOLATIONS" "valid-doc.md" \
  "validator passes a valid knowledge doc"
assert_not_contains "$VIOLATIONS" "valid-flagged-doc.md" \
  "validator passes a needs_review doc with empty track values"

# --- Real store: every document in tasks/solutions/ must validate -----------
if [ -d tasks/solutions ]; then
  REAL="$(validate_store tasks/solutions)"
  assert_eq "" "$REAL" "real store documents all validate (violations: ${REAL:-none})"
  assert_file_contains tasks/solutions/README.md "problem_type" \
    "store README documents the schema"
fi

finish
