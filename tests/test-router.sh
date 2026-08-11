#!/usr/bin/env bash
set -uo pipefail
PASS=0; FAIL=0
has() { if grep -qiF "$2" "$1" 2>/dev/null; then echo "  PASS: $(basename $1) has '$2'"; PASS=$((PASS+1)); else echo "  FAIL: $(basename $1) missing '$2'"; FAIL=$((FAIL+1)); fi; }
ordered() { local a b; a=$(grep -n "$2" "$1" | head -1 | cut -d: -f1); b=$(grep -n "$3" "$1" | head -1 | cut -d: -f1)
  if [ -n "$a" ] && [ -n "$b" ] && [ "$a" -lt "$b" ]; then echo "  PASS: '$2' before '$3'"; PASS=$((PASS+1));
  else echo "  FAIL: '$2' must come before '$3'"; FAIL=$((FAIL+1)); fi; }

R=skills/claude-design/SKILL.md

# The router must exist as a real skill with frontmatter, or it cannot be invoked.
has "$R" "name: claude-design"
has "$R" "description: Use as the single entry point"

# It must decide, not delegate the decision back to the user — the whole point.
has "$R" "**Do not ask the user which stage they want**"
# Grounding is mandatory and must not be presented as a choice.
has "$R" "**Do not ask permission; grounding is not optional.**"
# taste must be checked before anything else routes.
ordered "$R" "Does \`.claude/design/TASTE.md\` exist?" "Is the direction settled?"
ordered "$R" "Is the direction settled?" "What is the endpoint?"

# Code endpoints must still build in Figma first, or ship has nothing to measure.
has "$R" "run \`design\` first even if the user only said \"build it in"
has "$R" "means shipping code with nothing to verify fidelity against"

# State handoff: the reference captures are what make the image-comparison QA work.
has "$R" "a discarded reference forces it"
has "$R" "\`ship\` should not re-derive geometry a gate already measured"

# The daemon check is the single largest speed win and is invisible without it.
has "$R" "**Check \`figma-cli daemon status\` specifically.**"
has "$R" "~20s instead of ~3s"
has "$R" "re-time one call to"
# Preflight runs once at the router, not per stage.
has "$R" "rather than in every stage"

# The three speed rules must all be present with their numbers intact.
has "$R" "**Gate before critique.**"
has "$R" "**Overlap the audit.**"
has "$R" "**Stop at the tolerance.**"
has "$R" "±8pt position, ±3pt cap-height is converged"

# A stage that could not run must be reported, never silently dropped.
has "$R" "must say so plainly rather than being silently dropped"

echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
