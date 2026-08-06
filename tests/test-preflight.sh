#!/usr/bin/env bash
# Verifies preflight reports each dependency and exits non-zero when Figma is unreachable.
set -uo pipefail
PASS=0; FAIL=0
check() { if eval "$2"; then echo "  PASS: $1"; PASS=$((PASS+1)); else echo "  FAIL: $1"; FAIL=$((FAIL+1)); fi; }

OUT="$(bash scripts/preflight.sh 2>&1)"

check "reports figma-cli presence" 'grep -q "PREFLIGHT: figma-cli" <<<"$OUT"'
check "reports figma desktop check" 'grep -q "PREFLIGHT: figma-desktop" <<<"$OUT"'
check "reports emil skills check"   'grep -q "PREFLIGHT: emil-skills" <<<"$OUT"'
check "manifest is valid json"      'node -e "JSON.parse(require(\"fs\").readFileSync(\".claude-plugin/plugin.json\",\"utf8\"))"'
check "manifest name is claude-design" 'node -e "const m=JSON.parse(require(\"fs\").readFileSync(\".claude-plugin/plugin.json\",\"utf8\"));process.exit(m.name===\"claude-design\"?0:1)"'

echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
