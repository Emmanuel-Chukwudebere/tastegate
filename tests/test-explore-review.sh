#!/usr/bin/env bash
set -uo pipefail
PASS=0; FAIL=0
has() { if grep -qiF "$2" "$1" 2>/dev/null; then echo "  PASS: $(basename $1) has '$2'"; PASS=$((PASS+1)); else echo "  FAIL: $(basename $1) missing '$2'"; FAIL=$((FAIL+1)); fi; }
ordered() { # $1 file, $2 earlier, $3 later
  local a b; a=$(grep -n "$2" "$1" | head -1 | cut -d: -f1); b=$(grep -n "$3" "$1" | head -1 | cut -d: -f1)
  if [ -n "$a" ] && [ -n "$b" ] && [ "$a" -lt "$b" ]; then echo "  PASS: '$2' before '$3'"; PASS=$((PASS+1));
  else echo "  FAIL: '$2' must come before '$3'"; FAIL=$((FAIL+1)); fi; }

E=skills/explore/SKILL.md
has "$E" "Define three directions"
has "$E" "figma-cli render-batch '[…]' --verify"
has "$E" "Check each against \`skills/design/SLOP.md\` **before building**"
has "$E" "**all in a single message** so they run"
has "$E" "**locked direction** for the project"
has "$E" "invoke Emil's \`prototype\` skill"
has "$E" "differ in *approach*, not in accent color"
# The SLOP check must precede the build step, not just be mentioned somewhere:
ordered "$E" "Check each against \`skills/design/SLOP.md\` \*\*before building\*\*" "### 2. Build in parallel"

R=skills/review/SKILL.md
has "$R" "\`skills/design/RUBRIC.md\`."
has "$R" "Never apply fixes from this skill. If the user wants them applied, that is"
has "$R" "invoke \`improve-animations\` for a repo-wide motion audit with"
has "$R" "Invoke \`review-animations\` on the code diff or implementation. Its posture is"
has "$R" "Dispatch a sub-agent (model **sonnet**) with the brief in"
has "$R" "Escalate that pass to **opus** when any dimension scores"

echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
