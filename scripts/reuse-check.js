(async () => {
  /* Reuse gate: did this build INSTANCE the design system, or re-draw it?
   *
   * Why this exists: `design/SKILL.md` step 3 says "never rebuild what exists,"
   * but nothing verified it, so drift from the user's components was invisible.
   * A rebuilt Button looks right in every screenshot and passes every other
   * gate here — lint, spec, a11y, fonts, pixel diff — because it IS visually a
   * button. It is only wrong structurally: unlinked, so it never inherits a
   * design-system change, and it is the exact failure users report as
   * "it keeps drifting from my components."
   *
   * This reports only. Fixes belong to the builder, who knows the intent.
   *
   * NOTE: every comment here lives INSIDE the IIFE deliberately. `figma-cli run`
   * silently returns nothing — no output, no error, exit 0 — when a file carries
   * leading `//` comments before the opening `(async () => {`. See FIGMA-CLI.md.
   *
   * Usage: figma-cli run scripts/reuse-check.js
   *        (substitute __NODE_ID__ and __HANDLES__ first; __HANDLES__ is a
   *         comma-separated list of registry component names) */
  const NODE_ID = "__NODE_ID__";
  const HANDLES = "__HANDLES__";

  const root = await figma.getNodeByIdAsync(NODE_ID);
  if (!root) return "REUSE: node " + NODE_ID + " not found";

  /* Walk the subtree with an explicit stack. `findAll` on a node inside a large
   * file costs seconds (17.8s measured on a 56-node frame in a 57k-node doc). */
  const all = [];
  const stack = [root];
  while (stack.length) {
    const n = stack.pop();
    all.push(n);
    if (n.children) for (const c of n.children) stack.push(c);
  }

  /* Registry handles. A build in a project whose registry is empty has nothing
   * to drift FROM, so the gate stays silent rather than inventing findings. */
  const handles = HANDLES.split(",").map(s => s.trim()).filter(Boolean);

  const instances = all.filter(n => n.type === "INSTANCE");

  /* Nodes inside an INSTANCE belong to that component, not to this build. They
   * carry the component's own internal frame names and variant names, so
   * checking them reports the design system's structure as this build's drift.
   * Verified live: a correctly-instanced BottomNav produced three "detached
   * instance" findings from its own internal Tab= children. Same scoping rule
   * as lint-node.js check 5. */
  const insideInstance = (n) => {
    for (let p = n.parent; p; p = p.parent) if (p.type === "INSTANCE") return true;
    return false;
  };
  /* The root itself is included. Asked to build a "Composer" when the registry
   * already has one, a builder hand-draws it AS the root — excluding the root
   * makes exactly that case invisible. Verified live: a hand-built Composer
   * FRAME reported clean until the root was checked. When the root is an
   * INSTANCE it is not a FRAME, so it is skipped anyway. */
  const owned = all.filter(n => !insideInstance(n));

  /* Which registry components did this build actually instance? Resolve each
   * instance to its main component AND that component's set: a variant's own
   * name is "Style=Primary, Size=Small", never "Button" — comparing the
   * instance name to the handle would miss every variant in the system. */
  const usedSets = new Set();
  for (const inst of instances) {
    try {
      const main = await inst.getMainComponentAsync();
      if (!main) continue;
      usedSets.add(main.name.toLowerCase());
      if (main.parent && main.parent.type === "COMPONENT_SET") {
        usedSets.add(main.parent.name.toLowerCase());
      }
    } catch (e) { /* a broken link is reported below as an unresolved instance */ }
  }

  const findings = [];
  const fmt = (sev, n, msg) => sev + "  " + n.name.slice(0, 34).padEnd(36) + msg + "  [" + n.id + "]";

  /* Report the ROOT of each drifted subtree, not every node in it. A hand-built
   * "BottomNav" holding four detached "Tab=" children is one fix — instantiate
   * the parent — and the children come back with it. Verified live: suppressing
   * descendants turned 14 findings into 3 actual fixes on the same node.
   * An unbounded list also trains the reader to skim past the gate. */
  const flagged = new Set();
  const underFlagged = (n) => {
    for (let p = n.parent; p; p = p.parent) if (flagged.has(p.id)) return true;
    return false;
  };

  /* Shallowest-first, so a parent is judged before its children and can
   * suppress them. `owned` came off a stack walk, which is not depth-ordered. */
  const depthOf = (n) => { let d = 0; for (let p = n.parent; p; p = p.parent) d++; return d; };
  const ordered = owned.slice().sort((a, b) => depthOf(a) - depthOf(b));

  /* Each node yields at most one finding, most specific first. A detached
   * "Tab=Home" inside a hand-built "BottomNav" is one problem, not two, and
   * reporting it twice makes the count read as worse than the build is. */
  for (const n of ordered) {
    if (n.type !== "FRAME" && n.type !== "GROUP") continue;
    if (underFlagged(n)) continue;

    /* 1. A detached instance. Figma keeps the variant name in the node name
     *    when an instance is detached, so "Style=Primary, Size=Small" on a
     *    FRAME is a near-certain detach — silent, and permanent. */
    if (/^[A-Za-z][\w ]*=/.test(n.name)) {
      findings.push(fmt("ERROR", n, "variant name on a FRAME — detached instance"));
      flagged.add(n.id);
      continue;
    }

    /* 2. A frame named like a registry component, that is not an instance of
     *    it. This is the drift itself: the builder produced the shape by hand. */
    const nm = n.name.toLowerCase();
    for (const h of handles) {
      const hl = h.toLowerCase();
      /* Match whole-word-ish, so "ButtonRow" does not read as "Button" while
       * "Primary Button" and "Button / Large" still do. */
      const re = new RegExp("(^|[^a-z0-9])" + hl.replace(/[.*+?^${}()|[\]\\]/g, "\\$&") + "([^a-z0-9]|$)", "i");
      if (re.test(nm)) {
        findings.push(fmt("ERROR", n, "hand-built, but the registry has \"" + h + "\" — instantiate it"));
        flagged.add(n.id);
        break;
      }
    }
  }

  /* 3. An instance whose main component no longer resolves. Checked on every
   *    instance, including nested ones: a broken link inside a reused component
   *    still breaks this build's render. */
  for (const inst of instances) {
    try {
      const main = await inst.getMainComponentAsync();
      if (!main) findings.push(fmt("WARN", inst, "instance with no resolvable main component"));
    } catch (e) {
      findings.push(fmt("WARN", inst, "main component lookup failed: " + e.message));
    }
  }

  /* With no handles, findings are not meaningful — return before counting them,
   * so the header cannot report errors the body then says it cannot check. */
  if (!handles.length) {
    return [
      "REUSE (scoped to " + NODE_ID + ", " + all.length + " nodes): " +
        instances.length + " instance(s), " + usedSets.size + " distinct component(s) reused",
      "  registry is empty — reuse NOT CHECKED.",
      "  Composed output is impossible without handles; expect generated geometry.",
      "  If the project has a design system, the registry failed to build — see taste/SKILL.md.",
    ].join("\n");
  }

  const errors = findings.filter(f => f.startsWith("ERROR"));
  const lines = [
    "REUSE (scoped to " + NODE_ID + ", " + all.length + " nodes, " +
      owned.length + " authored here): " +
      instances.length + " instance(s), " +
      usedSets.size + " distinct component(s) reused, " +
      errors.length + " error(s), " + (findings.length - errors.length) + " warning(s)",
  ];

  lines.push("  registry handles given: " + handles.length);
  if (findings.length) lines.push(...findings.map(f => "  " + f));

  /* Name what was rolled up. A gate that quietly collapses findings reads as a
   * cleaner build than it is — the opposite of the point. */
  const suppressed = owned.filter(n =>
    (n.type === "FRAME" || n.type === "GROUP") && !flagged.has(n.id) && underFlagged(n)).length;
  if (suppressed) {
    lines.push("  (" + suppressed + " descendant node(s) rolled up into the roots above — " +
      "re-run after instancing to confirm they resolve)");
  }

  /* An all-geometry build against a non-empty registry is the loudest signal
   * available: the design system was present and went entirely unused. */
  if (!instances.length) {
    lines.push("  ERROR  zero instances in the whole subtree, against a registry of " +
      handles.length + " component(s) — this build is all geometry.");
  } else if (!findings.length) {
    lines.push("  clean — reused: " + [...usedSets].slice(0, 12).join(", "));
  }

  return lines.join("\n");
})();
