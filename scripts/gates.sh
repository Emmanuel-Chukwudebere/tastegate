#!/usr/bin/env bash
# Deterministic quality gates. Runs BEFORE any model-based critique so the
# expensive pass never spends attention on tool-detectable defects.
# Usage: gates.sh [nodeId] [component-name]
set -uo pipefail
NODE_ID="${1:-}"
COMPONENT="${2:-}"
GATE_FAIL=0
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Scratch dir for generated scripts. Do NOT use `mktemp` here: on Git Bash it
# returns a POSIX path like /tmp/foo.js, which the shell resolves to C:\tmp but
# hands to figma-cli — a Windows Node process — as a literal, unresolvable path.
# The script then silently reads as empty and the gate reports nothing at all.
# Same root cause as the `verify` writes-to-/tmp gotcha in FIGMA-CLI.md.
# Resolve one directory that BOTH the shell and a Windows Node process can open.
# $TEMP arrives as a backslashed Windows path that the shell cannot redirect into,
# while a bare /tmp is a POSIX path that figma-cli cannot resolve — so convert
# explicitly in each direction rather than trusting either form.
# Pick the shell-side directory FIRST, then convert that exact path for figma-cli.
# Converting in the other order silently splits them: on Git Bash `cygpath -u "$TEMP"`
# returns /tmp, and `cygpath -m /tmp` maps back to the Windows Temp — two different
# directories, so the shell writes one file and figma-cli reads another that is not
# there. It reads as empty, and the gate reports nothing while appearing to pass.
SCRATCH_SH="${TMPDIR:-/tmp}"
mkdir -p "$SCRATCH_SH" 2>/dev/null || true
if command -v cygpath >/dev/null 2>&1; then
  SCRATCH_WIN="$(cygpath -m "$SCRATCH_SH" 2>/dev/null || echo "$SCRATCH_SH")"
else
  SCRATCH_WIN="$SCRATCH_SH"
fi

# Every gate below is scoped to NODE_ID. `figma-cli lint` is deliberately not used:
# it has no scoping flag and ignores the current selection, so it always walks the
# whole file. Measured against a 57,158-node design system it took 36-41s and then
# died with a CDP timeout — and `lint --fix` at that scope would rewrite the entire
# design system to "fix" one new frame. scripts/lint-node.js performs the same
# checks over one subtree in ~2s.
if [ -z "$NODE_ID" ]; then
  echo "GATE: no nodeId given — every gate here is scoped, so nothing can run."
  echo "GATE: usage: gates.sh <nodeId> [component-name]"
  exit 1
fi

echo "GATE: lint (scoped to $NODE_ID)"
LINT_SRC="$HERE/lint-node.js"
if [ -f "$LINT_SRC" ]; then
  LINT_RUN_SH="$SCRATCH_SH/gate-lint-$$.js"; LINT_RUN="$SCRATCH_WIN/gate-lint-$$.js"
  sed "s/__NODE_ID__/$NODE_ID/" "$LINT_SRC" > "$LINT_RUN_SH"
  LINT_OUT="$(figma-cli run "$LINT_RUN" 2>&1)"
  echo "$LINT_OUT"
  rm -f "$LINT_RUN_SH"
  # An unbound color is the rule TASTE.md states most strictly, so treat it as fatal.
  if echo "$LINT_OUT" | grep -q "ERROR"; then
    echo "GATE: lint found errors — fix before critique is worth running."
    GATE_FAIL=1
  fi
else
  echo "GATE: lint-node.js not found; skipping scoped lint (do NOT substitute whole-file lint)."
fi

if [ -n "$COMPONENT" ]; then
  echo "GATE: spec --check $COMPONENT against $NODE_ID"
  if figma-cli spec "$COMPONENT" --check "$NODE_ID" --tolerance 2; then
    echo "GATE: spec OK"
  else
    echo "GATE: spec VIOLATION - build is off-spec. Fix before critique."
    GATE_FAIL=1
  fi
else
  echo "GATE: spec --check skipped (no component given)"
fi

