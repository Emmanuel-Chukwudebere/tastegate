#!/usr/bin/env bash
# Every audit in this pipeline must be a DISPATCHED sub-agent with a budget, not an
# inline pass -- and ship must review as it goes, not only at the end.
#
# Found by audit: `ship` had no dispatch instruction at all (step 8 said only "run
# RUBRIC.md"), and `review` step 3 had one line with no budget, no overlap, and no
# reference. Both shipped that way. These anchors carry the rule's polarity so a
# regression to an inline or unbudgeted pass fails here.
set -uo pipefail
PASS=0; FAIL=0
has() { if grep -qiF "$2" "$1" 2>/dev/null; then echo "  PASS: $1 has '$2'"; PASS=$((PASS+1)); else echo "  FAIL: $1 missing '$2'"; FAIL=$((FAIL+1)); fi; }

# --- Every stage that audits must name a dispatch, a brief, and a model. ---
for f in skills/design/SKILL.md skills/review/SKILL.md skills/ship/SKILL.md; do
  has "$f" "RUNTIMES.md"
  has "$f" "qa-brief.md"
done

D=skills/design/SKILL.md
has "$D" "dispatch a sub-agent, overlapped not blocking"
has "$D" "Dispatch in the background and keep building"

R=skills/review/SKILL.md
# The four inputs, each of which the pass degrades badly without.
has "$R" "Dispatch a sub-agent (model **sonnet**) per \`design/RUNTIMES.md\`"
has "$R" "A tool-call budget"
has "$R" "195 tool calls"
has "$R" "Accepted exceptions\` from \`TASTE.md\`"
# Per-breakpoint parallelism, in ONE message -- serial dispatch was the 144-minute path.
has "$R" "**Dispatch one sub-agent per breakpoint, all in a single message**"
has "$R" "never read"
# Degradation must be stated, so a runtime without sub-agents still runs the pass.
has "$R" "Without sub-agent support"

S=skills/ship/SKILL.md
# Step 8 must DISPATCH, not merely "run the rubric" -- that was the actual defect.
has "$S" "### 8. Round-trip check — dispatch a sub-agent"
has "$S" "**Dispatch it, do not run it inline.**"
# The reason has to survive editing: self-review in the authoring context is weakest.
has "$S" "still resident and reads as justification"
# The three inputs ship has that design does not.
has "$S" "the emitted file paths"
has "$S" "the residual deltas from step 7"
has "$S" "the states from \`states.md\`"

# Review-as-it-goes: the gap that let a stand-in image reach production.
has "$S" "**Dispatch a review as each component lands, not once at the end.**"
has "$S" "costs an edit"
has "$S" "placeholders that render fine"
# It must be BACKGROUND, or it serialises emit and costs more than it saves.
has "$S" "background** sub-agent per component"
# And it must be budgeted, or it becomes the 195-call audit.
has "$S" "budget**, and tell it **not to re-derive**"
# Single-component escape hatch, so the rule does not add a pass where none is needed.
has "$S" "On a single-component job, skip this"

# The router must state the rule once, since it sequences the stages.
R2=skills/tastegate/SKILL.md
has "$R2" "Every audit in this pipeline is a"
has "$R2" "a fresh context reviews code the way a reader will"

# --- Image extraction: export node is the WRONG tool, and that must stay stated. ---
E=skills/ship/emit.md
has "$E" "Images travel as bytes, never as a stand-in"
# The failure mode is that a placeholder passes EVERY check -- the reason it shipped.
has "$E" "**A stand-in image passes every check in this pipeline**"
has "$E" "**Do not use \`export node\` for this.**"
has "$E" "Verify the byte count"
has "$E" "A named gap gets fixed; a plausible placeholder ships"

F=skills/design/FIGMA-CLI.md
has "$F" "Extracting an image fill: \`export node\` is the wrong tool"
has "$F" "4.07MB"
has "$F" "766KB"
has "$F" "getImageByHash"
has "$F" "765,831"
# scaleMode -> object-fit mapping must be present, or the crop is guesswork.
has "$F" 'scaleMode: "FILL"'
has "$F" "object-fit: cover"
# The no-op object-position finding, with its measurement.
has "$F" "silent no-op"
has "$F" "Compute the overflow before"
# Magic-byte sniffing: the paint carries no format field.
has "$F" "sniff the magic bytes"

# getNodeByIdAsync hangs rather than returning null -- so the null guard is not enough.
has "$F" "hangs on a nonexistent id rather than returning null"
has "$F" "unreachable when \`id\` does not exist"
has "$F" "verify an id exists"

# --- The extraction script itself. ---
X=scripts/extract-image.js
has "$X" "getBytesAsync"
has "$X" "getSizeAsync"
# Comments INSIDE the IIFE: a leading // header makes `run` return nothing at exit 0.
if [ "$(head -c 2 "$X")" = "//" ]; then
  echo "  FAIL: $X starts with // — figma-cli run returns nothing"; FAIL=$((FAIL+1))
else
  echo "  PASS: $X does not start with a // header"; PASS=$((PASS+1))
fi
# Both placeholders must be present for the sed substitution to work.
for p in __NODE_ID__ __META__; do has "$X" "$p"; done
# Ambiguity must be refused, not silently resolved to fills[0].
has "$X" "ambiguous"
# The chunked base64 loop: fromCharCode.apply overflows the stack on a large array.
has "$X" "0x8000"
# A missing fill on a parent must name the children, not read as a bad node id.
has "$X" "the fill may live on one of them"

# The spec's disproved <SVG> claim must be marked, not left as guidance.
SP=docs/superpowers/specs/2026-08-06-tastegate-local-design.md
has "$SP" "Disproved during implementation: there is no \`<SVG>\` element"
has "$SP" "createNodeFromSvg"

echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
