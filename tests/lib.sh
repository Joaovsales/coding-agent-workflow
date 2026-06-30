# tests/lib.sh — minimal zero-dependency assertion helpers.
# Source this from a test-*.sh script, call assertions, then call `finish`.
# No external deps: pure bash + coreutils (grep). Works in any POSIX-ish shell.

_TESTS=0
_FAILS=0

# assert_contains <haystack> <needle> <message>
assert_contains() {
  _TESTS=$((_TESTS + 1))
  case "$1" in
    *"$2"*) printf '  ok   %s\n' "$3" ;;
    *) _FAILS=$((_FAILS + 1)); printf '  FAIL %s\n       expected to contain: %s\n' "$3" "$2" ;;
  esac
}

# assert_not_contains <haystack> <needle> <message>
assert_not_contains() {
  _TESTS=$((_TESTS + 1))
  case "$1" in
    *"$2"*) _FAILS=$((_FAILS + 1)); printf '  FAIL %s\n       expected NOT to contain: %s\n' "$3" "$2" ;;
    *) printf '  ok   %s\n' "$3" ;;
  esac
}

# assert_file_contains <file> <literal-needle> <message>
assert_file_contains() {
  _TESTS=$((_TESTS + 1))
  if [ -f "$1" ] && grep -qF -- "$2" "$1"; then
    printf '  ok   %s\n' "$3"
  else
    _FAILS=$((_FAILS + 1)); printf '  FAIL %s\n       file %s missing or lacks: %s\n' "$3" "$1" "$2"
  fi
}

# assert_eq <expected> <actual> <message>
assert_eq() {
  _TESTS=$((_TESTS + 1))
  if [ "$1" = "$2" ]; then
    printf '  ok   %s\n' "$3"
  else
    _FAILS=$((_FAILS + 1)); printf '  FAIL %s\n       expected: %s\n       actual:   %s\n' "$3" "$1" "$2"
  fi
}

# assert_files_identical <file-a> <file-b> <message>
assert_files_identical() {
  _TESTS=$((_TESTS + 1))
  if [ -f "$1" ] && [ -f "$2" ] && diff -q "$1" "$2" >/dev/null 2>&1; then
    printf '  ok   %s\n' "$3"
  else
    _FAILS=$((_FAILS + 1)); printf '  FAIL %s\n       files differ or missing: %s vs %s\n' "$3" "$1" "$2"
  fi
}

# finish — report and exit non-zero if any assertion failed.
finish() {
  if [ "$_FAILS" -gt 0 ]; then
    printf '  -> %d/%d assertions FAILED\n' "$_FAILS" "$_TESTS"
    exit 1
  fi
  printf '  -> %d assertions passed\n' "$_TESTS"
  exit 0
}
