#!/usr/bin/env bash
set -uo pipefail
PASS=0; FAIL=0
has() { if grep -qiF "$2" "$1" 2>/dev/null; then echo "  PASS: $(basename $1) has '$2'"; PASS=$((PASS+1)); else echo "  FAIL: $(basename $1) missing '$2'"; FAIL=$((FAIL+1)); fi; }
nothas() { if grep -qiF "$2" "$1" 2>/dev/null; then echo "  FAIL: $(basename $1) must NOT have '$2'"; FAIL=$((FAIL+1)); else echo "  PASS: $(basename $1) omits '$2'"; PASS=$((PASS+1)); fi; }
ordered() { # $1 file, $2 earlier, $3 later
  local a b; a=$(grep -n "$2" "$1" | head -1 | cut -d: -f1); b=$(grep -n "$3" "$1" | head -1 | cut -d: -f1)
  if [ -n "$a" ] && [ -n "$b" ] && [ "$a" -lt "$b" ]; then echo "  PASS: '$2' before '$3'"; PASS=$((PASS+1));
  else echo "  FAIL: '$2' must come before '$3'"; FAIL=$((FAIL+1)); fi; }

S=skills/design/SKILL.md
has "$S" "Read \`.claude/design/TASTE.md\`."
has "$S" "Read \`.claude/design/registry.md\`. If empty, warn that output will be generated"
has "$S" "figma-cli instantiate \"<ComponentName>\" # if yes, use it"
has "$S" "figma-cli render-batch '[\"<Frame>…</Frame>\",\"<Frame>…</Frame>\"]' --verify"
has "$S" "\`--verify\` returns a screenshot in the same call, so seeing the result costs no"
has "$S" "bash scripts/gates.sh <nodeId> \"<ComponentName>\""
has "$S" "\`qa-brief.md\` as the brief. Model: **sonnet**. The screenshot and"
has "$S" "**Maximum 3 QA passes.** Escalate to opus"
has "$S" "**If it does not exist, refuse** and direct the"
# The gate must run before the model-based QA pass:
ordered "$S" "bash scripts/gates.sh <nodeId>" "Dispatch per \`skills/design/RUNTIMES.md\` using"
# Registry lookup must precede building:
ordered "$S" "figma-cli spec \"<ComponentName>\"" "figma-cli render-batch"

G=scripts/gates.sh
has "$G" "if figma-cli lint --fix --json 2>/dev/null; then"
has "$G" "if figma-cli spec \"\$COMPONENT\" --check \"\$NODE_ID\" --tolerance 2; then"

Q=skills/design/qa-brief.md
has "$Q" "\`[plugin]/skills/design/RUBRIC.md\` — your scoring method"
has "$Q" "**Evidence** — what you actually observed, and where in the design"
has "$Q" "**Write full prose findings with your reasoning.** A terse list is not acceptable;"
has "$Q" "**If the same dimension scores ≤ 2 on two consecutive passes**, say explicitly that this warrants escalation to a stronger model, and why."
# Must match RUBRIC.md's condition (same dimension twice), not fire on any single low score from pass 2 on:
nothas "$Q" "and this is pass 2 or later"

if [ -x scripts/gates.sh ] || [ -f scripts/gates.sh ]; then echo "  PASS: gates.sh exists"; PASS=$((PASS+1)); else echo "  FAIL: gates.sh missing"; FAIL=$((FAIL+1)); fi

echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
