#!/usr/bin/env bash
# Verifies the standard-resolution rule from the plan's Global Constraints:
# skills locate a standard by checking their own directory first, then
# sibling skill directories, and degrade to their own rules if absent.
set -uo pipefail
PASS=0; FAIL=0
has() { if grep -qiF "$2" "$1" 2>/dev/null; then echo "  PASS: $(basename $1) has '$2'"; PASS=$((PASS+1)); else echo "  FAIL: $(basename $1) missing '$2'"; FAIL=$((FAIL+1)); fi; }
nothas() { if grep -qiF "$2" "$1" 2>/dev/null; then echo "  FAIL: $(basename $1) must NOT have '$2'"; FAIL=$((FAIL+1)); else echo "  PASS: $(basename $1) omits '$2'"; PASS=$((PASS+1)); fi; }
uniq1() { local n; n=$(grep -ciF "$2" "$1" 2>/dev/null || echo 0); if [ "$n" -eq 1 ]; then echo "  PASS: $(basename $1) has exactly 1 '$2'"; PASS=$((PASS+1)); else echo "  FAIL: $(basename $1) has $n (want 1) '$2'"; FAIL=$((FAIL+1)); fi; }

DESIGN=skills/design/SKILL.md
SHIP=skills/ship/SKILL.md
TASTE=skills/taste/SKILL.md
EXPLORE=skills/explore/SKILL.md
REVIEW=skills/review/SKILL.md

# --- 1. Each of the five SKILL.md files states the resolution rule ---
# Own-directory-first clause:
uniq1 "$DESIGN" "sits beside this SKILL.md — read it directly"
uniq1 "$SHIP" "sits beside this SKILL.md — read it directly"
uniq1 "$TASTE" "sits beside this SKILL.md — read it directly"
# explore/ and review/ open directly on the sibling case (they have no
# own-directory standards to locate), so their rule statement is anchored
# on the sibling clause instead — checked below together with the other three.

# Sibling-lookup clause (own dir first, then sibling skill's directory):
uniq1 "$DESIGN" "then in that sibling skill's own directory"
uniq1 "$SHIP" "then in that sibling"
uniq1 "$TASTE" "would belong to a sibling skill"
uniq1 "$EXPLORE" "belongs to a"
uniq1 "$REVIEW" "belongs to a"

# Inline-fallback-on-absence clause, with the modal ("Never fail") inside the anchor:
uniq1 "$DESIGN" "Never fail, and never"
uniq1 "$SHIP" "say so once, apply the rule stated"
uniq1 "$TASTE" "say so once, apply this skill's own"
uniq1 "$EXPLORE" "then fall back to the compact rule below"
uniq1 "$REVIEW" "then fall back to the compact rule below"

# --- 2. No SKILL.md contains a skills/<self>/ self-prefix ---
nothas "$DESIGN" "skills/design/"
nothas "$SHIP" "skills/ship/"
nothas "$EXPLORE" "skills/explore/"
nothas "$REVIEW" "skills/review/"
nothas "$TASTE" "skills/taste/"
# No SKILL.md should reference any skills/ path at all, own or otherwise —
# sibling references use the shorter <skill>/<FILE> form instead. Exempt the
# legitimate external exception: ~/.claude/skills/ and ~/.agents/skills/ are
# the cross-runtime install locations for Emil's (unrelated, outside-the-
# plugin) skills, not a self-prefixed reference into THIS plugin's own tree.
for f in "$DESIGN" "$SHIP" "$EXPLORE" "$REVIEW" "$TASTE"; do
  n=$(grep -icF "skills/" "$f" 2>/dev/null)
  external=$(grep -icE '\.(claude|agents)/skills/' "$f" 2>/dev/null)
  n="${n:-0}"; external="${external:-0}"
  if [ "$n" -eq "$external" ]; then
    echo "  PASS: $(basename $f) omits 'skills/' (beyond the external emil-design-eng exception)"; PASS=$((PASS+1))
  else
    echo "  FAIL: $(basename $f) must NOT have 'skills/' beyond the external emil-design-eng exception ($n found, $external excused)"; FAIL=$((FAIL+1))
  fi
done

