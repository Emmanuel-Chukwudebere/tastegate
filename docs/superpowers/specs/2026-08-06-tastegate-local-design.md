# tastegate — a local Claude Design, grounded in your taste

**Date:** 2026-08-06
**Status:** approved design, ready for implementation planning

## Problem

Design work in Claude Code produces output that misses the author's taste, takes many turns, and burns tokens. Anthropic's hosted **Claude Design** product does noticeably better. It is unavailable here: the `/design-sync` and `/design-login` commands require reaching claude.ai, and per the Claude Code command reference, on Amazon Bedrock "the underlying tool can't reach claude.ai, so the command is unavailable." This environment runs on Bedrock (`CLAUDE_CODE_USE_BEDROCK=1`, `us-east-1`).

The installed `frontend-design` skill does not close the gap. It is a single 1,332-word prose file with no `references/`, no `scripts/`, no component registry, and no verification step. Anthropic's own write-up (2025-11-12) describes it as roughly 400 tokens of taste guidance aimed at one-shot HTML. It is a prompt, not a system.

### Why Claude Design outperforms it

The hosted product does not use a better model. It wraps the same models in three mechanisms, both quoted from its product page:

1. **Component grounding** — "Import from GitHub, design files, or your local codebase so Claude can build with your real components." It composes from a verified registry instead of inventing.
2. **Closed-loop self-check** — "Claude checks its output against your design system, and makes corrections before you see it." The user only ever sees post-QA work.
3. **Parallel explorations** — it generates multiple genuine directions at once rather than one guess refined through conversation.

All three are reproducible locally. The gap is architectural, not model capability.

### Root cause of the token cost

Without a registry, every design decision is re-derived from scratch. Without a self-check, the user *is* the QA loop, correcting across many expensive Opus turns. The dominant cost is conversational correction, not generation.

## Goals

1. Match Claude Design's three mechanisms locally on Bedrock.
2. Surpass it by grounding in the author's taste and enforcing motion and accessibility standards it does not check.
3. Cut token cost by replacing conversational correction with registry composition, tool-emitted tokens, and delegated QA.
4. Complete the round trip with pixel-perfect design-to-code in the user's chosen framework, motion and interaction included.
5. Ship as a reusable, releasable plugin where each project grows its own taste.
6. Run across Claude Code (primary), Codex, Grok build, and Google Antigravity from one codebase.

## Non-goals

- Reaching claude.ai or reviving `/design-sync`. Permanently blocked on Bedrock.
- Replacing Figma's canvas. Figma is the better surface: real components, variants, variables.
- A general-purpose Figma wrapper. This is a design-quality system that uses Figma.

## Existing assets

Verified present on this machine:

| Asset | Status |
|---|---|
| `figma-ds-cli` v2.1.0 (silships/figma-cli), global | installed, unregistered with Claude Code |
| Figma Desktop `app-126.7.10` | installed |
| Node 26.6.0 / npm 11.18.0 | installed |
| Bedrock routing, Opus 5 / Sonnet 5 / Haiku 4.5 | configured |
| `frontend-design` plugin | enabled, insufficient |

`figma-cli` already provides every primitive this system needs. It ships a 4,021-word `CLAUDE.md` and a 664-line `REFERENCE.md`, and is currently wired into nothing.

Commands verified live against `--help`, not inferred from docs:

- **Grounding** — `spec <component>` reads a component's authoritative spec from `DESIGN.md`, and **`spec --check <nodeId>` enforces it, exiting 1 on violation** with a `--tolerance` in px; `instantiate <name>` drops an instance of an existing component; `extract` writes `DESIGN.md` with 12 selectable sections (`identity, structure, color, variables, typography, spacing, depth, components, states, rules, extending, tokens`), `--split` emitting full per-page trees; `import` accepts `DESIGN.md`, `tailwind.config.js`, CSS variables, design-tokens JSON, or a Storybook URL
- **Mechanical emit** — `export css`, `export tailwind`, `export dtcg`, `export-jsx`, `export-storybook`
- **Sight** — `render --verify` / `render-batch --verify` return a screenshot in the same call; `verify [nodeId]` takes a small screenshot for AI verification with `--base64` for inline
- **Reference intake** — `analyze-url` extracts **exact CSS values** via Playwright with `-w`/`-h` viewport control; `screenshot-url` imports a site screenshot into Figma; `recreate-url` rebuilds a page in Figma; `gradient extract <image>` pulls real gradients from an image
- **Design analysis** — `analyze colors`, `analyze typography`, `analyze spacing`, and **`analyze clusters` (finds repeated patterns — i.e. component candidates)**, all with `--json`
- **Audit** — `lint --fix --json`; `a11y audit / contrast / vision / touch / text / focus`
- **Systematisation** — `node to-component`, `sizes` (S/M/L variants), `slot create|convert|add|preferred`, `use|theme` (rebind a selection to another collection for light/dark), `unwrap` (fix an LLM bundling N items into one component), `unstack` / `arrange` (non-destructive overlap repair)
- **Batch efficiency** — `set-batch`, `bind-batch`, `rename-batch`, `delete-batch`, `var create-batch`; fill/stroke accept `var:name` references that **stay bound**, so theme switching keeps working
- **Safety** — `undo` removes nodes from the last render; `status` / `diagnose` for connection health

Three of these were not in the original design and change it materially:

