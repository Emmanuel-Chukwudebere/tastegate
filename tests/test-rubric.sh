#!/usr/bin/env bash
set -uo pipefail
PASS=0; FAIL=0
has() { if grep -qiF "$2" "$1" 2>/dev/null; then echo "  PASS: $1 has '$2'"; PASS=$((PASS+1)); else echo "  FAIL: $1 missing '$2'"; FAIL=$((FAIL+1)); fi; }

R=skills/design/RUBRIC.md
for d in Typography Palette Spacing Hierarchy Motion Accessibility Slop Breakpoint; do has "$R" "$d"; done
has "$R" "0-5"
has "$R" "evidence"
has "$R" "MOTION.md"
has "$R" "TYPOGRAPHY.md"
has "$R" "escalate"

S=skills/design/SLOP.md
has "$S" "#F4F1EA"
has "$S" "terracotta"
has "$S" "acid-green"
has "$S" "broadsheet"
has "$S" "purple gradient"
has "$S" "01 / 02 / 03"

F=skills/design/FIGMA-CLI.md
has "$F" 'flex="row'
has "$F" "p={24}"
has "$F" 'bg="#fff"'
has "$F" "rounded={16}"
has "$F" "never use"
has "$F" "eval"

echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
