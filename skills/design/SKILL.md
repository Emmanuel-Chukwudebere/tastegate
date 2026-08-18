---
name: design
description: Use when building or reshaping UI in Figma, creating screens or components, or when the user asks for a design, layout, or interface in a project that has a taste profile.
license: MIT
metadata:
  author: Emmanuel Chukwudebere
  homepage: https://github.com/Emmanuel-Chukwudebere/tastegate
---

# Design

Composes UI in Figma from the project's registry and taste profile, checks its own
output, and only then shows the result.

## Locating standards

A standard named without a path sits beside this SKILL.md — read it directly.
A standard named `<skill>/<FILE>` belongs to a sibling skill: look beside this
SKILL.md first, then in that sibling skill's own directory (for example
`../design/RUBRIC.md` under a full plugin install, or wherever the harness
installed that skill). A single-skill install ships only this directory, so a
sibling standard may be absent — when that happens, say so once, apply the
rule stated inline in this skill, and continue. Never fail, and never
silently skip a check while implying it ran.

## Preconditions

1. Run `bash scripts/preflight.sh`. Stop on hard failure. **Without `scripts/`**
   (a single-skill install), run its checks directly: `figma-cli --version`,
   `figma-cli status`, and **`figma-cli daemon status`** (all hard — stop if any
   fails). The daemon check is not optional: a stale token makes every `eval`/`run`
   cost ~20s instead of ~3s, and `status` reports `Connected` anyway. Also check whether
   `~/.claude/skills/emil-design-eng` or `~/.agents/skills/emil-design-eng`
   exists (soft), and whether `playwright` and `figma-use` resolve via `npm root
   -g` (soft — both are optional dependencies).
2. Read `.claude/design/TASTE.md`. **If it does not exist, refuse** and direct the
   user to `/tastegate:taste`. Grounding is mandatory — building without it
   produces exactly the untethered output this plugin exists to prevent.
3. Read `.claude/design/registry.md`. If empty, warn that output will be generated
   rather than composed, then proceed.
4. Read `FIGMA-CLI.md` for the JSX dialect before writing any JSX.

## Loop

### 1. Load
`TASTE.md` and `registry.md`. Work from handles, not node trees.

### 2. Plan
Do this in thinking, not in output — it is cheap to discard. Produce a compact
plan: the tokens this screen uses, an ASCII wireframe, and the signature element
from `TASTE.md`.

Review the plan against `SLOP.md` before building. If any part reads as the
generic default you would produce for any similar brief, revise it and say what
you changed and why.

**Then check the profile against usability thresholds — see `CONFLICT.md`.** Where
`TASTE.md` requires something that crosses a measurable line (contrast below WCAG
AA, targets under 24×24, transitions over 300ms, motion with no reduced-motion
path), raise it now with the measured value, the threshold, and the smallest fix
that holds the brand — then let the user decide. Batch every conflict into one
message before building, never one interrupt per finding.

**Only measurable conflicts.** If you cannot name the threshold and the measured
value, it is a preference, not a finding — and the profile wins. A brand that looks
unlike your defaults is the point of grounding, not a defect to correct.

### 3. Reuse before building
For every element, check the registry first — and **always pass `--file`**:

```bash
figma-cli spec "<ComponentName>" --file .claude/design/registry.md        # does a handle exist?
figma-cli instantiate "<ComponentName>" --file .claude/design/registry.md # if yes, use it
```

**`--file` is mandatory, not a convenience.** Both commands auto-locate a
`DESIGN.md` by scanning cwd and one level of subdirectories — and that scan
**skips every dot-directory**, which is exactly where this plugin writes its
registry. Verified live: with a valid 42-component registry at
`.claude/design/registry.md`, the bare `figma-cli spec "Button"` printed
`✗ No DESIGN.md found` while the same call with `--file` returned the full
60-variant spec.

**That failure is the drift.** `✗ No DESIGN.md found` and
`✗ No component matching "Button"` are both a red `✗` at exit 1, so "the registry
is unreachable" is indistinguishable from "this component does not exist" — and the
reasonable next step for both is to build it by hand. The design system is never
consulted, and every build re-draws what already exists.

