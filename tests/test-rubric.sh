#!/usr/bin/env bash
set -uo pipefail
PASS=0; FAIL=0
has() { if grep -qiF "$2" "$1" 2>/dev/null; then echo "  PASS: $1 has '$2'"; PASS=$((PASS+1)); else echo "  FAIL: $1 missing '$2'"; FAIL=$((FAIL+1)); fi; }

R=skills/design/RUBRIC.md
for d in Typography Palette Spacing Hierarchy Motion Accessibility Slop Breakpoint; do has "$R" "$d"; done
has "$R" "0-5"
has "$R" "the score, cited evidence (what you"
has "$R" "MOTION.md"
has "$R" "TYPOGRAPHY.md"
# Escalation must fire on the SAME dimension across two consecutive passes,
# never on any two unrelated low scores -- anchor carries the noun and the
# modal ("escalate that pass") on one line so a reversion to "any dimension"
# fails this check (mirrors qa-brief.md and review/SKILL.md, which must agree).
has "$R" "If the same dimension scores ≤ 2 on two consecutive passes, **escalate that pass"

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
# Slash-vs-hyphen token gotcha: the rule must be stated with its modal intact.
has "$F" "matching \`var list\`, not the hyphen form from \`export css\`.**"
# Unresolved var: does not fail the render -- must be readable as one anchor.
has "$F" "**An unresolved \`var:\` reference does not fail the render.**"
# Real evidence: the failing warning text, verbatim.
has "$F" "neutral-300, neutral-900, neutral-white"
# Real evidence: the working slash form after the fix.
has "$F" 'bg="var:neutral/900"` resolved cleanly with no'
# Collection pin for disambiguating multiple collections.
has "$F" "pin resolution with"
# spec's positional <component> must precede --check -- `spec --check <id>`
# fails live with "missing required argument 'component'" (verified against
# --help), so the anchor carries the full correct call shape:
has "$F" "spec <component> --check <nodeId> --tolerance 2"

# Font weight forms are per-family and a wrong form falls back to Inter with no
# warning and exit 0 — found live when weight="semibold" on Syne rendered Inter.
# Anchors carry the per-family split, since a doc that lost it would send builders
# straight back into the silent fallback.
has "$F" "Inter is every text node's initial state, so a font that never binds stays Inter"
has "$F" 'is the default `fontName` of a newly created text node**, not a'
has "$F" "load-order problem rather than a rejected keyword"
# verify writes to /tmp, which Node resolves as C:\tmp on Windows.
has "$F" '`figma-cli verify <nodeId>` saves to'
has "$F" "mkdir -p /c/tmp"
# eval/run reject top-level await and bare return.
has "$F" "reject top-level"

# <Icon> is Iconify-only and fails silently — found live when five icons rendered as
# empty frames with exit 0, and again when Iconsax prefixes rendered filled squares.
# Anchors carry the failure mode, so a doc that softened it to "may not resolve" fails.
has "$F" "a miss renders as an empty frame with exit 0"
has "$F" "**A local component is not reachable through \`<Icon>\`.**"
has "$F" "**Iconsax is not on Iconify.**"
has "$F" "**\`<SVG>\` does not exist.**"
has "$F" "**\`<Instance>\` parses but its codegen is unreachable**"
# The assertion that catches it must be present, not just the warning.
has "$F" "**Always assert icon children after rendering.**"

echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
