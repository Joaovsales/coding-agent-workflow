#!/bin/bash
# tests/run.sh — discover and run every tests/test-*.sh from the repo root.
# Each test file is a standalone script that sources tests/lib.sh and calls
# `finish`. Exit non-zero if any test file fails. No external dependencies.

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

total=0
failed=0

shopt -s nullglob
for test_file in tests/test-*.sh; do
  total=$((total + 1))
  printf '\n=== %s ===\n' "$test_file"
  if ! bash "$test_file"; then
    failed=$((failed + 1))
  fi
done

printf '\n========================================\n'
if [ "$total" -eq 0 ]; then
  printf 'RESULT: no test files found (tests/test-*.sh)\n'
  exit 1
fi
if [ "$failed" -gt 0 ]; then
  printf 'RESULT: %d/%d test files FAILED\n' "$failed" "$total"
  exit 1
fi
printf 'RESULT: all %d test files passed\n' "$total"
exit 0
