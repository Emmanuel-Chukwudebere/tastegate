#!/usr/bin/env bash
# Brand-vs-usability pushback, the UX-law provenance rules, and the text-geometry
# cause of the unclosable vertical diff.
#
# Every anchor below carries the RULE'S POLARITY inside the quoted phrase, not just
# its topic. A doc that reverses the rule must fail these — so "the profile wins"
# is anchored with its subject attached, never as a bare keyword that would still
# match a document saying the opposite.
set -uo pipefail
PASS=0; FAIL=0
has() { if grep -qiF "$2" "$1" 2>/dev/null; then echo "  PASS: $1 has '$2'"; PASS=$((PASS+1)); else echo "  FAIL: $1 missing '$2'"; FAIL=$((FAIL+1)); fi; }
lacks() { if grep -qiF "$2" "$1" 2>/dev/null; then echo "  FAIL: $1 must NOT have '$2'"; FAIL=$((FAIL+1)); else echo "  PASS: $1 lacks '$2'"; PASS=$((PASS+1)); fi; }

C=skills/design/CONFLICT.md

# The mechanism's three moves, in order. Dropping any one turns pushback into
# either silent compliance or silent override -- the two failure modes named.
has "$C" "Surface the conflict, propose the smallest fix that keeps the brand intact, and"
has "$C" "Never silently override the profile, and never silently comply"

# The measurability line. This is the load-bearing rule: without it, every
# aesthetic preference becomes a "conflict" and the tool turns exhausting.
has "$C" "If you cannot name the threshold and the measured"
has "$C" "you do not have a conflict — you have a preference"
# The right-hand column must be stated as the profile WINNING, not merely listed.
has "$C" "the profile winning, which is correct"
has "$C" "Aesthetic disagreement is not a finding"

# The four-line report shape, and that it precedes the build.
has "$C" "CONFLICT:"
has "$C" "WHY IT MATTERS:"
has "$C" "SMALLEST FIX:"
has "$C" "YOUR CALL:"
has "$C" "before building, not after"

# Smallest-fix discipline: clearing the bar, not maximising it.
has "$C" "Clear 4.5:1 at 4.6, not 7.0"
has "$C" "Hold the hue, weight, and family"
has "$C" "One conflict, one decision"

# Recording: a re-raised decision teaches the user to ignore the mechanism.
has "$C" "## Accepted exceptions"
has "$C" "Do not re-raise"
has "$C" "not in \`design\`, not in \`review\`, not in a QA pass"

# The unattended default MUST be follow-the-profile. A doc that flipped this to
# "apply the fix" would silently redesign a brand in CI, so the anchor carries
# both the action and its object.
has "$C" "follow the profile and"
has "$C" "an unattended run is not consent to redesign their brand"
# ...with exactly one exception, stated with its numeric floor.
has "$C" "never ship a state that cannot be perceived at all"
has "$C" "1.5:1"

U=skills/design/UX-LAWS.md

# Attribution: the file must be traceable to its source and licence.
has "$U" "lawsofux.com"
has "$U" "Jon Yablonski"
has "$U" "CC BY-NC-SA"

# The quantified/directional split is the whole point of the file.
has "$U" "Most of these are not thresholds, and using them as gates is a misuse"
has "$U" "If you cannot quote the law's own number, you are reasoning, not gating"

# Miller's own warning, verbatim -- it is the strongest available argument against
# the misuse, and it comes from the law itself rather than from us.
has "$U" "Don't use the 'magical number seven' to justify unnecessary design limitations"
# And the correct application (chunking) vs the forbidden one (capping items).
has "$U" "never for capping menu items or form fields"

# Doherty: the number, and the conflation it must prevent. 400ms feedback is NOT
# a licence for a 400ms animation -- MOTION.md caps that at 300ms.
has "$U" "Doherty Threshold — feedback within 400ms"
has "$U" "Applies to system *feedback*, not to animation duration"
has "$U" "Do not conflate them"
# The inverse case, so a profile's deliberate delay is not flagged as a defect.
has "$U" "A deliberate delay is a design decision, not a defect"

# Fitts's Law carries NO numbers -- verified against the source page. This anchor
# is the fabricated-citation guard, so it must name the real source of 24x24.
has "$U" "no numbers at all"
has "$U" "WCAG 2.5.8 Target Size"
has "$U" "Attributing a pixel value to Fitts's Law is a fabricated citation"

# Jakob's Law is the honest cost argument, and must stay an argument not a gate.
has "$U" "deviating from convention is not wrong, it is"
has "$U" "still an argument, not a gate"

# Aesthetic-Usability is why the deterministic gate precedes visual critique --
# the bias applies to the auditing model, not only to end users.
has "$U" "Visually pleasing design can mask usability problems"
has "$U" "looking is biased in a known direction"

# The laws are a vocabulary, never a ninth rubric dimension.
has "$U" "not a rubric dimension and not a checklist"
has "$U" "Never cite a law for a value it does not contain"

T=skills/design/TEXT-GEOMETRY.md

