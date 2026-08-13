#!/usr/bin/env bash
# The reuse path: the registry must be reachable, and the build must be checked
# against it. Both were broken silently — `spec`/`instantiate` auto-locate skips
# dot-directories, so a valid registry at .claude/design/registry.md was invisible,
# and nothing verified that a build instanced anything at all.
set -uo pipefail
PASS=0; FAIL=0
has() { if grep -qiF "$2" "$1" 2>/dev/null; then echo "  PASS: $(basename $1) has '$2'"; PASS=$((PASS+1)); else echo "  FAIL: $(basename $1) missing '$2'"; FAIL=$((FAIL+1)); fi; }
nothas() { if grep -qiF "$2" "$1" 2>/dev/null; then echo "  FAIL: $(basename $1) must NOT have '$2'"; FAIL=$((FAIL+1)); else echo "  PASS: $(basename $1) omits '$2'"; PASS=$((PASS+1)); fi; }
ordered() { # $1 file, $2 earlier, $3 later
  local a b; a=$(grep -n "$2" "$1" | head -1 | cut -d: -f1); b=$(grep -n "$3" "$1" | head -1 | cut -d: -f1)
  if [ -n "$a" ] && [ -n "$b" ] && [ "$a" -lt "$b" ]; then echo "  PASS: '$2' before '$3'"; PASS=$((PASS+1));
  else echo "  FAIL: '$2' must come before '$3'"; FAIL=$((FAIL+1)); fi; }

echo "--- the --file flag is mandatory on every registry read ---"
D=skills/design/SKILL.md
has "$D" 'figma-cli spec "<ComponentName>" --file .claude/design/registry.md'
has "$D" 'figma-cli instantiate "<ComponentName>" --file .claude/design/registry.md'
has "$D" "**\`--file\` is mandatory, not a convenience.**"
# The REASON must be recorded, not just the flag: a future edit that "tidies" the
# flag away needs to hit the explanation for why it exists.
has "$D" "**skips every dot-directory**, which is exactly where this plugin writes its"
# The two indistinguishable failures are the actual drift mechanism:
has "$D" "is indistinguishable from \"this component does not exist\""
has "$D" "**A \`✗\` from either command is a stop, not a signal to build.**"
# Reuse must keep the linkage rationale, not just "don't rebuild":
has "$D" "design-system changes"

echo "--- the reuse gate is wired into step 5 and cannot be substituted ---"
has "$D" "the **reuse check**"
has "$D" "**The reuse check is the one no other gate can substitute for.**"
# A hand-built component passes every OTHER gate -- that's why this one is needed:
has "$D" "passes lint, spec, a11y, fonts, and the pixel diff, because visually it *is*"
has "$D" "getMainComponentAsync"
has "$D" "Never skip it silently; it is the check that catches"
# Roll-up must be documented so the count is not read as the whole story:
has "$D" "**root** of each drifted subtree, not every node inside it"
has "$D" "Zero instances against a non-empty registry is the loudest signal"
# The gate call must carry the registry argument:
has "$D" 'bash scripts/gates.sh <nodeId> "<ComponentName>" [.claude/design/registry.md]'
# Reuse (step 3) must be checked BEFORE the build (step 4), and gated at step 5:
ordered "$D" "### 3. Reuse before building" "### 4. Build"
ordered "$D" "### 4. Build" "the \*\*reuse check\*\*"

echo "--- gates.sh runs the reuse check and passes --file to spec ---"
G=scripts/gates.sh
has "$G" 'REGISTRY="${3:-.claude/design/registry.md}"'
has "$G" "reuse-check.js"
has "$G" 'figma-cli spec "$COMPONENT" --check "$NODE_ID" --tolerance 2 --file "$REGISTRY"'
# Without --file, the spec gate silently never ran -- record why it is there:
has "$G" "auto-locate skips every dot-directory"
# Handles must come from the same headings `spec` parses, or gate and tool disagree:
has "$G" "grep '^### ' \"\$REGISTRY\""
has "$G" "GATE: reuse VIOLATION"
# A reuse error must fail the gate, like lint and spec:
has "$G" 'GATE_FAIL=1'
# sed delimiter must not be / -- component names contain slashes (vuesax/twotone/add):
has "$G" 's|__HANDLES__|$HANDLES|'
# Missing registry must be announced, never silently treated as "clean":
has "$G" "no registry at \$REGISTRY; reuse cannot be checked."
has "$G" "reuse-check.js not found; reuse NOT checked."

