#!/usr/bin/env bash
# Runs every test suite. Exits non-zero if any fails.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
TOTAL_FAIL=0
TOTAL_CHECKS=0
for t in tests/test-*.sh; do
  echo ""
  echo "=== $t ==="
  OUT="$(bash "$t" 2>&1)"
  echo "$OUT"
  LAST="$(printf '%s\n' "$OUT" | tail -1)"
  N="$(printf '%s' "$LAST" | sed -n 's/^PASS=\([0-9]*\).*/\1/p')"
  [ -n "$N" ] && TOTAL_CHECKS=$((TOTAL_CHECKS + N))
  if printf '%s' "$LAST" | grep -q "FAIL=0"; then
    echo "--- $t OK"
  else
    echo "--- $t FAILED"
    TOTAL_FAIL=$((TOTAL_FAIL + 1))
  fi
done
echo ""
echo "$TOTAL_CHECKS checks across $(ls tests/test-*.sh | wc -l | tr -d ' ') suites"
if [ "$TOTAL_FAIL" -eq 0 ]; then
  echo "ALL SUITES PASSED"
else
  echo "$TOTAL_FAIL SUITE(S) FAILED"
fi
exit "$TOTAL_FAIL"
