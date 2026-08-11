#!/usr/bin/env bash
set -uo pipefail
PASS=0; FAIL=0
has() { if grep -qiF "$2" "$1" 2>/dev/null; then echo "  PASS: $(basename $1) has '$2'"; PASS=$((PASS+1)); else echo "  FAIL: $(basename $1) missing '$2'"; FAIL=$((FAIL+1)); fi; }
cnt0() { local n; n=$(grep -cE "$2" "$1" 2>/dev/null || true); if [ "${n:-0}" -eq 0 ]; then echo "  PASS: $(basename $1) has no /$2/"; PASS=$((PASS+1)); else echo "  FAIL: $(basename $1) has $n match(es) for /$2/"; FAIL=$((FAIL+1)); fi; }

D=scripts/dtcg-to-css.js
# export css cannot resolve aliases; this converter exists because of that, and the
# reason must survive or someone will "simplify" back to the broken command.
has "$D" "emits"
has "$D" "for every semantic token"
has "$D" "so the indirection survives into CSS and a theme"

C=examples/vela-hero/src/Hero.module.css
T=examples/vela-hero/src/Hero.tsx
# Zero raw hex outside comments: every color must be a token reference.
cnt0 "$C" "^[^/*]*#[0-9a-fA-F]{3}"
# MOTION.md: ease-in is banned on UI, scale(0) is banned, hover must be gated,
# reduced motion must be handled. Each check is mechanical, so assert it directly.
cnt0 "$C" "ease-in[^-]"
cnt0 "$C" "scale\(0\)"
has "$C" "hover: hover) and (pointer: fine)"
has "$C" "prefers-reduced-motion"
# The signature element's line break is load-bearing per TASTE.md.
has "$T" "The line break is load-bearing"
# States: a Figma frame is one state; the emitted component needs the rest.
has "$T" "loading"
has "$T" "disabled={state ==="
has "$C" ":focus-visible"
has "$C" ":disabled"

R=examples/vela-hero/README.md
# The unverified step must be stated plainly, never implied as measured.
has "$R" "**The pixel diff did not run.**"
has "$R" "the rendered browser output was never compared to either"
has "$R" "## What was NOT verified"
# Deliberate divergences must be recorded so nobody "fixes" them.
has "$R" "do not \"fix\" these"

echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