**Never rebuild what exists.** Composing by handle costs a fraction of emitting
geometry, and keeps the component tree linked so the build inherits later
design-system changes.

**A `✗` from either command is a stop, not a signal to build.** Distinguish the two
causes before proceeding: if `--file` points at a real file and the component is
genuinely absent, say so and build it; if the registry is missing or unparseable,
that is a `/taste` problem — fix it there rather than hand-building around it.

### 4. Build
```bash
figma-cli render-batch '["<Frame>…</Frame>","<Frame>…</Frame>"]' --verify
```

`--verify` returns a screenshot in the same call, so seeing the result costs no
extra round trip. Bind every color to a token: `bg="var:surface"`, never `bg="#fff"`.
Resolve real variable names with `figma-cli var list` before writing a `var:`
reference — `export css`'s hyphenated names (`--neutral-900`) are not valid
`var:` targets; the slash form (`var:neutral/900`) is, per `FIGMA-CLI.md`.

Use `<Icon name="prefix:name">` with the set from `TASTE.md`. **`<Icon>` resolves through
Iconify only** — a local component name, a wrong prefix, or a set Iconify does not carry
all render as an empty frame or a filled square, with no warning and exit 0. For a local
component use `createInstance()` via `eval`; for an unhosted glyph use
`figma.createNodeFromSvg`. Both are documented in `FIGMA-CLI.md`. Never hand-draw paths,
and **never substitute a different icon variant** to work around a lookup failure — the
profile pins the variant.

**Assert the icon children after rendering.** A zero-child icon frame is the signature of
a failed lookup and is invisible in the render's own output.

### 5. Gate — deterministic, before any model critique
```bash
bash scripts/gates.sh <nodeId> "<ComponentName>" [.claude/design/registry.md]
```

This runs a scoped lint, the **reuse check**, `spec --check`, `a11y audit`, and the
font check — all five in ~7s, all free and exact. **A `spec --check` failure is a
hard stop, not a finding** — the build is off-spec; fix it before critique is worth
running.

**The reuse check is the one no other gate can substitute for.** A hand-built
`Button` passes lint, spec, a11y, fonts, and the pixel diff, because visually it *is*
a button — it is wrong only structurally: unlinked, so it never inherits a
design-system change. `scripts/reuse-check.js` resolves every INSTANCE to its main
component and flags any frame named like a registry handle that is not one, plus any
detached instance (a variant name such as `Tab=Home` sitting on a FRAME). It reports
the **root** of each drifted subtree, not every node inside it, and names how many
descendants it rolled up.

Zero instances against a non-empty registry is the loudest signal it emits: the
design system was available and went entirely unused.

**Without `scripts/`**, run the reuse check as an `eval` walk of the subtree —
resolve each INSTANCE with `getMainComponentAsync()` and compare frame names against
the registry's `### ` headings. Never skip it silently; it is the check that catches
drift from the user's own components.

**Never gate with `figma-cli lint`.** It has no scoping flag and ignores the current
selection, so it always walks the whole document: measured at 36–41s and then a
`CDP timeout` on a 57,158-node file, and `lint --fix` at that scope would rewrite the
entire design system to fix one frame. `scripts/lint-node.js` runs the same checks over
one subtree in ~2s. **Without `scripts/`**, run `a11y audit <nodeId>` and
`spec <component> --check <nodeId>` directly, and do the lint checks with an `eval`
walk of the subtree — never substitute the whole-file `lint`.

**An unresolved-variable warning from `render` is a build failure, not a
cosmetic warning.** It is free to detect from the command's own output, so
fix it before the QA pass — never let it reach the QA model or the user.

**Also gate the font bindings.** Weight keywords and numerics are per-family, and
a wrong form falls back to Inter silently — `render` still exits 0 (see
`FIGMA-CLI.md`). This is mechanically detectable, so detect it here rather than
paying a model to notice it:

```bash
figma-cli run <script>   # assert every TEXT node's fontName matches TASTE.md
```