1. **`spec --check <nodeId>`** — a deterministic, exit-code registry-compliance gate. Design-system conformance becomes a hard check rather than something the QA model eyeballs. This is the enforcement layer the `claude2figma` approach hand-rolls, already built in.
2. **`analyze clusters --json`** — detects repeated patterns, so `registry.md` can be **generated** from an existing file instead of hand-authored, and drift ("three near-identical cards that should be one component") is detectable.
3. **`lint --fix --json`** — mechanical issue repair before any model-based critique runs, so the QA pass spends its attention on taste rather than on mechanical defects a tool can fix for free.

### The JSX dialect

`render` uses a specific dialect that must be documented in the plugin, since it is the single most likely source of failed calls:

- **Elements** — `<Frame> <Rectangle> <Ellipse> <Text> <Line> <Image> <SVG> <Icon>`
- **Layout** — `flex="row|col"`, `gap`, `justify`, `items`, `wrap`, `w="fill"`, `minW`/`maxW`
- **Spacing** — `p`, `px`/`py`, `pt`/`pr`/`pb`/`pl`
- **Appearance** — `bg`, `stroke`, `strokeWidth`, `opacity`, `rounded`, `shadow`, `blur`
- **Native effects** — `noise`, `texture`, `progressiveBlur`, `glass` (with refraction/depth/radius/dispersion/light controls)
- **Icons** — `<Icon name="<prefix>:<name>" size color>` pulls real SVG from the Iconify API; `create icon` does the same standalone with `-s`/`-c` (and `-c` accepts `var:name`, so icon color stays token-bound). `lucide:` is the docs' example, **not a constraint** — any of Iconify's 231 collections works
- **Raw SVG** — ~~`<SVG>` accepts arbitrary SVG~~ **Disproved during implementation: there is no `<SVG>` element.** The parser's tag list is `Frame|Text|Icon|Rect|Rectangle|Ellipse|Circle|Image|Slot|Instance`, and using `<SVG>` fails with `SVG is not defined`. The real escape hatch for an unhosted set is `figma.createNodeFromSvg(svgString)` via `eval`/`run`, or `createInstance()` for a local component — see `skills/design/FIGMA-CLI.md`

Documented gotchas, each a real failure mode: `layout="horizontal"` → `flex="row"`; `padding={24}` → `p={24}`; `fill="#fff"` → `bg="#fff"`; `cornerRadius={12}` → `rounded={12}`. And a hard rule from the tool's own `CLAUDE.md`: **never use `eval` to create visual nodes** — it bypasses positioning, name dedup, constraints, and every safety guard.

## Architecture

One plugin, five skills, two tiers of standards.

```
C:\Users\imman\GitHub\Design\           (the plugin repo, git-versioned)
├── .claude-plugin/plugin.json
├── skills/
│   ├── design-taste/SKILL.md           → /taste
│   ├── design-explore/SKILL.md         → /explore
│   ├── design-build/SKILL.md           → /design
│   ├── design-review/SKILL.md          → /review
│   └── design-ship/SKILL.md            → /ship
├── standards/                          SHIPPED — universal craft
│   ├── MOTION.md                       numeric extract; defers to Emil's skills
│   ├── TYPOGRAPHY.md                   Emil's 7 rules, scored
│   ├── RUBRIC.md                       0–5 scoring checklist
│   ├── SLOP.md                         AI-default catalogue
│   ├── FRAMEWORKS.md                   per-target emit + motion bindings
│   └── FIGMA-CLI.md                    JSX dialect, gotchas, command map
├── references/runtimes/                cross-harness action→tool mapping
│   ├── claude-code.md
│   ├── codex.md
│   ├── antigravity.md
│   └── grok.md
└── scripts/                            deterministic helpers
```

**External dependency (optional, recommended):** `emilkowalski/skills` (MIT), installed via `npx skills@latest add emilkowalski/skills`. When present it is authoritative for motion and interaction; when absent the shipped standards still enforce the rules. See Component 7.

Per-project, generated by `/taste` in whatever repo is being designed:

```
<consuming project>/.claude/design/     PROJECT — taste, not shipped
├── TASTE.md
└── registry.md
```

### Why standards split into two tiers

Motion physics, the scoring rubric, and the AI-slop catalogue are universally true — they ship in the box. Taste is per-project: a fintech dashboard and a children's app must not share `TASTE.md`. Splitting the tiers is what makes the plugin releasable, and lets one author keep different taste per project.

### Progressive disclosure

Per Anthropic's skill-authoring guidance, a skill's body loads only when triggered, so "long reference material costs almost nothing until you need it." Skill bodies stay thin and point at standards files. Sub-agents read only the standard relevant to their pass. Idle cost of the whole system is approximately zero.

### Skills

| Skill | Command | Purpose |
|---|---|---|
| `design-taste` | `/taste` | Build or update `TASTE.md` + `registry.md` |
| `design-explore` | `/explore` | 3 genuinely different directions in parallel |
| `design-build` | `/design` | Compose from registry, auto-QA, then show |
| `design-review` | `/review` | Standalone scored audit of existing work |
| `design-ship` | `/ship` | Pixel-perfect Figma → code, framework of choice |

Descriptions must state **only triggering conditions**, never workflow summaries. The `writing-skills` guidance documents that a description summarizing workflow becomes a shortcut agents take instead of reading the skill body.

## Component 1 — `design-taste` (`/taste`)

Establishes what "good" means for one project. Everything else depends on it, so it ships first.

Five intake modes, combinable in one profile:

