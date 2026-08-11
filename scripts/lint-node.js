(async () => {
  /* Scoped lint: the checks `figma-cli lint` performs, restricted to one subtree.
   *
   * Why this exists: `figma-cli lint` has no scoping flag and ignores the current
   * selection — it always walks the whole file. Measured on a 57,158-node design
   * system it took 36-41s and then failed with a CDP timeout, so it cannot serve
   * as a gate there. Worse, `lint --fix` at that scope would rewrite the entire
   * design system to "fix" a single new frame.
   *
   * This reports only. Fixes belong to the builder, who knows the intent.
   *
   * NOTE: every comment here lives INSIDE the IIFE deliberately. `figma-cli run`
   * silently returns nothing — no output, no error, exit 0 — when a file carries
   * leading `//` comments before the opening `(async () => {`. Verified by
   * stripping an 11-line header from an otherwise byte-identical file: header
   * present = empty output, header removed = correct output.
   *
   * Usage: figma-cli run scripts/lint-node.js  (substitute __NODE_ID__ first) */
  const NODE_ID = "__NODE_ID__";
  const root = await figma.getNodeByIdAsync(NODE_ID);
  if (!root) return "LINT: node " + NODE_ID + " not found";

  const findings = [];
  const add = (sev, node, msg) => findings.push({ sev, id: node.id, name: node.name, msg });

  const SPACING = [0, 2, 4, 8, 12, 16, 20, 24, 32, 40, 48, 56, 64, 72, 80, 96];
  const onScale = (v) => SPACING.includes(Math.round(v));

  // Walk the subtree directly. `findAll` on a node inside a large file costs
  // seconds (17.8s measured on a 56-node frame in a 57k-node document); an
  // explicit stack walk of the same subtree is milliseconds.
  const all = [];
  const stack = [root];
  while (stack.length) {
    const n = stack.pop();
    all.push(n);
    if (n.children) for (const c of n.children) stack.push(c);
  }

  for (const n of all) {
    // 1. Unbound colors — the rule TASTE.md states most strictly.
    for (const key of ["fills", "strokes"]) {
      const paints = n[key];
      if (!Array.isArray(paints)) continue;
      paints.forEach((p, i) => {
        if (p.type !== "SOLID" || p.visible === false) return;
        const bound = n.boundVariables && n.boundVariables[key] && n.boundVariables[key][i];
        if (!bound) add("ERROR", n, "unbound " + key.slice(0, -1) + " (raw color, no variable)");
      });
    }

    // 2. Off-scale spacing in auto-layout.
    if (n.layoutMode && n.layoutMode !== "NONE") {
      for (const k of ["itemSpacing", "paddingTop", "paddingRight", "paddingBottom", "paddingLeft"]) {
        const v = n[k];
        if (typeof v === "number" && v !== 0 && !onScale(v)) {
          add("WARN", n, k + "=" + v + " is off the 4-based scale");
        }
      }
    }

    // 3. Empty icon frames — a failed <Icon> lookup renders zero children at exit 0.
    if (n.type === "FRAME" && n.children && n.children.length === 0) {
      const looksIconic = /icon|logo|indicator|sparkle|burger|menu|avatar/i.test(n.name);
      const small = n.width <= 64 && n.height <= 64;
      if (looksIconic || small) add("ERROR", n, "empty frame " + Math.round(n.width) + "x" + Math.round(n.height) + " (failed icon lookup?)");
    }

    // 4. Detached instances of registry components.
    if (n.type === "FRAME" && /button|input|card|badge|chip|avatar|toggle/i.test(n.name)) {
      add("WARN", n, "named like a registry component but is a FRAME, not an INSTANCE");
    }

    // 5. Text nodes with no explicit line-height.
    if (n.type === "TEXT" && n.lineHeight && n.lineHeight.unit === "AUTO" && n.fontSize >= 20) {
      add("WARN", n, "display text at " + n.fontSize + "pt uses AUTO line-height");
    }
  }

  const errors = findings.filter(f => f.sev === "ERROR");
  const warns = findings.filter(f => f.sev === "WARN");
  const fmt = (f) => "  " + f.sev + "  " + f.name.slice(0, 30).padEnd(32) + f.msg + "  [" + f.id + "]";
  const lines = [
    "LINT (scoped to " + NODE_ID + ", " + all.length + " nodes): " +
      errors.length + " error(s), " + warns.length + " warning(s)",
  ];
  if (errors.length) lines.push(...errors.map(fmt));
  if (warns.length) lines.push(...warns.map(fmt));
  if (!findings.length) lines.push("  clean");
  return lines.join("\n");
})();
