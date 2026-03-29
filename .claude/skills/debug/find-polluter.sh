#!/bin/bash
# find-polluter.sh — Find which test creates unwanted files/directories
#
# Usage: ./find-polluter.sh <target> <test-pattern>
# Example: ./find-polluter.sh '.git' 'src/**/*.test.ts'
#
# Runs tests one-by-one, checks if <target> appears after each test.
# Reports the first test that creates the pollution.

set -euo pipefail

TARGET="$1"
PATTERN="$2"

if [ -z "$TARGET" ] || [ -z "$PATTERN" ]; then
  echo "Usage: $0 <target-file-or-dir> <test-glob-pattern>"
  echo "Example: $0 '.git' 'src/**/*.test.ts'"
  exit 1
fi

# Collect test files
TEST_FILES=($(find . -path "./$PATTERN" 2>/dev/null || echo ""))
TOTAL=${#TEST_FILES[@]}

if [ "$TOTAL" -eq 0 ]; then
  echo "No test files found matching: $PATTERN"
  exit 1
fi

echo "Searching for polluter of '$TARGET' across $TOTAL test files..."

# Check for pre-existing pollution
if [ -e "$TARGET" ]; then
  echo "WARNING: '$TARGET' already exists. Remove it first for accurate results."
  exit 1
fi

for ((i=0; i<TOTAL; i++)); do
  FILE="${TEST_FILES[$i]}"
  echo -n "  [$((i+1))/$TOTAL] $FILE ... "

  # Run the test (suppress output)
  npm test -- "$FILE" > /dev/null 2>&1 || true

  # Check if pollution appeared
  if [ -e "$TARGET" ]; then
    echo "POLLUTER FOUND"
    echo ""
    echo "  Test file: $FILE"
    echo "  Created:   $TARGET"
    echo ""
    echo "  Investigate this test for side effects."
    exit 0
  fi

  echo "clean"
done

echo ""
echo "No polluter found. '$TARGET' was not created by any individual test."