1. **Reference images** — local screenshots. `gradient extract` pulls real hex values and gradient geometry out of the image rather than having Claude guess them.
2. **Live URLs** — `analyze-url --screenshot` / `screenshot-url`.
3. **Figma moodboard page** — `extract --pages "Moodboard"` reads a curated page directly off the canvas.
4. **Existing Figma file / design system** — `extract` → `DESIGN.md`, becomes `registry.md`.
5. **Code or brand tokens** — `import tailwind.config.js` / `globals.css` / `tokens.json` / Storybook URL.

Plus **interview mode** when no references exist: a fixed question set covering typography temperament, density, color, motion appetite, and explicit dislikes. Interview mode is what makes the plugin usable on day one by someone with nothing prepared.

### URL intake — exact values, not impressions

`analyze-url <url>` uses Playwright to *"extract exact CSS values"*, and takes `-w` / `-h` viewport flags plus `--screenshot`. This is materially better than screenshot-only intake: the reference contributes **real computed CSS** — actual type scales, spacing values, colors — rather than Claude's estimate of what a picture looks like.

Responsive intake follows from the viewport flags. A reference is captured at three widths, so `TASTE.md` records how the direction *behaves*, not just how it looks at one size:

```
analyze-url <url> -w 390  --screenshot     mobile
analyze-url <url> -w 834  --screenshot     tablet
analyze-url <url> -w 1440 --screenshot     desktop
```

What this yields per reference: exact type scale and its ratio across breakpoints, real spacing rhythm, true colors (no eyedropper guessing), and the reflow strategy — what stacks, what hides, where columns collapse. Breakpoint behaviour is then a first-class part of the taste profile and a scored dimension in `RUBRIC.md`, rather than something discovered late at ship time.

Screenshots are always captured alongside the CSS extraction, at every breakpoint. Numbers alone under-describe a reference — composition, rhythm, and the feel of a layout only read visually — so each reference contributes **both** exact values and a visual record. `--screenshot` on `analyze-url` covers this, `screenshot-url` imports the image into Figma as an on-canvas reference, and `recreate-url` rebuilds a page as editable layers at 1440px for studying structure. The last is for study only, never for shipping someone else's design.

### Motion and interaction from a reference page — what is and is not possible

Direct answer: **`analyze-url` does not capture motion.** I read its source (`src/commands/url-tools.js`, 674 lines). Its `getComputedStyle` calls collect a fixed, static set — `color`, `backgroundColor`, `fontSize`, `fontWeight`, `fontFamily`, `borderRadius`, `border`/`borderWidth`/`borderColor`, and padding — plus `getBoundingClientRect` geometry for headings, buttons, inputs, and labels. No `transition`, no `animation`, no `transform`, no keyframes. Two static snapshots at two viewport widths cannot express timing, easing, or gesture.

This matters because motion is precisely where taste is hardest to articulate and most often wrong. So the pipeline closes the gap deliberately, in three tiers:

**1. Static motion properties, mechanically.** Playwright MCP is installed and enabled, so `browser_evaluate` can read the declared motion off a live page:

```js
getComputedStyle(el).transitionProperty / transitionDuration /
transitionTimingFunction / transitionDelay
getComputedStyle(el).animationName / animationDuration /
animationTimingFunction / animationIterationCount
document.styleSheets → @keyframes rules
```

That yields the reference's **actual durations and cubic-beziers** — the exact values `MOTION.md` scores against — rather than an impression of "feels snappy". It also reveals the library in use: a `--sonner`/`--vaul` custom property or a `data-state="open"` attribute identifies the component's provenance.

**2. Interaction states, by driving the page.** Playwright can `browser_hover`, `browser_click`, and `browser_press_key`, screenshotting before and after. That captures the states a static grab cannot: hover treatment, focus rings, open/closed menus, loading and error states. These are exactly the states `/ship` must generate and that a Figma frame never contains.

**3. Timed capture for sequences.** Successive screenshots across a transition record its trajectory — where it starts, how it settles, whether it overshoots. Enough to classify the motion and reproduce it, though not a frame-accurate recording.