# The cause, stated as two DIFFERENT reference lines rather than a fixable offset.
has "$T" "two different reference lines"
has "$T" "artifact, not a defect"

# Both error sources, each with its measured magnitude. A doc that kept the topic
# but dropped the numbers could not justify the rule, so the numbers are anchored.
has "$T" "line-height: 1\` is shorter than Figma AUTO; a \`1.2\` ratio is taller"
has "$T" "CSS centres the glyph, Figma does not"
has "$T" "the glyph moves 11px purely from line-height"

# The diagnostic signature that disproved the uniform-offset hypothesis.
has "$T" "flips sign partway down"
has "$T" "a uniform offset cannot produce it"

# The rule, and the prevention that makes the rule unnecessary.
has "$T" "Compare ink to ink. Never compare box to box"
has "$T" "Set an explicit line-height on both sides, in pixels"

# The NaN trap in the reference implementation -- silent, so it needs stating.
has "$T" "returns \`NaN\` for \`line-height: normal\`"

# Why this is filed as speed, not fidelity: the loop cannot terminate on success.
has "$T" "unclosable by construction"

# Ground-truthing claim: metrics API cross-checked against rasterised ink.
has "$T" "scanning for the first row of ink"
has "$T" "agreed within 1px"

# --- Wiring: a standard nothing references is a standard nothing applies. ---
has skills/design/SKILL.md "see \`CONFLICT.md\`"
has skills/design/SKILL.md "Only measurable conflicts"
has skills/design/RUBRIC.md "Score this against the threshold, not against \`TASTE.md\`"
has skills/design/RUBRIC.md "UX-LAWS.md"
has skills/design/RUBRIC.md "WCAG 2.5.8"
# RUBRIC must keep the inverse guard too: divergence-by-profile is not slop.
has skills/design/RUBRIC.md "The inverse is not a finding"
has skills/design/qa-brief.md "CONFLICT.md"
has skills/design/qa-brief.md "UX-LAWS.md"
has skills/design/qa-brief.md "applies to you"
has skills/review/SKILL.md "design/CONFLICT.md"
has skills/ship/SKILL.md "design/TEXT-GEOMETRY.md"
has skills/ship/SKILL.md "Compare **ink to ink**"
has skills/ship/states.md "design/CONFLICT.md"
has skills/tastegate/SKILL.md "Compare ink to ink, never box to box"
has skills/taste/TASTE-template.md "## Accepted exceptions"
has skills/taste/TASTE-template.md "Never re-raise an entry here"

# ship must carry the SAME tolerance band as design -- its absence there is what
# left the pixel-chase unbounded in the stage where it actually happened.
has skills/ship/SKILL.md "±8pt position, ±3pt cap-height"
has skills/ship/SKILL.md "At most 2 correction rounds between diffs"
has skills/ship/SKILL.md "not to correct harder"

# states.md thresholds must be numeric, since Figma supplies neither state.
has skills/ship/states.md "≥ 3:1 against **both** the component and the page"
has skills/ship/states.md "text still ≥ 4.5:1"

# The lint script must flag AUTO line-height, and must NOT block on instance text
# it cannot fix -- both polarities anchored.
has scripts/lint-node.js "AUTO line-height at"
has scripts/lint-node.js "inside an instance"
has scripts/lint-node.js "Report it, do not block it"
# gates.sh surfaces a11y findings as a CONFLICT rather than exiting 1 on a brand
# colour the user may already have accepted.
has scripts/gates.sh "raise a CONFLICT"

# The lint comment must live INSIDE the IIFE: a leading // header makes
# `figma-cli run` return nothing at exit 0, which reads as "clean".
if [ "$(head -c 2 scripts/lint-node.js)" = "//" ]; then
  echo "  FAIL: scripts/lint-node.js starts with // — figma-cli run returns nothing"
  FAIL=$((FAIL+1))
else
  echo "  PASS: scripts/lint-node.js does not start with a // header"
  PASS=$((PASS+1))
fi

# Every standard the README's table names must exist. A table naming a missing file
# is the same class of defect as the three false README claims fixed in 0.3.0 --
# it reads as a feature and delivers nothing.
for f in design/RUBRIC.md design/SLOP.md design/MOTION.md design/TYPOGRAPHY.md \
         design/CONFLICT.md design/UX-LAWS.md design/TEXT-GEOMETRY.md \
         design/FIGMA-CLI.md ship/states.md ship/FRAMEWORKS.md; do
  if grep -qF "\`$f\`" README.md 2>/dev/null && [ -f "skills/$f" ]; then
    echo "  PASS: README lists skills/$f and it exists"; PASS=$((PASS+1))
  else
    echo "  FAIL: README/skills mismatch for $f"; FAIL=$((FAIL+1))
  fi
done

# Guard the fabricated citation directly: no file may attach a pixel value to
# Fitts's Law. UX-LAWS.md is exempt because it names the error to forbid it.
for f in skills/design/RUBRIC.md skills/design/CONFLICT.md skills/ship/states.md; do
  lacks "$f" "Fitts's Law: 24"
  lacks "$f" "per Fitts"
done

echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
