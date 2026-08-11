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
# Must restate RUBRIC.md's escalation condition as same-dimension, not any-dimension:
has "$S" "when \`RUBRIC.md\`'s condition is met (the same dimension ≤ 2 twice)"
has "$S" "**If it does not exist, refuse** and direct the"
# scripts/ must have a documented inline equivalent so README's "nothing
# hard-depends on scripts/" claim is true under a single-skill install:
has "$S" "(a single-skill install), run its checks directly: \`figma-cli --version\`,"
has "$S" "**Without \`scripts/\`**, run \`a11y audit <nodeId>\` and"
# Real variable names must be resolved before writing var: references:
has "$S" "Resolve real variable names with \`figma-cli var list\` before writing a \`var:\`"
# Unresolved-variable warning is a build failure, not a cosmetic warning:
has "$S" "**An unresolved-variable warning from \`render\` is a build failure, not a"
# Must be fixed before the QA pass, never reaching the QA model or user:
has "$S" "fix it before the QA pass — never let it reach the QA model or the user."
# The gate must run before the model-based QA pass:
ordered "$S" "bash scripts/gates.sh <nodeId>" "Dispatch per \`RUNTIMES.md\` using"
# Registry lookup must precede building:
ordered "$S" "figma-cli spec \"<ComponentName>\"" "figma-cli render-batch"

G=scripts/gates.sh
# The old whole-file `lint --fix` must be GONE, not merely unused: at 57k nodes it
# timed out, and --fix at that scope rewrites the whole design system.
nothas "$G" "figma-cli lint --fix --json"
has "$G" "if figma-cli spec \"\$COMPONENT\" --check \"\$NODE_ID\" --tolerance 2; then"

Q=skills/design/qa-brief.md
has "$Q" "\`[plugin]/skills/design/RUBRIC.md\` — your scoring method"
has "$Q" "**Evidence** — what you actually observed, and where in the design"
has "$Q" "**Write full prose findings with your reasoning.** A terse list is not acceptable;"
has "$Q" "**If the same dimension scores ≤ 2 on two consecutive passes**, say explicitly that this warrants escalation to a stronger model, and why."
# Must match RUBRIC.md's condition (same dimension twice), not fire on any single low score from pass 2 on:
nothas "$Q" "and this is pass 2 or later"

if [ -x scripts/gates.sh ] || [ -f scripts/gates.sh ]; then echo "  PASS: gates.sh exists"; PASS=$((PASS+1)); else echo "  FAIL: gates.sh missing"; FAIL=$((FAIL+1)); fi

# Throughput rules, added after a live build where one blocking audit of three
# frames took 144 minutes and 195 tool calls. Each anchor guards a rule whose
# reversal would restore that cost, so the polarity sits inside the anchor.
has "$S" "**Dispatch in the background and keep building.**"
has "$S" "**Cap the audit.**"
has "$S" "Also gate the font bindings.**"
# The font gate must run in step 5, before the QA dispatch — same reason the
# lint/spec gates do: it is free, and a model hunting it is not.
ordered "$S" "Also gate the font bindings" "Dispatch in the background"

# Convergence rules, added after a live hero spent ~20 measure-adjust-export rounds
# closing deltas that were no longer visible. Each anchor carries the numeric band or
# the cap, since a doc that lost the number would restore the unbounded loop.
has "$S" "**Converged means stop: ±8pt position, ±3pt cap-height.**"
has "$S" "**At most 2 geometry-correction rounds between QA passes.**"
has "$S" "**Derive type size from one rendered probe, never from a cap-height ratio.**"
# The tolerance must be stated before the round cap, so a builder reads "when am I done"
# before "how many tries do I get".
ordered "$S" "Converged means stop" "At most 2 geometry-correction rounds"

Q=skills/design/qa-brief.md
has "$Q" "**Budget: \`[N]\` tool calls.**"
has "$Q" "do not re-derive"
has "$Q" "not in the *number of findings*"

# The audit judges by comparing pictures against the agreed direction. Told to score
# eight dimensions with no reference and no budget, one pass spent 195 tool calls
# probing properties a gate had already measured. These anchors carry the polarity
# ("not by measuring", "Do not probe") so a reversal breaks the check.
has "$Q" "**Compare against the direction:**"
has "$Q" "**Judge by looking, not by measuring.**"
has "$Q" "**Do not probe node properties.**"
has "$Q" "**Lead with the direction, not the checklist.**"
has "$Q" "still misses the direction has failed"
has "$S" "**Pass the reference image alongside the build.**"
# The reference must be handed over before the audit is dispatched, or there is
# nothing to compare against.
ordered "$S" "Pass the reference image alongside the build" "Cap the audit"




# Gate scoping and daemon health, added after measuring the two biggest time sinks:
# unscoped `lint` (36-41s then CDP timeout on a 57k-node file) and a stale daemon
# token (20.1s per eval vs 3.0s, with `status` still reporting "Connected").
# Anchors carry the numbers, since a doc that lost them would restore both costs.
has "$S" "**Never gate with \`figma-cli lint\`.**"
has "$S" "**\`figma-cli daemon status\`**"
has "$S" "cost ~20s instead of ~3s, and \`status\` reports \`Connected\` anyway"
G=scripts/gates.sh
has "$G" "figma-cli lint\` is deliberately not used"
has "$G" "do NOT substitute whole-file lint"
# The gate must fail loudly on an unbound color, not merely print it.
has "$G" "GATE: lint found errors"
# The font gate must treat Inter as a violation, not a note.
has "$G" "GATE: font VIOLATION"
L=scripts/lint-node.js
# Comments must live inside the IIFE — `run` returns nothing with a leading // header.
has "$L" "silently returns nothing"
has "$L" "leading \`//\` comments before the opening"
P=scripts/preflight.sh
has "$P" "PREFLIGHT: figma-daemon AUTH FAILED"
has "$P" "figma-cli daemon restart"

# A hidden node exports a ~149-byte transparent PNG at exit 0, so a blank screenshot
# can reach the QA pass with no signal anywhere. Mutation-verified: setting
# visible=false makes this gate report BLANK (149 bytes).
has "$G" "GATE: export not blank"
has "$G" "check node.visible via"
# Reused DS instances carry their own type — a "no Inter" check passes right over it.
has "$G" "GATE: font MIXED"

echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