**Honest limits.** This reads *declared* CSS motion. It does not capture JS-driven animation internals (a Framer Motion spring's stiffness and damping are computed at runtime, not declared), scroll-linked timelines in full, or physics parameters. For those, `animation-vocabulary` is the right instrument: the user describes the effect, that skill names it precisely, and `MOTION.md` supplies conforming values. Where a reference's motion cannot be measured it is recorded in `TASTE.md` as a described intent, explicitly flagged as inferred rather than measured — never presented as extracted fact.

**Outputs**

`TASTE.md` — 4–6 named hex values, type pairing with roles and scale ratio, spacing scale, density stance, motion appetite, signature-element policy, breakpoint behaviour, **icon set**, and an explicit **never** list.

### Icon set is a taste decision, recorded once

Icon style carries as much personality as typography, so `TASTE.md` records the chosen set and `/design` uses it for every icon rather than defaulting per screen. Mixed icon sets are one of the fastest ways a UI reads as assembled rather than designed, so the profile names exactly one primary set (a second is permitted only for a documented purpose, e.g. brand logos).

**Iconsax specifically.** Verified against the Iconify API: neither `iconsax` nor `vuesax` exists in its 231 collections — searched by prefix, name, and author; both `/collection?prefix=` endpoints return *Not found*. Iconsax and Vuesax are the same project, and it simply is not hosted there. So for Iconsax the pipeline uses the **`<SVG>` path**: point `/taste` at a local Iconsax SVG directory or its npm package, and icons are imported as raw SVG. This is recorded in `TASTE.md` as the icon source, with a resolution order:

```
icon set = Iconify collection   → <Icon name="prefix:name">     (preferred: one call, no assets)
icon set = local/npm SVG dir    → <SVG>                          (Iconsax and any unhosted set)
```

Iconsax's own variants (Linear, Bold, Broken, Outline, Two-tone, Bulk) map to subdirectories or filename suffixes in that source, and the chosen variant is pinned in the profile so all icons stay stylistically consistent.

For users without a specific commitment, close Iconify-hosted alternatives offering the same variant axes are worth naming — `solar` (7,401 icons; Linear / Bold / Broken / Line-duotone / Bold-duotone / Outline) is the nearest match in structure, alongside `ph` (Phosphor, 9,072), `tabler` (6,184), `lucide` (1,756), and `heroicons` (1,288). These are suggestions surfaced during `/taste`, never a silent substitution: **the user's named set always wins**, and if it is unhosted the `<SVG>` path is used rather than quietly swapping in a lookalike.

Hand-drawing icon paths is prohibited in all cases. It burns tokens and produces worse geometry than either path above.

`registry.md` — component handles for `instantiate`, plus bound token names. This is the file that ends node-tree generation: composing by handle costs a fraction of emitting geometry.

The registry is **generated, not hand-authored**: `extract --sections components` yields the variant matrices, and `analyze clusters --json` surfaces repeated patterns that *should* be components but aren't yet. The second is a design-system health check as much as an intake step — three near-identical cards on a canvas are a component waiting to be named, and it reports them.

Each entry records the handle for `instantiate`, its variant axes, and its bound tokens, so `spec --check` can later enforce it mechanically.

Re-running `/taste` **amends** rather than overwrites, so the profile compounds as more references arrive.

## Component 2 — `design-build` (`/design`)

The core loop, mirroring Claude Design's "corrections before you see it."

```
1. LOAD    registry.md + TASTE.md            handles, not node trees
2. PLAN    tokens + ASCII wireframe          in thinking; cheap to discard
3. BUILD   figma-cli render-batch --verify   builds AND screenshots in one call
4. GATE    lint --fix  +  spec --check       deterministic; free; no model
5. QA      Sonnet 5 sub-agent: screenshot + RUBRIC + MOTION → scored findings
6. FIX     apply fixes, re-verify
7. SHOW    user sees only post-QA output
```

Step 3 matters for cost: `--verify` returns the screenshot in the same call, so seeing the result costs no extra round trip.

**Step 4 is a cost multiplier and must run before step 5.** `lint --fix` repairs mechanical defects for free, and `spec --check <nodeId>` enforces registry conformance with an exit code. Both are deterministic — zero model tokens. Only what survives these gates reaches the QA model, so the expensive pass spends its attention on taste and motion instead of on problems a tool already catches. Running the model first would be paying Sonnet to find what `lint` finds free.

A `spec --check` failure is a hard stop, not a finding: the build is off-spec and must be corrected before critique is worth running.

**Never generate a component that exists in `registry.md`.** Check `spec <name>` first; if a handle exists, `instantiate` it.

## Component 3 — the QA loop, at Sonnet 5

The requirement is Opus-depth critique at lower cost. The resolution: **critique depth comes from the rubric, not from model priors.** The sub-agent is not asked "does this look good" — it scores against explicit, numeric criteria.

`RUBRIC.md` — each dimension scored 0–5, every finding requiring cited evidence and an exact fix:

- **Typography** — scale ratio present, display ≠ body family, weight contrast ≥ 400
- **Palette** — matches `TASTE.md` values, accent restricted to ≤ 2 placements
- **Spacing** — every value on the scale, optical alignment held
- **Hierarchy** — one focal point, signature element present
- **Motion** — delegated to `MOTION.md`
- **Accessibility** — contrast, touch targets, reduced motion (cross-checked with `a11y audit`)
- **Slop** — delegated to `SLOP.md`

`MOTION.md` — Emil Kowalski's standards, already numeric and therefore machine-checkable:

- Frequency table: 100+/day → no animation ever; keyboard-initiated actions never animate
- Easing order: entry/exit `ease-out`; moving/morphing `ease-in-out`; hover/color `ease`; constant `linear`. **`ease-in` on UI is banned.**
- Curves: `ease-out: cubic-bezier(0.23, 1, 0.32, 1)`; `ease-in-out: cubic-bezier(0.77, 0, 0.175, 1)`; `ease-drawer: cubic-bezier(0.32, 0.72, 0, 1)`
- Durations: button press 100–160ms; tooltip/popover 125–200ms; dropdown 150–250ms; modal/drawer 200–500ms; **UI stays under 300ms**
- Physicality: never `scale(0)` — use `scale(0.9–0.97)` + `opacity: 0`; popovers scale from trigger via `transform-origin`, modals exempt; `:active` `scale(0.97)` at 160ms `ease-out`
- Performance: animate **only** `transform` and `opacity`; never `width`/`height`/`margin`/`padding`/`top`/`left`; never drive child transforms from a parent CSS variable; Framer Motion shorthands (`x`/`y`/`scale`) drop frames — use full `transform` strings
- Gesture: momentum dismissal at velocity > ~0.11; boundary damping; pointer capture; ignore extra touch points mid-drag
- Accessibility: `prefers-reduced-motion` keeps opacity and drops transforms — "fewer and gentler, not zero"; gate hover behind `@media (hover: hover) and (pointer: fine)`
- Stagger: 30–80ms between items, never blocking interaction

`SLOP.md` — the three AI-default clusters named in the `frontend-design` skill, treated as automatic findings unless the brief explicitly asks for one: warm cream (~#F4F1EA) + high-contrast serif + terracotta accent; near-black + single acid-green or vermilion accent; broadsheet with hairline rules, zero radius, dense columns. Plus purple-gradient-on-white, and unjustified `01 / 02 / 03` numbering.

**Output format:** full prose findings with cited evidence and exact fixes — explicitly *not* a terse list. The depth requirement is met by the rubric; the cost saving comes from *where* the pass runs. The screenshot and standards load into the sub-agent's context; only findings return to the main Opus session. Depth is preserved without paying Opus rates to read pixels.

**Escalation:** if any dimension scores ≤ 2 on two consecutive passes, that pass escalates to Opus. Sonnet 5 handles the common case; Opus handles genuinely hard taste calls.

**Termination:** maximum 3 QA passes per build. On exit, report remaining findings rather than looping silently.

## Component 4 — `design-explore` (`/explore`)

Three genuinely different directions built as real Figma frames via `render-batch`, fanned out across parallel sub-agents. Each direction gets its own token set and signature element; each is checked against `SLOP.md` so the three are not variations on one default.

The user picks one; the winner is written into `TASTE.md` as the locked direction for the project.

This front-loads taste alignment. Three upfront directions replace the long correction thread that dominates current cost.

## Component 5 — `design-review` (`/review`)

The QA loop as a standalone command, runnable against Figma frames or a React codebase. Same rubric, same Sonnet 5 delegation, same escalation rule. Read-only: emits a prioritized report and an implementation plan, never blind edits.

## Component 6 — `design-ship` (`/ship`) — pixel-perfect design-to-code

The second half of the round trip, and a first-class deliverable rather than an afterthought. Requirement: **pixel-perfect conversion**, with the target framework chosen by the user.

### Framework targets

Default **React**. The user may specify another target (`/ship vue`, `/ship svelte`, `/ship react-native`, `/ship html`). Framework choice affects only the emit layer; extraction, verification, and the motion contract are framework-agnostic. Each target declares its styling and motion bindings:

| Target | Styling | Motion |
|---|---|---|
| React (default) | CSS variables, or Tailwind if the project uses it | CSS transitions; Framer Motion only where spring physics or gestures are needed |
| Vue / Svelte | same token variables | native transitions, same curves |
| React Native | StyleSheet from the same tokens | Reanimated, curves ported |
| Plain HTML | CSS variables | CSS transitions |

Detect the project's existing framework and styling system before asking. Never introduce a second styling paradigm into a project that already has one.

### Why pixel-perfect is achievable here

Conversion is measurement, not interpretation. Because the design was composed from registry handles with bound tokens, the geometry is already exact and machine-readable:

1. **Extract** — `figma-cli extract --selection` yields structure, bound token names, and Auto Layout values (padding, gap, alignment, constraints). Auto Layout maps directly onto flexbox; this is the mechanism that makes fidelity mechanical rather than eyeballed.
2. **Emit mechanically, in three layers** — `export-jsx --pretty` for the structural scaffold, `export css` / `export tailwind` / `export dtcg` for token values, `export-storybook` for the catalogue where applicable. All verified live. **Structure and values are generated by the tool, not the model.** Zero tokens spent on them, zero transcription errors — exactly the deterministic-work-belongs-in-scripts principle Anthropic's authoring guidance calls for. See "Three layers of mechanical export" below for what this does and does not cover.
3. **Map** — registry handle → existing project component; bound Figma variable → the CSS variable of the same name emitted in step 2. A shared token namespace across Figma and code is what keeps the two from drifting.
4. **Emit** — write the component in the target framework, referencing the variables from step 2. Zero raw hex values, zero magic numbers.
5. **Verify visually** — screenshot the built UI (Playwright MCP is installed and enabled) at the same viewport as the Figma frame, and diff it against the frame screenshot from `render --verify`. Findings are geometric: spacing deltas, type-size mismatches, color drift.
6. **Correct and re-verify** — loop until the diff is clean or 3 passes elapse, then report residual deltas honestly.

Step 5 is the part conventional Figma-to-code tools omit, and the reason their output is approximate. Both sides can be screenshotted, so fidelity is checkable rather than asserted.

### Three layers of mechanical export

Export is not limited to tokens. Verified live, `figma-cli` emits three distinct layers, and each one the tool produces is one the model does not have to write:

| Layer | Command | Output |
|---|---|---|
| **Tokens** | `export css` / `export tailwind` / `export dtcg` | CSS custom properties, Tailwind config, DTCG JSON |
| **Components / screens** | `export-jsx [nodeId] --pretty` | JSX/React structure for any node or full screen |
| **Component catalogue** | `export-storybook [nodeId]` | Storybook stories per component |

Plus `extract --sections components` for variant matrices and `--split` for full per-page trees under `DESIGN-structure/`.

**How `export-jsx` is used, and its honest limits.** It takes only `--output` and `--pretty` — no framework target, no token-binding flag. So it produces a *structural scaffold*: correct hierarchy, correct nesting, correct layout intent, straight from the canvas. It does not produce idiomatic framework code, token-bound values, interaction states, or motion.

The pipeline therefore treats it as **step zero of emit, not a replacement for it**:

```
export-jsx        → structure scaffold      (tool: free, exact)
export css/dtcg   → token values           (tool: free, exact)
Claude            → framework idiom, token binding, states, motion
```

Claude's job shrinks to the part that genuinely needs judgement. Structure and values arrive exact; the model spends its tokens on interaction, accessibility, and motion. This is the single largest cost reduction in the pipeline, and it is why fidelity is achievable: the geometry is never re-derived.

`export-storybook` is emitted alongside shipped components when the project uses Storybook, giving the catalogue for free.

### Tokens as the round-trip spine

`export dtcg` is documented as "the export side of token sync," pairing with `import tokens.json`. Tokens therefore travel **both directions** by tool, not by model:

```
Figma variables ──export css/tailwind/dtcg──▶ code
code tokens ─────import tokens.json/globals.css──▶ Figma variables
```

This makes drift correctable in whichever direction it appears, and means a design system can originate on either side. It is also why pixel-perfection is realistic: the values are never retyped by a language model.

### Motion and interaction on conversion

A static frame cannot express motion, so the motion layer is authored at ship time, governed by `MOTION.md` and Emil's skills. The frequency matrix is applied per element: a command-palette toggle gets no animation; a modal gets 200–500ms `ease-out`; a first-run celebration may get delight. Interaction states absent from the Figma frame — `:hover` gated behind `@media (hover: hover) and (pointer: fine)`, `:active` at `scale(0.97)`/160ms, `:focus-visible`, disabled, loading, empty, and error — are generated as part of shipping, since a design frame rarely contains them and their absence is what makes converted code feel unfinished.

Library selection follows `pick-ui-library`: never hand-roll a toast, drawer, or popover when a vetted library exists. Hand-rolled versions reliably carry accessibility, z-index, and focus-management defects.

### Round-trip integrity

`/ship` closes the loop by running the same `RUBRIC.md` against the built result, so code is held to the standard the design was held to. If code and Figma diverge later, the shared token namespace makes the drift detectable.

## Component 7 — Emil Kowalski's skills as the motion and interaction layer

`emilkowalski/skills` is **MIT licensed**, 26k stars, last pushed 2026-08-05 — actively maintained, and safe to depend on in a released plugin.

**Confirmed installed** in both `~/.claude/skills/` and `~/.agents/skills/` (the cross-runtime alias): all ten of `emil-design-eng`, `animate`, `review-animations`, `improve-animations`, `find-animation-opportunities`, `animation-vocabulary`, `apple-design`, `pick-ui-library`, `prototype`, plus `find-skills`.

Rather than paraphrasing his rules, this plugin **delegates to them** and orchestrates when each applies. Paraphrasing would go stale; his repo is updated frequently.

### Orchestration — which skill fires where

Every skill has a defined slot. None is decorative.

| Emil skill | Invoked by | When |
|---|---|---|
| `emil-design-eng` | all skills | Baseline authority for polish, component design, motion decisions |
| `animation-vocabulary` | `/taste` | Translating vague taste language ("bouncy", "snappy") into exact curves during intake |
| `apple-design` | `/taste`, `/ship` | When the profile calls for native feel: direct manipulation, velocity handoff, materials |
| `prototype` | `/explore` | Multiple live interactive versions at the code layer, complementing Figma-frame exploration |
| `find-animation-opportunities` | `/ship` | **Before** authoring motion: where motion is warranted, and where it must be refused |
| `pick-ui-library` | `/ship` | **Before** writing any component: never hand-roll a toast, drawer, popover, or dialog |
| `animate` | `/ship` | Authoring each animation with correct curve, duration, property, interruption, exit |
| `review-animations` | `/ship`, `/review` | Adversarial motion audit of the emitted code; default posture is to flag |
| `improve-animations` | `/review` | Repo-wide motion audit producing prioritized plans (read-only) |

### Mandatory sequence at `/ship`

Motion is where converted code most often feels wrong, so the order is fixed rather than discretionary:

```
1. find-animation-opportunities  → what should animate, what must not
2. pick-ui-library               → vetted library or hand-roll? decide BEFORE writing
3. animate                       → author each animation properly
4. review-animations             → adversarial audit of the result
```

Steps 1 and 2 run *before* any component code is written. Deciding motion and library choice after the fact is what produces the fragile hand-rolled toasts and unjustified animations this pipeline exists to prevent.

`MOTION.md` remains in the plugin as the **enforceable numeric extract** used for scoring, because the QA sub-agent needs thresholds in context without loading the full skill set. Where Emil's skills are installed they are authoritative and `MOTION.md` defers to them; where absent, `MOTION.md` alone still enforces the standard. The plugin degrades gracefully rather than hard-failing.

### Typography rules from `agents-with-taste`

Emil's article adds seven typography rules absent from the original rubric. These fold into `RUBRIC.md` as scored criteria: line length capped near 65 characters; tabular alignment for numbers; explicit truncation handling; letter-spacing on uppercase; complete font fallback stacks; deliberate underline usage; and a single clear emphasis hierarchy.

His durations are tighter than the standards file in places — 100–150ms micro-interactions, 150–250ms standard UI, 200–300ms modals. Where the two disagree, the **tighter bound wins**, consistent with his stated principle: "set the rules, be *strict*."

The article's thesis is the justification for this entire architecture: *"If you know what great feels like, describe the rules, then give them to your agents so they can follow them."*

## Component 8 — cross-runtime portability

Primary target **Claude Code**. Also required: Codex, Grok (build mode), and Google Antigravity.

This follows the pattern Superpowers already uses in production — skills are written to **speak in actions**, and a per-runtime reference file maps those actions to that harness's tools. Superpowers ships `codex-tools.md`, `antigravity-tools.md`, `gemini-tools.md`, and `pi-tools.md` for exactly this purpose.

### What makes it portable

| Layer | Portability |
|---|---|
| `standards/` (markdown) | Fully portable. Plain files with no runtime coupling. |
| `figma-cli` invocations | Fully portable. Any harness that can run a shell command. |
| Emil's skills | Already installed to `~/.agents/skills/`, the alias Codex, Copilot CLI, and Gemini CLI read. |
| Sub-agent dispatch | **Runtime-specific.** Needs a mapping per harness. |
| Screenshot reading | **Runtime-specific.** Requires image-input support. |

### Runtime adaptation

`references/runtimes/` in the plugin, one file per harness, each mapping the two coupled actions:

- **Claude Code** — `Agent` tool for sub-agents; `Read` for screenshots. Native path.
- **Codex** — requires `[features] multi_agent = true` in `~/.codex/config.toml`, enabling `spawn_agent` / `wait_agent` / `close_agent`.
- **Antigravity** — `invoke_subagent` with `TypeName: research` for read-only QA passes; no todo tool, so task tracking uses a task artifact (`write_to_file` with `IsArtifact: true`).
- **Grok build** — capability-detect at runtime; fall back to inline execution where sub-agents are unavailable.

### Dual distribution — plugin and `npx skills add`

The repo must be installable **both** ways, from one layout:

```bash
claude --plugin-dir ./tastegate                    # Claude Code plugin
npx skills@latest add emmanuel-chukwudebere/skills     # any agent, any runtime
```

Verified against the `skills` CLI (`vercel-labs/skills`, v1.5.22) and against
`emilkowalski/skills` as a working reference. Requirements are minimal:

- Skills live at `skills/<name>/SKILL.md` from the repo root — walked up to three
  levels deep, so flat and categorised layouts both resolve.
- `SKILL.md` needs YAML frontmatter with `name` and `description`.
- **No manifest is required.** Emil's repo root contains only `.gitignore`,
  `LICENSE`, `README.md`, and `skills/` — that is the entire installable surface.
- Supporting files sit beside `SKILL.md` in the same directory (Emil ships
  `RECIPES.md`, `STANDARDS.md`, `AUDIT.md`, `PLAN-TEMPLATE.md`, `PICKER.md` this way).

**The two formats are compatible, not competing.** `skills/<name>/SKILL.md` is
exactly what the Claude Code plugin spec expects, and `.claude-plugin/plugin.json`
is simply ignored by the `skills` CLI. One layout, two install paths.

One adjustment follows. Under `npx skills add`, only each skill's own directory is
installed — a sibling `standards/` directory at the repo root would not come with
it. Shared standards therefore live **inside the skill that owns them**, and other
skills reference them by relative path:

```
skills/
├── design/
│   ├── SKILL.md
│   ├── MOTION.md         ← authoritative copy, travels with the skill
│   ├── TYPOGRAPHY.md
│   ├── RUBRIC.md
│   ├── SLOP.md
│   ├── FIGMA-CLI.md
│   └── qa-brief.md
├── taste/     SKILL.md + intake.md + interview.md + TASTE-template.md
├── ship/      SKILL.md + emit.md + states.md + FRAMEWORKS.md
├── explore/   SKILL.md
└── review/    SKILL.md
```

Each skill states its dependency explicitly, and degrades to its own rules when a
sibling is absent — someone installing only `review` still gets a working audit.
Skills must therefore **locate their standards rather than assume a fixed path**,
checking their own directory first, then sibling skill directories.

`scripts/` is likewise reachable only in the plugin install, so every script has a
documented inline equivalent: the skill states the `figma-cli` commands directly,
and the script is a convenience wrapper rather than a hard dependency.

### Graceful degradation

The pipeline must not require sub-agents to function. Where a runtime cannot dispatch them, the QA pass runs **inline in the main context** — more expensive, identical output. Where a runtime cannot read images, the visual pass is skipped and the system says so plainly rather than asserting unverified fidelity, falling back to `a11y audit` and token-compliance checks that need no eyes.

Skills are authored to **request capabilities, not name tools**: "dispatch a read-only sub-agent with this brief" rather than "call the Agent tool." The runtime reference resolves it. This is what keeps one plugin working across four harnesses instead of forking it four ways.

## Token economics

| Lever | Mechanism |
|---|---|
| Registry composition | `instantiate "Button"` instead of emitting node trees |
| Tokens emitted by tool | `export css` / `tailwind` / `dtcg` — the entire value layer costs zero model tokens |
| Structure emitted by tool | `export-jsx` scaffolds hierarchy; the model writes only idiom, states, motion |
| Deterministic gates first | `lint --fix` and `spec --check` run before the QA model, so it never spends attention on mechanically detectable defects |
| Batch operations | `set-batch` / `bind-batch` / `rename-batch` / `create-batch` — one call instead of N |
| Exact CSS from references | `analyze-url` returns real computed values, removing guess-then-correct cycles |
| Progressive disclosure | skills and standards load only when triggered |
| Deterministic work in scripts | per Anthropic: "sorting a list via token generation is far more expensive than simply running a sorting algorithm" |
| Delegated QA | screenshots and standards never enter the main Opus context |
| `--verify` in one call | build and screenshot without an extra round trip |
| Upfront explorations | replaces multi-turn correction |

The trade is deliberate: more compute per design pass, far fewer expensive conversational turns.

**Not doing:** capping `CLAUDE_CODE_MAX_OUTPUT_TOKENS` globally. Design generation writes long files; a low cap truncates mid-file and forces regeneration, costing more. Caps belong on sub-agents, not the main loop.

## Error handling

- **Figma Desktop not running** — `figma-cli connect` fails fast with instructions; never proceed blind.
- **Missing `TASTE.md`** — `/design` and `/explore` refuse and direct the user to `/taste`. Grounding is mandatory; this is the whole thesis.
- **Empty `registry.md`** — permitted, with a warning that output will be generated rather than composed.
- **`--verify` returns no screenshot** — fall back to `export screenshot`; if that fails, report honestly that the QA pass could not run. Never claim verification that did not happen.
- **Bad build** — `figma-cli undo`.
- **Sub-agent failure** — surface it; do not silently skip QA.
- **Emil's skills not installed** — proceed on `MOTION.md` and `TYPOGRAPHY.md`, noting once that installing them raises the ceiling. Never hard-fail on an optional dependency.
- **Unsupported `/ship` target** — state which targets are supported and stop, rather than guessing at an unfamiliar framework's idioms.
- **Pixel diff cannot run** (no dev server, Playwright unavailable) — emit the code, then state plainly that visual verification did not run. Never imply verified fidelity that was not measured.

## Verification

The system is verified against Anthropic's stated method: run representative tasks, identify gaps, iterate.

1. **Registry compliance** — build a form with `registry.md` populated; assert zero raw hex values and zero from-scratch components where a handle existed.
2. **Motion rubric** — plant known violations (`ease-in` on entry, 450ms dropdown, `scale(0)` entry, animated `height`); assert `/review` catches every one.
3. **Slop detection** — request a generic landing page; assert the default cluster is flagged.
4. **Taste adherence** — build against a `TASTE.md` with distinctive values; assert output uses those values and nothing off-profile.
5. **Escalation** — force a dimension to score ≤ 2 twice; assert escalation to Opus fires.
6. **Pixel fidelity** — ship a Figma frame to React, screenshot both at one viewport, diff them; assert spacing, type size, and color match within tolerance, and that residual deltas are reported rather than hidden.
7. **Framework targeting** — run `/ship` against a Vue project and a Tailwind React project; assert the emitted code follows each project's existing styling paradigm and introduces no second one.
8. **Interaction completeness** — assert shipped components include hover (correctly gated), active, focus-visible, disabled, loading, empty, and error states even when absent from the Figma frame.
9. **Graceful degradation** — run the motion audit with `emilkowalski/skills` absent; assert `MOTION.md` alone still catches planted violations.
10. **Emil sequence enforced** — run `/ship` on a component needing a toast and a drawer; assert `find-animation-opportunities` and `pick-ui-library` ran *before* any component code was written, and that no toast or drawer was hand-rolled.
11. **Token export fidelity** — compare `export css` output against the Figma variables; assert every value matches and that no token value was transcribed by the model.
11a. **Deterministic gates run first** — plant a lintable defect and an off-spec component; assert `lint --fix` and `spec --check` both run *before* the QA sub-agent is dispatched, and that a `spec --check` non-zero exit halts the build rather than proceeding to critique.
11b. **Registry generation** — run intake on a file containing three near-identical cards; assert `analyze clusters` surfaces them as a component candidate and that `registry.md` is generated rather than hand-written.
11c. **Responsive intake** — run `analyze-url` at 390/834/1440; assert `TASTE.md` records the type scale, spacing, and reflow behaviour per breakpoint, and that breakpoint behaviour is scored in `RUBRIC.md`.
11d. **JSX dialect correctness** — assert generated JSX uses `flex=`/`p=`/`bg=`/`rounded=` and never `layout=`/`padding=`/`fill=`/`cornerRadius=`, and that `eval` is never used to create visual nodes.
11e. **Icon set adherence** — set `TASTE.md` to an Iconify collection and assert every icon uses that prefix with no mixing; then set it to a local Iconsax directory and assert the `<SVG>` path is used, no lookalike collection is silently substituted, and no icon path is hand-drawn.
11f. **Motion extraction honesty** — run motion intake against a page with CSS transitions and assert real durations and timing functions are captured; run it against a page using JS-driven springs and assert the result is recorded as *inferred*, not presented as measured.
11g. **Interaction-state capture** — drive a reference page with hover, focus, and click; assert the captured states inform the states `/ship` generates.
12. **Cross-runtime** — run `/review` under Claude Code and under one non-Claude harness; assert both complete, and that where sub-agents or image input are unavailable the system degrades and *says so* rather than silently skipping.
13. **Cost baseline** — record tokens for one screen built with the system versus without, to confirm the correction-turn saving is real.

Per `writing-skills`, skills are tested with sub-agents against these cases before the plugin is considered done.

## Build order

Taste precedes build, or there is nothing to ground against.

1. `plugin.json` + `standards/` (`MOTION.md`, `TYPOGRAPHY.md`, `RUBRIC.md`, `SLOP.md`, `FRAMEWORKS.md`) + `references/runtimes/claude-code.md` + register in `settings.json`
2. `design-taste` — including interview mode, so the plugin works with no references prepared
3. `design-build` — the auto-QA loop; core value
4. `design-ship` — pixel-perfect conversion, token export, and the mandatory Emil motion sequence
5. `design-explore`
6. `design-review`
7. Remaining runtime references (`codex.md`, `antigravity.md`, `grok.md`) + degradation testing

Milestone 3 is the first point of real payoff. Milestones 1–4 are the minimum shippable system, since the round trip is a stated requirement. Claude Code is proven first; other runtimes follow once the pipeline is validated on the primary target.

## Open items deferred by decision

- `TASTE.md` for this repo is scaffolded as a documented template now; `/taste` interview mode populates it in a later session. This was chosen deliberately so that release users build their own taste per project.
