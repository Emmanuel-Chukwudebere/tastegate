#!/usr/bin/env bash
set -uo pipefail
PASS=0; FAIL=0
has() { if grep -qiF "$2" "$1" 2>/dev/null; then echo "  PASS: $(basename $1) has '$2'"; PASS=$((PASS+1)); else echo "  FAIL: $(basename $1) missing '$2'"; FAIL=$((FAIL+1)); fi; }
ordered() {
  local a b; a=$(grep -n "$2" "$1" | head -1 | cut -d: -f1); b=$(grep -n "$3" "$1" | head -1 | cut -d: -f1)
  if [ -n "$a" ] && [ -n "$b" ] && [ "$a" -lt "$b" ]; then echo "  PASS: '$2' before '$3'"; PASS=$((PASS+1));
  else echo "  FAIL: '$2' must precede '$3'"; FAIL=$((FAIL+1)); fi; }

S=skills/ship/SKILL.md
has "$S" "### 1. \`find-animation-opportunities\`"
has "$S" "### 2. \`pick-ui-library\`"
has "$S" "Never hand-roll a toast, drawer, popover, dialog, or combobox — hand-rolled"
has "$S" "### 5. \`animate\`"
has "$S" "### 6. \`review-animations\`"
has "$S" "figma-cli export-jsx <nodeId> --pretty        # structural scaffold"
has "$S" "figma-cli export css                          # or: export tailwind | export dtcg tokens.json"
has "$S" "Screenshot the built UI at the same viewport as the Figma frame and diff against"
has "$S" "then state plainly that visual verification **did not run**. Never imply measured"
# Mandatory Emil sequence, in order:
ordered "$S" "### 1. \`find-animation-opportunities\`" "### 2. \`pick-ui-library\`"
ordered "$S" "### 2. \`pick-ui-library\`" "### 5. \`animate\`"
ordered "$S" "### 5. \`animate\`" "### 6. \`review-animations\`"
# Library choice must precede writing components:
ordered "$S" "### 2. \`pick-ui-library\`" "### 4. Emit"

E=skills/ship/emit.md
has "$E" "It does **not** produce idiomatic framework code, token-bound values, interaction"
has "$E" "flag. So it produces a **structural scaffold**: correct hierarchy, nesting, and"
has "$E" "| Token values | \`export css\` / \`export tailwind\` / \`export dtcg\` | tool — exact, free |"
has "$E" "## Auto Layout maps onto flexbox"
has "$E" "\`extract --selection\` returns Auto Layout values — padding, gap, alignment,"

T=skills/ship/states.md
has "$T" "| Hover | **gated**: \`@media (hover: hover) and (pointer: fine)\` — touch fires false hovers, leaving sticky states |"
has "$T" "| Focus-visible | a visible ring; never remove the outline without replacing it |"
has "$T" "| Disabled | reduced contrast plus \`cursor: not-allowed\`; must still meet contrast minimums for readable text |"
has "$T" "| Loading | a skeleton or spinner; reserve the final layout's space so nothing shifts on arrival |"
has "$T" "| Empty | an invitation to act, not an apology. Say what to do next |"
has "$T" "| Error | what went wrong and how to fix it, in the interface's voice. Never vague, never apologetic |"
has "$T" "| Active / pressed | \`transform: scale(0.97)\`, 160ms \`ease-out\` |"

echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
