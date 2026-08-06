#!/usr/bin/env bash
set -uo pipefail
PASS=0; FAIL=0
has() { if grep -qiF "$2" "$1" 2>/dev/null; then echo "  PASS: $1 has '$2'"; PASS=$((PASS+1)); else echo "  FAIL: $1 missing '$2'"; FAIL=$((FAIL+1)); fi; }

F=skills/ship/FRAMEWORKS.md
for t in "Default target is **React**" \
         '| Vue | same token variables | native `<Transition>`' \
         "| Svelte | same token variables | native transitions, same curves |" \
         '| React Native | `StyleSheet` derived from the same tokens |' \
         "| Plain HTML | CSS custom properties | CSS transitions |"; do has "$F" "$t"; done
has "$F" "Reanimated, curves ported to its easing API"
has "$F" "Framer Motion only for spring physics, drag, or layout morphing"
has "$F" "**Detect before asking.**"
has "$F" "introduce a second styling paradigm into a project that has one"

C=skills/design/RUNTIMES.md
has "$C" 'Dispatch a sub-agent | `Agent` tool'
has "$C" 'Read an image | `Read` tool with the PNG path'
has "$C" 'Dispatch with `model: "sonnet"` for the QA pass'
has "$C" "runtime does not need to degrade"

echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
