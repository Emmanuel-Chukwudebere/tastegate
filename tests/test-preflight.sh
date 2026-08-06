#!/usr/bin/env bash
# Verifies preflight reports each dependency and exits non-zero when Figma is unreachable.
set -uo pipefail
PASS=0; FAIL=0
check() { if eval "$2"; then echo "  PASS: $1"; PASS=$((PASS+1)); else echo "  FAIL: $1"; FAIL=$((FAIL+1)); fi; }

OUT="$(bash scripts/preflight.sh 2>&1)"
RC=$?

check "reports figma-cli presence" 'grep -q "PREFLIGHT: figma-cli" <<<"$OUT"'
check "reports figma desktop check" 'grep -q "PREFLIGHT: figma-desktop" <<<"$OUT"'
check "reports emil skills check"   'grep -q "PREFLIGHT: emil-skills" <<<"$OUT"'
check "manifest is valid json"      'node -e "JSON.parse(require(\"fs\").readFileSync(\".claude-plugin/plugin.json\",\"utf8\"))"'
check "manifest name is claude-design" 'node -e "const m=JSON.parse(require(\"fs\").readFileSync(\".claude-plugin/plugin.json\",\"utf8\"));process.exit(m.name===\"claude-design\"?0:1)"'

# Test exit code: preflight must exit non-zero when figma-cli is absent
TMPDIR_STUB="$(mktemp -d)"
trap "rm -rf \"$TMPDIR_STUB\"" EXIT
OUT_NO_CLI="$(PATH="$TMPDIR_STUB:/usr/bin:/bin" bash scripts/preflight.sh 2>&1)"
RC_NO_CLI=$?
check "exits non-zero when figma-cli absent" '[ "$RC_NO_CLI" -ne 0 ]'

# Test exit code: preflight should match environment state for hard dependencies
# If figma-cli status succeeds, exit should be 0; if it fails, exit should be non-zero
if figma-cli status >/dev/null 2>&1; then
  check "exits 0 when hard deps satisfied" '[ "$RC" -eq 0 ]'
else
  check "exits non-zero when hard deps missing" '[ "$RC" -ne 0 ]'
fi

echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
