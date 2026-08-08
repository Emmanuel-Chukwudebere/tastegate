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

Correct and re-verify, maximum 3 passes, then report residual deltas.

**If the diff cannot run** (no dev server, Playwright unavailable): emit the code,
then state plainly that visual verification **did not run**. Never imply measured
fidelity that was not measured.

### 8. Round-trip check
Run `design/RUBRIC.md` against the built result, so code is held to the
standard the design was held to.

## Token round trip

Tokens travel both directions by tool, never by retyping:

```
Figma variables ──export css/tailwind/dtcg──▶ code
code tokens ─────import tokens.json/globals.css──▶ Figma variables
```

If code and Figma drift, the shared token namespace makes it detectable and
correctable in whichever direction it appeared.