echo "--- reuse-check.js: correctness of the checks themselves ---"
R=scripts/reuse-check.js
# figma-cli run returns NOTHING when a file has leading // comments (FIGMA-CLI.md).
# The first line must therefore be the IIFE, not a comment.
if [ "$(head -1 "$R")" = "(async () => {" ]; then
  echo "  PASS: reuse-check.js opens with the IIFE (leading // comments break figma-cli run)"; PASS=$((PASS+1))
else
  echo "  FAIL: reuse-check.js must open with '(async () => {' — leading comments return empty output at exit 0"; FAIL=$((FAIL+1))
fi
nothas "$R" "^// "
# Nodes inside an INSTANCE are the design system's, not this build's:
has "$R" "Nodes inside an INSTANCE belong to that component, not to this build"
has "$R" "if (p.type === \"INSTANCE\") return true;"
# The root itself must be checked -- a hand-built component IS the root:
has "$R" "const owned = all.filter(n => !insideInstance(n));"
has "$R" "a builder hand-draws it AS the root"
# Variant names live on the main component, so compare the SET name, not the instance:
has "$R" "a variant's own"
has "$R" "COMPONENT_SET"
# Roll-up: report the root, and say how many were folded in:
has "$R" "const flagged = new Set();"
has "$R" "rolled up into the roots above"
# Shallowest-first ordering is what makes roll-up correct; a stack walk is not ordered:
has "$R" "Shallowest-first, so a parent is judged before its children"
# Empty registry must not report errors it then says it cannot check:
has "$R" "registry is empty — reuse NOT CHECKED."
has "$R" "return before counting them"
# An all-geometry build against a real registry is the loudest available signal:
has "$R" "this build is all geometry."
# Detached instances keep the variant name on a FRAME:
has "$R" "variant name on a FRAME — detached instance"

echo "--- taste: the registry must be built so that it PARSES ---"
T=skills/taste/SKILL.md
has "$T" "and **verify it parses**"
has "$T" "**\`mkdir -p\` the output directory first.**"
has "$T" "**Scope with \`--pages\`, and use a real page name.**"
has "$T" "grep -c '^Reuse:' .claude/design/registry.md"
# The three structural requirements a block needs to be seen at all:
has "$T" "needs a \`### Name\` heading, a \`· N variants\` line, and a \`Reuse:\` line"
has "$T" "A registry that exists but does not parse is worse than none"

echo "--- FIGMA-CLI.md records both gotchas with evidence ---"
F=skills/design/FIGMA-CLI.md
has "$F" "## \`spec\` and \`instantiate\` cannot see a registry in a dot-directory"
has "$F" "skips every entry beginning with \`.\`"
has "$F" "Sample variant structure:\`.** A \`.md\`"
has "$F" "**The two failure messages are indistinguishable in practice.**"
has "$F" "mechanism behind \"it keeps drifting from my components.\""
has "$F" "## \`extract\` needs its output directory to exist, and times out unscoped"
has "$F" "✖ Extraction failed: Connection timeout"
has "$F" "✔ 55,915 nodes, 42 components"

echo "--- ship: code drifts from components too ---"
S=skills/ship/SKILL.md
has "$S" "**Resolve every registry handle to a real import before writing any markup.**"
has "$S" "a second source of truth that will diverge on the next change"
has "$S" "treat an"
has "$S" "unresolved handle as a finding to report, not a component to write"
has "$S" "a re-implemented component where the project already has one"
# The per-component review must check imports, not appearance -- appearance passes:
has "$S" "check the"
has "$S" "imports, not the appearance"

echo "--- README documents the gate and the script ---"
has README.md "reuse-check.js"

echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