# --- 3. explore/ and review/ carry an inline fallback and name the ---
#        sibling as authoritative when present ---
uniq1 "$EXPLORE" "sibling file is authoritative whenever it is present"
uniq1 "$REVIEW" "sibling file is authoritative whenever it is present"
# The fallback content itself must be present and compact (a summary, not
# a reproduction of the sibling file):
uniq1 "$EXPLORE" "reject the AI-default clusters"
uniq1 "$EXPLORE" "warm cream (near \`#F4F1EA\`) paired with serif display and terracotta"
uniq1 "$REVIEW" "score all eight dimensions"
# Escalation condition must be same-dimension, not any-dimension (Finding 3):
uniq1 "$REVIEW" "Escalate to opus when the same"

# --- 4. Mechanical check: every <skill>/<FILE> sibling reference resolves ---
#        on disk under skills/<skill>/<FILE>. Catches typos and drift.
#        Scoped to skills/*/SKILL.md, since the sibling-path form
#        (`design/MOTION.md`) is only ever written from a *different*
#        skill's directory looking across; a file already inside design/
#        would drop the prefix (see part 4b).
BACKTICK='`'
PATTERN="${BACKTICK}(design|ship|explore|review|taste)/[A-Za-z0-9_.-]+\\.md${BACKTICK}"
REFS="$(grep -noE "$PATTERN" skills/*/SKILL.md \
  | sed -E 's/^[^:]+:[0-9]+://' | tr -d "$BACKTICK" | sort -u)"
if [ -z "$REFS" ]; then
  echo "  FAIL: no sibling <skill>/<FILE> references found to check"; FAIL=$((FAIL+1))
else
  while IFS= read -r ref; do
    [ -z "$ref" ] && continue
    if [ -f "skills/$ref" ]; then
      echo "  PASS: skills/$ref exists (referenced as \`$ref\`)"; PASS=$((PASS+1))
    else
      echo "  FAIL: skills/$ref does not exist (referenced as \`$ref\`)"; FAIL=$((FAIL+1))
    fi
  done <<< "$REFS"
fi

# --- 4b. Mechanical check: every bare `<FILE>.md` reference in ANY markdown ---
#         file under skills/ (not just SKILL.md) resolves inside that same
#         file's own skill directory. This is the check the reviewer proved
#         vacuous — it stopped at SKILL.md, so a broken bare `MOTION.md` in a
#         supporting file (states.md, FRAMEWORKS.md, TASTE-template.md,
#         intake.md) went undetected. Files that live outside the plugin
#         entirely (the consuming project's TASTE.md, registry.md, and a
#         generated DESIGN.md) are excluded — they are never resolvable
#         under skills/ by design.
EXTERNAL_SKIP="TASTE.md registry.md DESIGN.md"
BARE_PATTERN="${BACKTICK}[A-Za-z][A-Za-z0-9_.-]*\\.md${BACKTICK}"
BARE_CHECKED=0
for f in skills/*/*.md; do
  SKILLDIR="$(dirname "$f")"
  FILEREFS="$(grep -noE "$BARE_PATTERN" "$f" 2>/dev/null \
    | sed -E 's/^[0-9]+://' | tr -d "$BACKTICK" | sort -u)"
  [ -z "$FILEREFS" ] && continue
  while IFS= read -r ref; do
    [ -z "$ref" ] && continue
    SKIP=0
    for ext in $EXTERNAL_SKIP; do [ "$ref" = "$ext" ] && SKIP=1; done
    [ "$SKIP" -eq 1 ] && continue
    BARE_CHECKED=$((BARE_CHECKED+1))
    if [ -f "$SKILLDIR/$ref" ]; then
      echo "  PASS: $SKILLDIR/$ref exists (bare \`$ref\` in $f)"; PASS=$((PASS+1))
    else
      echo "  FAIL: $SKILLDIR/$ref does not exist (bare \`$ref\` in $f)"; FAIL=$((FAIL+1))
    fi
  done <<< "$FILEREFS"
done
if [ "$BARE_CHECKED" -eq 0 ]; then
  echo "  FAIL: no bare \`<FILE>.md\` references found to check"; FAIL=$((FAIL+1))
fi

echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
