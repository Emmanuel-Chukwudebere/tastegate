---
name: ship
description: Use when converting a Figma design into code, implementing a design in React or another framework, when the user asks to build the design for real, or when they want the design turned into components.
---

# Ship

Converts a Figma design into production code with measured fidelity, in the
framework the project already uses.

Argument: an optional target — `react` (default), `vue`, `svelte`,
`react-native`, `html`.

## Locating standards

A standard named without a path sits beside this SKILL.md — read it directly.
A standard named `<skill>/<FILE>` (for example `design/MOTION.md`) belongs to
a sibling skill: look beside this SKILL.md first, then in that sibling
skill's own directory (`../design/MOTION.md` under a full plugin install, or
wherever the harness installed that skill). This skill ships with its own
directory only under a single-skill install, so `design/MOTION.md` and
`design/RUBRIC.md` may be absent — if so, say so once, apply the rule stated
inline in this skill, and continue. Never fail, and never silently skip a
check while implying it ran.

## Preconditions

1. Read `FRAMEWORKS.md`. **Detect** the project's framework and styling
   system from `package.json` and existing components before asking. Never
   introduce a second styling paradigm into a project that has one.
2. Read `.claude/design/TASTE.md` and `registry.md`.
3. If the requested target is unsupported, say which are supported and stop.

## Order of operations

Motion and library decisions come **first**, because deciding them after writing
components is what produces fragile hand-rolled toasts and unjustified animation.

### 1. `find-animation-opportunities`
Invoke it on the design. Output: what should animate, and explicitly what must
not. The frequency matrix in `design/MOTION.md` governs — keyboard-initiated
actions never animate.

### 2. `pick-ui-library`
Invoke it before writing any component.
Never hand-roll a toast, drawer, popover, dialog, or combobox — hand-rolled
versions reliably carry accessibility, z-index, and focus-management defects.

### 3. Extract and export mechanically
See `emit.md`. In short:

```bash
figma-cli extract --selection                 # structure + bound tokens + Auto Layout
figma-cli export-jsx <nodeId> --pretty        # structural scaffold
figma-cli export css                          # or: export tailwind | export dtcg tokens.json
figma-cli export-storybook <nodeId>           # if the project uses Storybook
```

Structure and values come from the tool. **Never retype a token value.**

### 4. Emit
Write the component in the target framework, referencing the exported variables.
Zero raw hex, zero magic numbers. Map registry handles to existing project
components.

Generate every interaction state — see `states.md`. A Figma frame
contains almost none of them, and their absence is what makes converted code feel
unfinished.

**Dispatch a review as each component lands, not once at the end.** Step 8 audits the
whole result; that is too late to be cheap. A defect found while the component is the
thing you are working on costs an edit — the same defect found after three more
components depend on it costs a refactor.

Send one **background** sub-agent per component as you finish it (model **sonnet**),
and keep emitting while it runs. Wall-clock stays the slowest single review rather than
their sum, and the findings arrive while the context is still warm. What it checks —
things a pixel diff cannot see:

- **placeholders that render fine**: a stand-in image URL, lorem copy, a `#TODO` href,
  a hardcoded value where a token belongs. These survive every visual check because
  they *look* correct. One shipped hero kept a stand-in Unsplash URL past a full
  fidelity pass for exactly this reason.
- **states that exist in `states.md` and not in the code**
- **a second styling paradigm** entering a project that already has one
- **tokens retyped rather than referenced**

Two rules keep this from becoming the 195-call audit: give each one a **tool-call
budget**, and tell it **not to re-derive** what the export already established.

**On a single-component job, skip this** and let step 8 do the work — one component
does not need an incremental pass on top of a final one.

### 5. `animate`
Invoke it to author each animation warranted by step 1, with correct curve,
duration, property, interruption, and exit. Values from `design/MOTION.md`.

**If `TASTE.md` calls for a native feel** — direct manipulation, velocity
handoff, translucent materials — invoke `apple-design` alongside `animate` for
that component's motion and depth treatment.

### 6. `review-animations`
Invoke it on the emitted code as an adversarial audit.

### 7. Verify fidelity by measurement
Screenshot the built UI at the same viewport as the Figma frame and diff against
the frame screenshot:

- Render the app (dev server), then Playwright `browser_navigate` +
  `browser_take_screenshot` at the Figma frame's width.
- Compare against the frame screenshot from `render --verify` or
  `figma-cli verify <nodeId>`.
- Findings are geometric: spacing deltas, type-size mismatches, color drift.

**Read `design/TEXT-GEOMETRY.md` before diffing vertical positions.** Figma's
`node.y` and CSS's `getBoundingClientRect().top` are different reference lines:
Figma AUTO line-height and CSS `line-height` compute different box heights (measured
−12px to +9px at 105pt, depending on which CSS form), and CSS adds half-leading that
Figma has none of (11px at 105pt from line-height alone). Both errors are per-node
and scale with font size, so they **accumulate down a flex column and can flip sign
partway**, which no constant offset can correct. Compare **ink to ink** — cap-top to
cap-top — never box to box. Best is to prevent it: set an explicit pixel
line-height on both sides so the boxes match by construction.

**Converged means stop: ±8pt position, ±3pt cap-height** — the same band `design`
uses. Inside it, record the residual and move on. A measurement always returns a
non-zero delta, so without a stated tolerance every comparison reads as actionable
and the loop never ends; one hero spent ~20 measure-adjust rounds closing deltas
from 30pt to 5pt, long past visibility.

**At most 2 correction rounds between diffs**, maximum 3 diff passes. Then report
residual deltas.

**A delta that will not close after one correction is a signal to re-read the
comparison, not to correct harder.** Unclosable deltas are usually the reference-line
artifact above. Check whether the delta accumulates with depth or scales with font
size before adjusting geometry a second time.

**If the diff cannot run** (no dev server, Playwright unavailable): emit the code,
then state plainly that visual verification **did not run**. Never imply measured
fidelity that was not measured.

### 8. Round-trip check — dispatch a sub-agent
Dispatch per `design/RUNTIMES.md` with `design/qa-brief.md` as the brief, scoring all
eight `design/RUBRIC.md` dimensions against the built result — so code is held to the
standard the design was held to. Model: **sonnet**; escalate to **opus** on the same
condition (one dimension ≤ 2 on two consecutive passes).

**Dispatch it, do not run it inline.** Reviewing your own emitted code in the context
that wrote it is the weakest possible audit: the reasoning that produced a defect is
still resident and reads as justification. A fresh context sees the code as a reader
does. It is also the cheap path — the diff screenshots and standards load in the
sub-agent, and only findings come back.

The brief needs three things this stage has and `design` does not:

- **the emitted file paths**, so the audit reads code and not only pixels
- **the residual deltas from step 7**, with the tolerance band — otherwise it
  re-reports a converged 5pt gap as a finding
- **the states from `states.md`**, since a screenshot shows one state and the other
  seven are exactly where converted code fails

**Without sub-agent support**, run it inline and say so — the rubric supplies the
quality, isolation supplies the cost saving and the fresh eyes.

## Token round trip

Tokens travel both directions by tool, never by retyping:

```
Figma variables ──export css/tailwind/dtcg──▶ code
code tokens ─────import tokens.json/globals.css──▶ Figma variables
```

If code and Figma drift, the shared token namespace makes it detectable and
correctable in whichever direction it appeared.
