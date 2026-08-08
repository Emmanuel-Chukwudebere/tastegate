---
name: design
description: Use when building or reshaping UI in Figma, creating screens or components, or when the user asks for a design, layout, or interface in a project that has a taste profile.
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
   (a single-skill install), run its checks directly: `figma-cli --version` and
   `figma-cli status` (hard — stop if either fails), whether
   `~/.claude/skills/emil-design-eng` or `~/.agents/skills/emil-design-eng`
   exists (soft), and whether `playwright` and `figma-use` resolve via `npm root
   -g` (soft — both are optional dependencies).
2. Read `.claude/design/TASTE.md`. **If it does not exist, refuse** and direct the
   user to `/claude-design:taste`. Grounding is mandatory — building without it
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

### 3. Reuse before building
For every element, check the registry first:

```bash
figma-cli spec "<ComponentName>"        # does a handle exist?
figma-cli instantiate "<ComponentName>" # if yes, use it
```

**Never rebuild what exists.** Composing by handle costs a fraction of emitting
geometry, and keeps the component tree linked.

### 4. Build
```bash
figma-cli render-batch '["<Frame>…</Frame>","<Frame>…</Frame>"]' --verify
```

`--verify` returns a screenshot in the same call, so seeing the result costs no
extra round trip. Bind every color to a token: `bg="var:surface"`, never `bg="#fff"`.
Resolve real variable names with `figma-cli var list` before writing a `var:`
reference — `export css`'s hyphenated names (`--neutral-900`) are not valid
`var:` targets; the slash form (`var:neutral/900`) is, per `FIGMA-CLI.md`.

Use `<Icon name="prefix:name">` with the set from `TASTE.md`, or `<SVG>` for an
unhosted set. Never hand-draw paths.

### 5. Gate — deterministic, before any model critique
```bash
bash scripts/gates.sh <nodeId> "<ComponentName>"
```

This runs `lint --fix`, `spec --check`, and `a11y audit`. All are free and exact.
**A `spec --check` failure is a hard stop, not a finding** — the build is off-spec;
fix it before critique is worth running. **Without `scripts/`**, run the same
three `figma-cli` calls directly in that order — nothing in `gates.sh` beyond
composing them.

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

### 8. Show
Only now present the result. The user sees post-QA work.

## On failure

- Figma unreachable → stop with instructions; never proceed blind.
- Bad build → `figma-cli undo`.
- `--verify` returned no screenshot → try `figma-cli verify <nodeId>`; if that also
  fails, say plainly that the visual QA pass could not run.
- Sub-agent failed → surface it. Never silently skip QA.
