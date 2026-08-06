#!/usr/bin/env bash
# Asserts the standards files contain every exact threshold the rubric scores against.
set -uo pipefail
PASS=0; FAIL=0
has() { if grep -qF "$2" "$1" 2>/dev/null; then echo "  PASS: $1 has '$2'"; PASS=$((PASS+1)); else echo "  FAIL: $1 missing '$2'"; FAIL=$((FAIL+1)); fi; }

M=skills/design/MOTION.md
has "$M" "cubic-bezier(0.23, 1, 0.32, 1)"
has "$M" "cubic-bezier(0.77, 0, 0.175, 1)"
has "$M" "cubic-bezier(0.32, 0.72, 0, 1)"
has "$M" "300ms"
has "$M" "0.11"
has "$M" "scale(0.97)"
has "$M" "prefers-reduced-motion"
has "$M" "(hover: hover) and (pointer: fine)"
has "$M" "transform"
has "$M" "opacity"

T=skills/design/TYPOGRAPHY.md
has "$T" "65"
has "$T" "tabular"
has "$T" "letter-spacing"
has "$T" "fallback"

echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