# Contrast and target size are thresholds, not preferences: WCAG AA (4.5:1 body,
# 3:1 large text and UI components) and WCAG 2.5.8 (24x24 minimum). A failure here
# is reported as a CONFLICT per skills/design/CONFLICT.md when TASTE.md itself is
# the cause — the user decides — so this gate surfaces it rather than exiting 1 and
# stalling a build over a brand color the user has already accepted.
echo "GATE: a11y audit (scoped to $NODE_ID)"
A11Y_OUT="$(figma-cli a11y audit "$NODE_ID" 2>&1)"
echo "$A11Y_OUT"
if echo "$A11Y_OUT" | grep -qiE "fail|below|insufficient|too small"; then
  echo "GATE: a11y FINDINGS - if TASTE.md is the cause, raise a CONFLICT (measured value,"
  echo "GATE: a11y threshold, smallest brand-preserving fix) rather than silently shipping or overriding."
fi

# Fonts: a family that never binds stays Inter, and `render` exits 0 either way.
# Free to detect here; expensive to have a model notice later.
echo "GATE: font bindings"
FONT_RUN_SH="$SCRATCH_SH/gate-font-$$.js"; FONT_RUN="$SCRATCH_WIN/gate-font-$$.js"
cat > "$FONT_RUN_SH" <<EOF
(async () => {
  const root = await figma.getNodeByIdAsync("$NODE_ID");
  if (!root) return "FONT: node not found";
  const all = []; const st = [root];
  while (st.length) { const n = st.pop(); all.push(n); if (n.children) for (const c of n.children) st.push(c); }
  const texts = all.filter(n => n.type === "TEXT");
  const fams = {};
  for (const t of texts) {
    const k = t.fontName.family + " " + t.fontName.style;
    fams[k] = (fams[k] || 0) + 1;
  }
  const inter = texts.filter(t => t.fontName.family === "Inter");
  // Count distinct families. Text inside a reused DS component instance keeps that
  // system's font, so a frame can pass a "no Inter" check while still mixing two or
  // three families — found live: the CTA label came through as Syne and the avatar
  // initials as Plus Jakarta Sans inside an otherwise all-Outfit hero.
  const distinct = [...new Set(texts.map(t => t.fontName.family))];
  const inInstance = texts.filter(t => {
    let p = t.parent;
    while (p) { if (p.type === "INSTANCE") return true; p = p.parent; }
    return false;
  });
  const instFams = [...new Set(inInstance.map(t => t.fontName.family))];
  return "FONT: " + texts.length + " text node(s), " + distinct.length + " famil" + (distinct.length === 1 ? "y" : "ies") + "\n" +
    Object.entries(fams).map(([k, v]) => "  " + v + "x  " + k).join("\n") +
    (instFams.length ? "\nFONT: inside component instances: " + instFams.join(", ") : "") +
    (distinct.length > 1 ? "\nFONT: MIXED FAMILIES — " + distinct.join(" + ") + ". Reconcile against TASTE.md before shipping." : "") +
    (inter.length ? "\nFONT: INTER PRESENT on " + inter.length + " node(s) — a font that never bound." : "\nFONT: no Inter present.");
})();
EOF
FONT_OUT="$(figma-cli run "$FONT_RUN" 2>&1)"
echo "$FONT_OUT"
rm -f "$FONT_RUN_SH"
if echo "$FONT_OUT" | grep -q "INTER PRESENT"; then
  echo "GATE: font VIOLATION - unbound font. Load the family, then assign, per FIGMA-CLI.md."
  GATE_FAIL=1
fi
if echo "$FONT_OUT" | grep -q "MIXED FAMILIES"; then
  echo "GATE: font MIXED - reused component instances carry their own type. Override or accept explicitly."
  GATE_FAIL=1
fi

# A node with visible=false exports a ~149-byte transparent PNG and still exits 0,
# so the screenshot the QA pass judges can be blank with no signal anywhere.
echo "GATE: export not blank"
SHOT="$SCRATCH_SH/gate-shot-$$.png"
SHOT_WIN="$SCRATCH_WIN/gate-shot-$$.png"
figma-cli export node "$NODE_ID" --scale 2 -o "$SHOT_WIN" >/dev/null 2>&1
SHOT_BYTES="$(wc -c < "$SHOT" 2>/dev/null || echo 0)"
if [ "${SHOT_BYTES:-0}" -lt 1000 ]; then
  echo "GATE: export BLANK (${SHOT_BYTES} bytes) - check node.visible via 'figma-cli get $NODE_ID'."
  GATE_FAIL=1
else
  echo "GATE: export OK (${SHOT_BYTES} bytes)"
fi
rm -f "$SHOT"

exit "$GATE_FAIL"