The script walks the rendered frame and reports any `fontName.family` outside the
profile's declared families. An unexpected family is a **hard stop** — Inter
arriving uninvited is the "generic type" entry in `SLOP.md`, and letting it reach
the QA pass wastes the expensive pass on a free check.

Hand the gate's output to the QA pass as established fact. Every fact the sub-agent
must re-derive costs a tool call and wall-clock; the gate already knows the fonts,
the token bindings, the contrast ratios, and the node geometry.

Running the model before this gate would pay Sonnet to find what `lint` finds free.

### 6. QA — dispatch a sub-agent, overlapped not blocking
Dispatch per `RUNTIMES.md` using
`qa-brief.md` as the brief. Model: **sonnet**. The screenshot and
standards load in the sub-agent's context; only findings return here. Do not read
the screenshot into this context.

**Dispatch in the background and keep building.** A blocking QA pass makes the user
wait through the whole audit before seeing anything. Send the first frame to QA the
moment it renders and gate-passes, then build the next frame while that audit runs.
Collect findings as they return.

Where a build has several frames — breakpoints, states, variants — this turns a
serial chain into a pipeline: the wall-clock becomes the slowest single audit rather
than the sum of all of them. Measured on a three-breakpoint hero, a single blocking
audit of all three frames took 144 minutes and 195 tool calls; the same work
overlapped and pre-supplied with gate facts is a fraction of that.

**Pass the reference image alongside the build.** The QA pass judges by comparing two
pictures, so give it both: the `--verify` screenshot and whatever the direction was
arrived at from — the reference site capture from `/taste`, the moodboard, or the
winning `/explore` frame. Without the reference it can only check rules; with it, it
can tell you the build missed the direction, which is the finding that matters most.

Keep the reference captures from intake rather than discarding them. `/taste` saves a
screenshot per breakpoint precisely so this comparison is possible later.

**Feed the gate's findings into the brief.** The sub-agent should never spend calls
re-deriving what step 5 already measured — fonts, token bindings, contrast ratios,
node geometry. State them as fact and let it spend its budget on judgement.

Told to score eight dimensions with no budget and no reference, an audit will go
measuring — one such pass spent 195 tool calls probing properties the gate had
already established. The instruction that fixes this is explicit: **look at the
images, do not probe.**

**Cap the audit.** Give the sub-agent a tool-call budget in the brief and tell it to
report what it has when the budget is spent. An audit with no ceiling will keep
finding smaller things until it runs out of context, and the marginal finding is
worth far less than the wall-clock it costs.

### 7. Fix and re-verify
Apply the findings, re-render, re-gate. **Maximum 3 QA passes.** Escalate to opus
when `RUBRIC.md`'s condition is met (the same dimension ≤ 2 twice). On exit after
3 passes, report remaining findings rather than looping silently.

**Converged means stop: ±8pt position, ±3pt cap-height.** Inside that band the build
matches the reference — record the residual and move on. A measurement always returns
a non-zero delta, so without a stated tolerance every comparison reads as actionable
and the loop never ends. Measured live: one hero spent roughly 20 measure-adjust-export
rounds closing deltas from 30pt to 5pt, long past the point the difference was visible.

**At most 2 geometry-correction rounds between QA passes.** The 3-pass cap governs the
auditor; this one governs you. After the second round, ship what you have and report
what is still off, with its number.

**Derive type size from one rendered probe, never from a cap-height ratio.** Cap-height
divided by an assumed 0.72 is wrong per family and costs a round per iteration. Render
the string once at a known size, measure the cap-height that came back, then scale:
`size = probeSize × (targetCap / measuredCap)`. One round instead of four — the same
hero converged 50 → 41 → 34pt across three wasted rounds before landing where a single
probe would have put it.

### 8. Show
Only now present the result. The user sees post-QA work.

## On failure

- Figma unreachable → stop with instructions; never proceed blind.
- Bad build → `figma-cli undo`.
- `--verify` returned no screenshot → try `figma-cli verify <nodeId>`; if that also
  fails, say plainly that the visual QA pass could not run.
- Sub-agent failed → surface it. Never silently skip QA.
