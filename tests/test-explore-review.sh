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
has "$E" "Check each against \`design/SLOP.md\` **before building**"
has "$E" "**all in a single message** so they run"
has "$E" "**locked direction** for the project"
has "$E" "invoke Emil's \`prototype\` skill"
has "$E" "differ in *approach*, not in accent color"
# The SLOP check must precede the build step, not just be mentioned somewhere:
ordered "$E" "Check each against \`design/SLOP.md\` \*\*before building\*\*" "### 2. Build in parallel"

R=skills/review/SKILL.md
has "$R" "\`design/RUBRIC.md\`."
# analyze clusters is optional (needs figma-use); health check must be marked not-run, not silently skipped, when absent:
has "$R" "unavailable, report the cluster-detection health check as not run rather than"
has "$R" "Never apply fixes from this skill. If the user wants them applied, that is"
has "$R" "invoke \`improve-animations\` for a repo-wide motion audit with"
has "$R" "Invoke \`review-animations\` on the code diff or implementation. Its posture is"
# Dispatch must name the runtime resolver, not just "dispatch a sub-agent" -- the
# one-line version shipped with no budget, no overlap, and no reference, which is how
# an audit spends 195 calls re-deriving what step 1 already measured.
has "$R" "Dispatch a sub-agent (model **sonnet**) per \`design/RUNTIMES.md\`"
has "$R" "Escalate that pass to **opus** when the same dimension scores"
# The inline fallback (for a single-skill install with no RUBRIC.md present)
# must state the identical same-dimension rule, not just the process-step
# escalation above -- otherwise the fallback and the full rule could drift
# apart from each other even after RUBRIC.md and review/SKILL.md agree.
has "$R" 'an exact fix, never "improve the spacing." Escalate to opus when the same'
# /review ships standalone -- an absent TASTE.md must degrade to sensible
# breakpoint defaults, not fail or silently skip the dimension (mirrors how
# /explore proceeds when TASTE.md is absent):
has "$R" "default widths 390 / 834 / 1440 rather than failing or silently skipping the"

echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
