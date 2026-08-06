# claude-design Plugin Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a reusable Claude Code plugin that reproduces and surpasses Anthropic's hosted Claude Design product locally — grounding design work in the user's taste, self-checking output before showing it, and cutting token cost by delegating deterministic work to tools.

**Architecture:** One repo, five skills, installable two ways — as a Claude Code plugin (`--plugin-dir`) and via `npx skills@latest add <owner>/skills`. Standards live *inside* the skill that owns them so they travel under either install path. Per-project taste (`TASTE.md`, `registry.md`) is generated into each consuming project's `.claude/design/`. Skills are thin and delegate to standards files, which load only when triggered. Deterministic work (`lint --fix`, `spec --check`, `export css`, `export-jsx`) runs as tool calls before any model-based critique.

**Tech Stack:** Markdown skills (`SKILL.md` + progressive-disclosure references), `figma-ds-cli` v2.1.0 (installed globally, binaries `figma-cli` and `figma-ds-cli`), Figma Desktop, Playwright MCP (installed and enabled), `emilkowalski/skills` (MIT, all 10 installed), Node 26.6.0, Bash for verification scripts.

## Global Constraints

Copied verbatim from the spec. Every task's requirements implicitly include this section.

- **Platform:** Windows 11, `bash` shell (Git Bash), Claude Code on AWS Bedrock (`CLAUDE_CODE_USE_BEDROCK=1`, `AWS_REGION=us-east-1`).
- **`/design-sync` and `/design-login` are permanently unavailable** on Bedrock. Never reference them as a fallback.
- **Plugin manifest path:** `.claude-plugin/plugin.json`. Only `plugin.json` goes inside `.claude-plugin/`. `skills/`, `references/`, `scripts/` all sit at plugin root.
- **Dual distribution.** The repo must install as a Claude Code plugin AND via `npx skills@latest add <owner>/skills`. The `skills` CLI (`vercel-labs/skills` v1.5.22) walks `skills/<name>/SKILL.md` up to three levels deep, requires `name` and `description` frontmatter, and needs **no manifest**. It installs **only each skill's own directory** — a repo-root `standards/` sibling would NOT travel with it.
- **Therefore: standards live inside the skill that owns them**, not in a repo-root `standards/`. Skills locate a standard by checking their own directory first, then sibling skill directories, and degrade to their own rules if absent.
- **Every script has a documented inline equivalent.** `scripts/` is only reachable under the plugin install, so no skill may hard-depend on one.
- **Skill descriptions state ONLY triggering conditions**, never a workflow summary. A description that summarizes workflow becomes a shortcut agents take instead of reading the skill body.
- **Plugin skills are namespaced:** `/claude-design:taste`, `/claude-design:design`, etc.
- **Never use `figma-cli eval` to create visual nodes.** It bypasses positioning, name dedup, constraints, and every safety guard.
- **JSX dialect (exact):** `flex="row|col"` not `layout=`; `p={24}` not `padding=`; `bg="#fff"` not `fill=`; `rounded={16}` not `cornerRadius=`.
- **Animate only `transform` and `opacity`.** Never `width`, `height`, `margin`, `padding`, `top`, `left`.
- **`ease-in` is banned on UI.** Entry/exit `ease-out`; moving/morphing `ease-in-out`; hover/color `ease`; constant `linear`.
- **UI animations stay under 300ms.** Button press 100–160ms; tooltip/popover 125–200ms; dropdown 150–250ms; modal/drawer 200–500ms. Where Emil's article gives tighter bounds (100–150ms micro, 150–250ms standard, 200–300ms modal), the tighter bound wins.
- **Custom curves (exact):** `ease-out: cubic-bezier(0.23, 1, 0.32, 1)`; `ease-in-out: cubic-bezier(0.77, 0, 0.175, 1)`; `ease-drawer: cubic-bezier(0.32, 0.72, 0, 1)`.
- **Never `scale(0)`.** Entry starts at `scale(0.9–0.97)` + `opacity: 0`.
- **Gesture dismissal threshold:** velocity > `0.11`.
- **Stagger:** 30–80ms between items.
- **Never claim verification that did not run.** If a screenshot, diff, or audit could not execute, say so plainly.
- **The user's named icon set always wins.** Never silently substitute a lookalike collection.
- **`iconsax` and `vuesax` are NOT in Iconify** (verified: 231 collections searched by prefix, name, author; `/collection?prefix=` returns *Not found* for both). Unhosted sets use the `<SVG>` path.

---

## File Structure

Plugin root is `C:\Users\imman\GitHub\Design`.

Standards live inside the skill that owns them, so they travel under `npx skills add` as well as under `--plugin-dir`. `skills/design/` is the standards home because it is the skill that scores against them.

| Path | Responsibility |
|---|---|
| `.claude-plugin/plugin.json` | Plugin manifest (ignored by the `skills` CLI) |
| `skills/design/SKILL.md` | Build loop with gates and QA |
| `skills/design/MOTION.md` | Numeric motion rubric; defers to Emil's skills when installed |
| `skills/design/TYPOGRAPHY.md` | Emil's 7 typography rules as scored criteria |
| `skills/design/RUBRIC.md` | 0–5 scoring checklist across 8 dimensions |
| `skills/design/SLOP.md` | AI-default look catalogue |
| `skills/design/FIGMA-CLI.md` | JSX dialect, gotchas, command map |
| `skills/design/qa-brief.md` | QA sub-agent brief template |
| `skills/design/RUNTIMES.md` | Action→tool mapping for all four harnesses |
| `skills/taste/SKILL.md` | Intake → `TASTE.md` + `registry.md` |
| `skills/taste/intake.md` | Five intake procedures incl. URL, motion, icons |
| `skills/taste/interview.md` | Ten-question fallback when no references exist |
| `skills/taste/TASTE-template.md` | The profile template |
| `skills/ship/SKILL.md` | Pixel-perfect design→code |
| `skills/ship/emit.md` | Three-layer mechanical export |
| `skills/ship/states.md` | Required interaction states |
| `skills/ship/FRAMEWORKS.md` | Per-target emit + motion bindings |
| `skills/explore/SKILL.md` | 3 parallel directions |
| `skills/review/SKILL.md` | Standalone scored audit |
| `scripts/preflight.sh` | Dependency check (plugin-only convenience) |
| `scripts/gates.sh` | `lint --fix` + `spec --check` runner (plugin-only convenience) |
| `tests/*.sh` | Verification scripts per task |
| `README.md` | Both install paths and usage |

**Standard resolution.** A skill needing a standard checks, in order: its own
directory, then `../design/`, then falls back to its own inline rules and says so.
This is what lets someone `npx skills add` a single skill and still get working
behaviour.

---

## Task 1: Plugin skeleton and preflight

**Files:**
- Create: `.claude-plugin/plugin.json`
- Create: `scripts/preflight.sh`
- Create: `tests/test-preflight.sh`
- Create: `.gitignore`

**Interfaces:**
- Consumes: nothing (first task)
- Produces: a loadable plugin named `claude-design`; `scripts/preflight.sh` exiting 0 when Figma Desktop is reachable and `figma-cli` is installed, non-zero otherwise, printing a `PREFLIGHT:` prefixed line per check

- [ ] **Step 1: Write the failing test**

Create `tests/test-preflight.sh`:

```bash
#!/usr/bin/env bash
# Verifies preflight reports each dependency and exits non-zero when Figma is unreachable.
set -uo pipefail
PASS=0; FAIL=0
check() { if eval "$2"; then echo "  PASS: $1"; PASS=$((PASS+1)); else echo "  FAIL: $1"; FAIL=$((FAIL+1)); fi; }

OUT="$(bash scripts/preflight.sh 2>&1)"

check "reports figma-cli presence" 'grep -q "PREFLIGHT: figma-cli" <<<"$OUT"'
check "reports figma desktop check" 'grep -q "PREFLIGHT: figma-desktop" <<<"$OUT"'
check "reports emil skills check"   'grep -q "PREFLIGHT: emil-skills" <<<"$OUT"'
check "manifest is valid json"      'node -e "JSON.parse(require(\"fs\").readFileSync(\".claude-plugin/plugin.json\",\"utf8\"))"'
check "manifest name is claude-design" 'node -e "const m=JSON.parse(require(\"fs\").readFileSync(\".claude-plugin/plugin.json\",\"utf8\"));process.exit(m.name===\"claude-design\"?0:1)"'

echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/test-preflight.sh`
Expected: FAIL — `scripts/preflight.sh` does not exist, and manifest checks fail with "no such file".

- [ ] **Step 3: Write the manifest**

Create `.claude-plugin/plugin.json`:

```json
{
  "name": "claude-design",
  "description": "Design with taste: grounds UI work in your design system and references, self-checks output before showing it, and ships pixel-perfect code.",
  "version": "0.1.0",
  "author": {
    "name": "imman"
  },
  "license": "MIT",
  "keywords": ["design", "figma", "ui", "motion", "design-system"]
}
```

- [ ] **Step 4: Write preflight**

Create `scripts/preflight.sh`:

```bash
#!/usr/bin/env bash
# Checks every dependency the design pipeline needs. Exits non-zero if a hard
# dependency is missing. Optional dependencies warn but do not fail.
set -uo pipefail
HARD_FAIL=0

if command -v figma-cli >/dev/null 2>&1; then
  echo "PREFLIGHT: figma-cli OK ($(figma-cli --version 2>/dev/null | head -1))"
else
  echo "PREFLIGHT: figma-cli MISSING - install with: npm i -g figma-ds-cli"
  HARD_FAIL=1
fi

if figma-cli status >/dev/null 2>&1; then
  echo "PREFLIGHT: figma-desktop OK"
else
  echo "PREFLIGHT: figma-desktop UNREACHABLE - open Figma Desktop, then run: figma-cli connect"
  HARD_FAIL=1
fi

if [ -d "$HOME/.claude/skills/emil-design-eng" ] || [ -d "$HOME/.agents/skills/emil-design-eng" ]; then
  echo "PREFLIGHT: emil-skills OK"
else
  echo "PREFLIGHT: emil-skills ABSENT - motion standards still enforced via skills/design/MOTION.md."
  echo "PREFLIGHT: emil-skills install with: npx skills@latest add emilkowalski/skills"
fi

exit "$HARD_FAIL"
```

- [ ] **Step 5: Create .gitignore**

```
node_modules/
*.log
DESIGN-structure/
.design-tmp/
*.png
!docs/**/*.png
```

- [ ] **Step 6: Run test to verify it passes**

Run: `bash tests/test-preflight.sh`
Expected: `PASS=5 FAIL=0`. If `figma-desktop` is unreachable the script still prints its `PREFLIGHT:` line, so the test passes; only the exit code differs.

- [ ] **Step 7: Validate the plugin loads**

Run: `claude plugin validate .`
Expected: `✔ Validation passed` (warnings acceptable at this stage — no skills exist yet).

- [ ] **Step 8: Commit**

```bash
git add .claude-plugin/plugin.json scripts/preflight.sh tests/test-preflight.sh .gitignore
git commit -m "feat: plugin skeleton with dependency preflight"
```

---

## Task 2: Motion and typography standards

**Files:**
- Create: `skills/design/MOTION.md`
- Create: `skills/design/TYPOGRAPHY.md`
- Create: `tests/test-standards.sh`

**Interfaces:**
- Consumes: Task 1's plugin root
- Produces: `skills/design/MOTION.md` and `skills/design/TYPOGRAPHY.md`, each containing every threshold from Global Constraints in greppable form, for the QA sub-agent to score against

- [ ] **Step 1: Write the failing test**

Create `tests/test-standards.sh`:

```bash
#!/usr/bin/env bash
# Asserts the standards files contain every exact threshold the rubric scores against.
set -uo pipefail
PASS=0; FAIL=0
has() { if grep -qF "$2" "$1" 2>/dev/null; then echo "  PASS: $1 has '$2'"; PASS=$((PASS+1)); else echo "  FAIL: $1 missing '$2'"; FAIL=$((FAIL+1)); fi; }

M=skills/design/MOTION.md
has "$M" "cubic-bezier(0.23, 1, 0.32, 1)"
has "$M" "cubic-bezier(0.77, 0, 0.175, 1)"
has "$M" "cubic-bezier(0.32, 0.72, 0, 1)"
has "$M" "300ms"
has "$M" "0.11"
has "$M" "scale(0.97)"
has "$M" "prefers-reduced-motion"
has "$M" "(hover: hover) and (pointer: fine)"
has "$M" "transform"
has "$M" "opacity"

T=skills/design/TYPOGRAPHY.md
has "$T" "65"
has "$T" "tabular"
has "$T" "letter-spacing"
has "$T" "fallback"

echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/test-standards.sh`
Expected: FAIL on all 14 checks — neither file exists.

- [ ] **Step 3: Write `skills/design/MOTION.md`**

```markdown
# Motion Standards

Authority: when `emilkowalski/skills` is installed, `emil-design-eng` and
`review-animations` are authoritative and this file defers to them. This file is
the numeric extract the QA pass scores against without loading the full skill set.
When those skills are absent, this file alone enforces the standard.

## 1. Should this animate at all?

Frequency decides presence. Check this before anything else.

| Frequency | Directive |
|---|---|
| 100+ times/day | No animation. Ever. |
| Tens of times/day | Remove or drastically reduce — opacity or color only |
| Occasional | Standard animation |
| Rare / first-time | Delight permitted |

**Never animate keyboard-initiated actions.** Command palettes, shortcuts, and
terminal prompts repeat constantly; motion reads as lag.

## 2. Purpose

Every animation needs a stated justification: spatial consistency (a toast
enters and exits on the same axis so swipe-to-dismiss feels right), state
indication, or preventing a jarring appearance. Reject "it looks cool" —
especially on frequently seen elements.

## 3. Easing — decision order

1. Entry / exit → `ease-out`
2. Moving / morphing → `ease-in-out`
3. Hover / color → `ease`
4. Constant motion → `linear`
5. Default → `ease-out`

**`ease-in` is banned on UI.** It delays the first moment the user is watching.

Custom curves:
- `ease-out`: `cubic-bezier(0.23, 1, 0.32, 1)`
- `ease-in-out`: `cubic-bezier(0.77, 0, 0.175, 1)`
- `ease-drawer`: `cubic-bezier(0.32, 0.72, 0, 1)`

## 4. Duration

**UI animations stay under 300ms.**

| Element | Range |
|---|---|
| Button press | 100–160ms |
| Tooltip / popover | 125–200ms |
| Dropdown | 150–250ms |
| Modal / drawer | 200–500ms |
| Micro-interaction | 100–150ms |
| Standard UI | 150–250ms |

Where ranges conflict, the tighter bound wins.

Asymmetric timing: deliberate user actions (press, hold, destructive confirm)
animate slower for weight; system responses snap. Symmetric timing on a
press-and-release is a finding.

Stagger: 30–80ms between items. Never block interaction.

## 5. Physicality

- **Never `scale(0)`.** Entry starts at `scale(0.9)`–`scale(0.97)` + `opacity: 0`.
- Popovers, dropdowns, tooltips scale from their trigger via `transform-origin`.
- Modals are the exception — center origin, they belong to the viewport.
- Button press: `scale(0.97)` on `:active`, 160ms `ease-out`.
- Crossfades use a blur to bridge states; without it two states visibly overlap.

## 6. Performance

- Animate **only `transform` and `opacity`**. These skip layout and paint.
- Never animate `width`, `height`, `margin`, `padding`, `top`, `left`.
- Never drive child transforms from a CSS variable on the parent — it forces
  style recalculation for every nested child.
- Framer Motion shorthands (`x`, `y`, `scale`) are not hardware-accelerated;
  they run on the main thread via rAF and drop frames. Use full CSS transform
  strings (`transform: translateY(10px)`) even inside Framer Motion.
- CSS transitions interrupt smoothly; keyframes restart from zero — avoid
  keyframes for rapidly retriggered motion.
- Engine choice: CSS for predetermined motion; WAAPI for interruptible JS-driven
  motion; Framer Motion for spring physics, drag, and layout morphing.
- `useSpring` for drag with momentum, "alive" elements, and interruptible gestures.

## 7. Gesture

- Momentum dismissal: compute velocity (distance ÷ elapsed ms), dismiss above `0.11`.
  Never use a bare distance threshold.
- Damping at boundaries: dragging past a natural edge takes progressively more effort.
- Pointer capture on drag start, so the element tracks a cursor that leaves its bounds.
- Multi-touch protection: ignore additional touch points once a drag begins.

## 8. Accessibility

```css
@media (prefers-reduced-motion: reduce) {
  /* keep opacity and color; drop transforms */
}
@media (hover: hover) and (pointer: fine) {
  /* gate all hover effects — touch fires false hovers */
}
```

Reduced motion means fewer and gentler animations, not zero.

## 9. Motion gaps

A conditional render (`{isOpen && <Modal />}`) with no exit animation wrapper
snaps out of existence. Flag it.
```

- [ ] **Step 4: Write `skills/design/TYPOGRAPHY.md`**

```markdown
# Typography Standards

Seven rules, each scored 0–5 by the QA pass.

1. **Line length** — cap measure near 65 characters. Long lines lose the reader's
   place on return sweep.
2. **Number alignment** — tabular figures (`font-variant-numeric: tabular-nums`)
   wherever numbers are compared in a column. Proportional figures make columns ragged.
3. **Truncation** — handle it explicitly. Decide ellipsis, wrap, or fade, and
   ensure the full value stays reachable (title attribute, tooltip, or detail view).
4. **Uppercase letter-spacing** — uppercase and small-caps need positive tracking.
   Set at default spacing, uppercase reads cramped.
5. **Font fallback stacks** — every family declares a complete stack ending in a
   generic. A missing webfont must not collapse to an unstyled default.
6. **Underlines** — deliberate. Underline links in prose; do not underline
   navigation or buttons where position and color already signal affordance.
7. **Emphasis hierarchy** — one clear level of emphasis per block. Bold competing
   with italic competing with color produces no hierarchy at all.

## Scale

Type scale is declared with an explicit ratio, and every size on the page comes
from it. Display and body faces are different families with a real weight
contrast (≥ 400 apart where both appear at similar size).
```

- [ ] **Step 5: Run test to verify it passes**

Run: `bash tests/test-standards.sh`
Expected: `PASS=14 FAIL=0`

- [ ] **Step 6: Commit**

```bash
git add skills/design/MOTION.md skills/design/TYPOGRAPHY.md tests/test-standards.sh
git commit -m "feat: motion and typography standards with exact thresholds"
```

---

## Task 3: Rubric, slop catalogue, and CLI dialect reference

**Files:**
- Create: `skills/design/RUBRIC.md`
- Create: `skills/design/SLOP.md`
- Create: `skills/design/FIGMA-CLI.md`
- Create: `tests/test-rubric.sh`

**Interfaces:**
- Consumes: `skills/design/MOTION.md`, `skills/design/TYPOGRAPHY.md` from Task 2 (referenced by name from `RUBRIC.md`)
- Produces: `skills/design/RUBRIC.md` defining 8 scored dimensions and a fixed findings output format; `skills/design/SLOP.md` listing the AI-default clusters; `skills/design/FIGMA-CLI.md` documenting the JSX dialect and the four gotchas

- [ ] **Step 1: Write the failing test**

Create `tests/test-rubric.sh`:

```bash
#!/usr/bin/env bash
set -uo pipefail
PASS=0; FAIL=0
has() { if grep -qiF "$2" "$1" 2>/dev/null; then echo "  PASS: $1 has '$2'"; PASS=$((PASS+1)); else echo "  FAIL: $1 missing '$2'"; FAIL=$((FAIL+1)); fi; }

R=skills/design/RUBRIC.md
for d in Typography Palette Spacing Hierarchy Motion Accessibility Slop Breakpoint; do has "$R" "$d"; done
has "$R" "0-5"
has "$R" "evidence"
has "$R" "MOTION.md"
has "$R" "TYPOGRAPHY.md"
has "$R" "escalate"

S=skills/design/SLOP.md
has "$S" "#F4F1EA"
has "$S" "terracotta"
has "$S" "acid-green"
has "$S" "broadsheet"
has "$S" "purple gradient"
has "$S" "01 / 02 / 03"

F=skills/design/FIGMA-CLI.md
has "$F" 'flex="row'
has "$F" "p={24}"
has "$F" 'bg="#fff"'
has "$F" "rounded={16}"
has "$F" "never use"
has "$F" "eval"

echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/test-rubric.sh`
Expected: FAIL on all checks — none of the three files exist.

- [ ] **Step 3: Write `skills/design/RUBRIC.md`**

```markdown
# Design QA Rubric

You are a senior design engineer auditing this work. Default posture is to flag;
approval is earned. Score each dimension 0–5.

**Every finding must carry:** the dimension, the score, cited evidence (what you
observed, where), and an exact fix (the precise value or change, never "improve
the spacing").

Write findings as full prose with reasoning. A terse list is not acceptable —
the reasoning is what makes a finding actionable.

## Dimensions

**1. Typography** — see `TYPOGRAPHY.md`. Is there an explicit scale with a stated
ratio? Are display and body different families? Is weight contrast real (≥ 400
apart at similar sizes)? Measure near 65 characters? Tabular figures where numbers
compare? Uppercase tracked? Complete fallback stacks?

**2. Palette** — do the colors match `TASTE.md` exactly? Is the accent restricted
to at most two placements? Is there a dominant color rather than an even split?

**3. Spacing** — is every value on the declared scale? Any magic numbers? Is
optical alignment held (visual edges aligned, not just mathematical bounds)?

**4. Hierarchy** — one clear focal point. Is the signature element from `TASTE.md`
present and doing the work? Does structure encode meaning, or decorate?

**5. Motion** — see `MOTION.md`. Score against its thresholds: frequency tier
respected, easing correct for interaction type, no `ease-in` on UI, under 300ms,
no `scale(0)`, `transform`/`opacity` only, `transform-origin` from trigger,
reduced-motion handled, hover gated.

**6. Accessibility** — contrast ratios pass, touch targets ≥ 24×24 (44×44
preferred), reduced motion respected, focus visible, reading order sensible.
Cross-check with `figma-cli a11y audit`.

**7. Slop** — see `SLOP.md`. Does this land on a known AI default? If the brief
did not ask for it, that is an automatic finding.

**8. Breakpoint behaviour** — does the design hold at the widths recorded in
`TASTE.md`? What stacks, what hides, where do columns collapse? Untested
breakpoints are a finding.

## Scoring and escalation

- **5** — exemplary, nothing to change.
- **3–4** — acceptable, with noted improvements.
- **0–2** — must fix before this is shown to the user.

If any dimension scores ≤ 2 on two consecutive passes, **escalate that pass to
Opus** rather than looping on Sonnet. Say plainly that you escalated and why.

Maximum 3 QA passes per build. On exit, report remaining findings rather than
looping silently.
```

- [ ] **Step 4: Write `skills/design/SLOP.md`**

```markdown
# AI-Default Look Catalogue

Current AI-generated design clusters around a small number of looks. Each is
legitimate for some briefs, but they appear regardless of subject, which makes
them defaults rather than choices.

**If the brief explicitly asks for one of these, follow the brief — the brief's
own words always win.** Where the brief leaves the axis free, landing on one of
these is an automatic finding.

## The three clusters

1. **Warm cream editorial** — background near `#F4F1EA`, high-contrast serif
   display, terracotta accent.
2. **Near-black with one acid accent** — near-black background, single bright
   acid-green or vermilion accent.
3. **Broadsheet** — hairline rules, zero border-radius, dense newspaper columns.

## Additional automatic findings

- **Purple gradient on white.** The most recognizable AI signature.
- **Generic type** — Inter, Roboto, Arial chosen by default rather than for the brief.
- **Unjustified `01 / 02 / 03` numbering.** Only valid when the content genuinely
  is a sequence and order carries information the reader needs.
- **The template hero** — big number, small label, supporting stats, gradient
  accent. Only if it is truly the best answer for this subject.
- **Scattered animation** — effects distributed evenly rather than one
  orchestrated moment. Extra animation is itself a tell that output is AI-generated.

## How to report

Name the cluster, cite the evidence, and propose a specific alternative derived
from the subject's own world — its materials, instruments, artifacts, vernacular.
```

- [ ] **Step 5: Write `skills/design/FIGMA-CLI.md`**

```markdown
# figma-cli Reference

Binaries: `figma-cli` and `figma-ds-cli` (same entry point). Controls Figma
Desktop directly over CDP. No API key, no rate limits.

## Hard rules

1. **Always use `render` / `render-batch` for frames** — they carry smart positioning.
2. **Never use `eval` to create visual nodes.** It has no positioning, overlaps at
   (0,0), and bypasses auto-split, name dedup, constraints, and fills. `eval` is
   only for Plugin API operations with no CLI subcommand.
3. Prefer `instantiate` over rebuilding anything that already exists.

## JSX dialect

**Elements:** `<Frame> <Rectangle> <Ellipse> <Text> <Line> <Image> <SVG> <Icon>`

| Concern | Syntax |
|---|---|
| Size | `w={320} h={200}`, `w="fill"`, `minW={100} maxW={500}` |
| Layout | `flex="row"` / `flex="col"`, `gap={16}`, `wrap`, `justify="start\|center\|end\|between"`, `items="start\|center\|end"` |
| Padding | `p={24}`, `px={16} py={8}`, `pt pr pb pl` |
| Appearance | `bg="#fff"`, `stroke="#000"`, `strokeWidth={1}`, `opacity={0.5}` |
| Corners | `rounded={16}`, `roundedTL={8}`, `overflow="hidden"` |
| Effects | `shadow="0 4 12 #0001"`, `blur={10}`, `rotate={45}` |
| Native | `noise="mono\|duo\|multi"`, `texture`, `progressiveBlur={40}`, `glass` |
| Text | `<Text size={18} weight="bold" color="#000" font="Inter">…</Text>` |
| Icon | `<Icon name="lucide:home" size={20} color="var:primary" />` |

**Token binding:** `bg`, `stroke`, and icon `color` accept `var:name` (e.g.
`var:primary`, `var:colors/brand-blue`). Variable references **stay bound**, so
theme switching keeps working. Always prefer `var:` over a literal hex.

## The four gotchas

| Wrong | Right |
|---|---|
| `layout="horizontal"` | `flex="row"` |
| `padding={24}` | `p={24}` |
| `fill="#fff"` | `bg="#fff"` |
| `cornerRadius={12}` | `rounded={12}` |

## Command map

| Purpose | Command |
|---|---|
| Connect / health | `connect`, `status`, `diagnose` |
| Build | `render '<Frame>…' --verify`, `render-batch '[…]' --verify` |
| See | `verify [nodeId]` (add `--base64` for inline) |
| Undo | `undo` (removes nodes from the last render) |
| Reuse | `spec <component>`, `instantiate <name>` |
| Enforce | `spec --check <nodeId> --tolerance 2` (exit 1 on violation) |
| Extract DS | `extract --sections <list>` (12 sections), `--pages`, `--selection`, `--split` |
| Import DS | `import <DESIGN.md\|tailwind.config.js\|globals.css\|tokens.json\|storybook-url>` |
| Export tokens | `export css`, `export tailwind`, `export dtcg [file]` |
| Export code | `export-jsx [nodeId] --pretty`, `export-storybook [nodeId]` |
| Reference intake | `analyze-url <url> -w <n> -h <n> --screenshot`, `screenshot-url <url>`, `recreate-url <url>` |
| Gradients | `gradient extract <image> [--mode mesh] [--apply-to <id>]`, `gradient mesh "<colors>"` |
| Analyse | `analyze colors\|typography\|spacing\|clusters --json` |
| Audit | `lint --fix --json`, `a11y audit\|contrast\|vision\|touch\|text\|focus` |
| Componentise | `node to-component <ids>`, `sizes --base small`, `variants from <ids> --property Size --values S,M,L` |
| Slots | `slot create\|list\|convert\|add\|preferred\|reset` |
| Theme | `use <collection>` (rebind selection to another collection) |
| Batch | `set-batch`, `bind-batch`, `rename-batch`, `delete-batch`, `var create-batch` |
| Repair | `unwrap <id>` (un-bundle), `unstack` (fix overlaps), `arrange` (destructive) |
| Inspect | `node tree`, `node bindings`, `get`, `find <name>`, `inspect <id> --json`, `canvas info` |

## Variant naming gotcha

The variant *property* name lives only on the property (`Size`, `State`). Do not
prefix values with the component name — `--values Button-Small` creates variants
literally named that.
```

- [ ] **Step 6: Run test to verify it passes**

Run: `bash tests/test-rubric.sh`
Expected: `PASS=25 FAIL=0`

- [ ] **Step 7: Commit**

```bash
git add skills/design/RUBRIC.md skills/design/SLOP.md skills/design/FIGMA-CLI.md tests/test-rubric.sh
git commit -m "feat: scoring rubric, slop catalogue, and figma-cli dialect reference"
```

---

## Task 4: Framework bindings and Claude Code runtime reference

**Files:**
- Create: `skills/ship/FRAMEWORKS.md`
- Create: `skills/design/RUNTIMES.md`
- Create: `tests/test-frameworks.sh`

**Interfaces:**
- Consumes: `skills/design/MOTION.md` (curves referenced per target)
- Produces: `skills/ship/FRAMEWORKS.md` with an emit + motion binding per target; `skills/design/RUNTIMES.md` mapping the two runtime-coupled actions (sub-agent dispatch, screenshot reading) to Claude Code tools

- [ ] **Step 1: Write the failing test**

Create `tests/test-frameworks.sh`:

```bash
#!/usr/bin/env bash
set -uo pipefail
PASS=0; FAIL=0
has() { if grep -qiF "$2" "$1" 2>/dev/null; then echo "  PASS: $1 has '$2'"; PASS=$((PASS+1)); else echo "  FAIL: $1 missing '$2'"; FAIL=$((FAIL+1)); fi; }

F=skills/ship/FRAMEWORKS.md
for t in React Vue Svelte "React Native" HTML; do has "$F" "$t"; done
has "$F" "Reanimated"
has "$F" "Framer Motion"
has "$F" "detect"
has "$F" "second styling paradigm"

C=skills/design/RUNTIMES.md
has "$C" "Agent"
has "$C" "Read"
has "$C" "sonnet"
has "$C" "degrade"

echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/test-frameworks.sh`
Expected: FAIL on all 11 checks — neither file exists.

- [ ] **Step 3: Write `skills/ship/FRAMEWORKS.md`**

```markdown
# Framework Targets

Default target is **React**. The user may name another: `/claude-design:ship vue`,
`… svelte`, `… react-native`, `… html`.

**Detect before asking.** Read `package.json`, config files, and existing
components to determine the framework and styling system already in use. Never
introduce a second styling paradigm into a project that has one — if the project
uses Tailwind, emit Tailwind; if it uses CSS modules, emit CSS modules.

| Target | Styling | Motion |
|---|---|---|
| React (default) | CSS custom properties, or Tailwind if the project uses it | CSS transitions; Framer Motion only for spring physics, drag, or layout morphing |
| Vue | same token variables | native `<Transition>`, same curves |
| Svelte | same token variables | native transitions, same curves |
| React Native | `StyleSheet` derived from the same tokens | Reanimated, curves ported to its easing API |
| Plain HTML | CSS custom properties | CSS transitions |

## Token source

Never hand-write token values. Generate them:

- `figma-cli export css` → CSS custom properties
- `figma-cli export tailwind` → Tailwind config
- `figma-cli export dtcg tokens.json` → W3C DTCG JSON

Then reference those variables in emitted components.

## Unsupported targets

If the requested target is not listed, say which targets are supported and stop.
Do not guess at an unfamiliar framework's idioms.

## Motion per target

All targets use the curves and durations in `MOTION.md`. Only the expression
differs. React Native has no CSS, so curves are ported to Reanimated's easing
functions while preserving the same timing values.
```

- [ ] **Step 4: Write `skills/design/RUNTIMES.md`**

```markdown
# Runtime: Claude Code

Skills in this plugin request capabilities rather than naming tools. This file
resolves them for Claude Code.

| Capability requested | Claude Code tool |
|---|---|
| Dispatch a sub-agent | `Agent` tool, `subagent_type: "general-purpose"` |
| Read an image | `Read` tool with the PNG path |
| Run a command | `Bash` tool |
| Write a file | `Write` / `Edit` |
| Drive a browser | Playwright MCP (`browser_navigate`, `browser_evaluate`, `browser_hover`, `browser_click`, `browser_take_screenshot`) |
| Track multi-step work | `TaskCreate` / `TaskUpdate` |

## QA sub-agent dispatch

Dispatch with `model: "sonnet"` for the QA pass. Escalate to `model: "opus"` when
`RUBRIC.md`'s escalation condition is met (any dimension ≤ 2 on two consecutive
passes).

The sub-agent brief must include: the screenshot path, the relevant standards
file paths, and `TASTE.md`. Screenshots and standards load in the sub-agent's
context; only findings return to the main session. This is the cost mechanism —
do not read screenshots into the main context.

## Available capabilities

Claude Code supports sub-agent dispatch and image reading natively, so no
degradation is required on this runtime. Both the visual QA pass and the pixel
diff run in full.

## Parallel dispatch

For `/explore`, send multiple `Agent` calls in a single message so directions
generate concurrently rather than in sequence.
```

- [ ] **Step 5: Run test to verify it passes**

Run: `bash tests/test-frameworks.sh`
Expected: `PASS=11 FAIL=0`

- [ ] **Step 6: Commit**

```bash
git add skills/ship/FRAMEWORKS.md skills/design/RUNTIMES.md tests/test-frameworks.sh
git commit -m "feat: framework bindings and Claude Code runtime mapping"
```

---

## Task 5: The `/taste` skill

**Files:**
- Create: `skills/taste/SKILL.md`
- Create: `skills/taste/intake.md`
- Create: `skills/taste/interview.md`
- Create: `skills/taste/TASTE-template.md`
- Create: `tests/test-taste.sh`

**Interfaces:**
- Consumes: `skills/design/FIGMA-CLI.md` (command syntax), `scripts/preflight.sh`
- Produces: `<project>/.claude/design/TASTE.md` and `<project>/.claude/design/registry.md`. Every later skill reads both from that exact path.

- [ ] **Step 1: Write the failing test**

Create `tests/test-taste.sh`:

```bash
#!/usr/bin/env bash
set -uo pipefail
PASS=0; FAIL=0
has() { if grep -qiF "$2" "$1" 2>/dev/null; then echo "  PASS: $(basename $1) has '$2'"; PASS=$((PASS+1)); else echo "  FAIL: $(basename $1) missing '$2'"; FAIL=$((FAIL+1)); fi; }
nothas() { if grep -qiF "$2" "$1" 2>/dev/null; then echo "  FAIL: $(basename $1) must NOT have '$2'"; FAIL=$((FAIL+1)); else echo "  PASS: $(basename $1) omits '$2'"; PASS=$((PASS+1)); fi; }

S=skills/taste/SKILL.md
has "$S" "description:"
has "$S" ".claude/design/TASTE.md"
has "$S" "amend"
# Description must state triggers only, not summarize workflow:
nothas "$S" "description: Builds a taste profile by"

I=skills/taste/intake.md
has "$I" "analyze-url"
has "$I" "-w 390"
has "$I" "-w 834"
has "$I" "-w 1440"
has "$I" "--screenshot"
has "$I" "gradient extract"
has "$I" "extract --pages"
has "$I" "analyze clusters"
has "$I" "browser_evaluate"
has "$I" "transitionTimingFunction"
has "$I" "inferred"
has "$I" "iconsax"
has "$I" "<SVG>"

V=skills/taste/interview.md
has "$V" "typography"
has "$V" "density"
has "$V" "motion"
has "$V" "never"

T=skills/taste/TASTE-template.md
has "$T" "Palette"
has "$T" "Icon set"
has "$T" "Breakpoint"
has "$T" "Never list"

echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/test-taste.sh`
Expected: FAIL — no `skills/taste/` directory exists.

- [ ] **Step 3: Write `skills/taste/SKILL.md`**

```markdown
---
name: taste
description: Use when starting design work in a project that has no taste profile yet, when the user provides design references (images, URLs, a Figma moodboard, brand tokens), when the user says the output does not match their taste, or when they ask to update the design direction.
---

# Taste

Establishes what "good" means for this project. Every other design skill depends
on the files this produces, so nothing else runs meaningfully until this does.

## Output location

Write to the **consuming project's** directory, never the plugin's:

- `.claude/design/TASTE.md` — the taste profile
- `.claude/design/registry.md` — component handles and bound tokens

Create `.claude/design/` if absent.

## Which mode

Ask which applies; several can combine in one profile.

| The user has | Mode |
|---|---|
| Screenshots, images | Reference intake → `intake.md` |
| Live site URLs | URL intake → `intake.md` |
| A Figma moodboard page | Moodboard intake → `intake.md` |
| An existing Figma file or design system | Design-system extract → `intake.md` |
| Code tokens, brand kit, Storybook | Token import → `intake.md` |
| Nothing prepared | Interview → `interview.md` |

## Process

1. Run `bash scripts/preflight.sh`. Stop on hard failure — Figma work cannot proceed blind.
2. Run the applicable intake modes.
3. Write `TASTE.md` from `TASTE-template.md`. Every field filled; no placeholders.
4. Write `registry.md` — generated by `extract --sections components` and
   `analyze clusters --json`, never hand-authored.
5. Show the user the profile and confirm it before finishing.

## Amending, not overwriting

If `TASTE.md` already exists, **amend it**. Read it first, add what the new
references contribute, and report what changed. The profile compounds as more
references arrive; overwriting discards accumulated taste.

## Honesty

Mark every value as measured or inferred. A color extracted by
`gradient extract` is measured. A motion feel derived from a description is
inferred. Never present inference as measurement.
```

- [ ] **Step 4: Write `skills/taste/intake.md`**

```markdown
# Intake Procedures

## 1. Local images

```bash
figma-cli gradient extract <image>            # real colors + gradient geometry
figma-cli gradient extract <image> --mode mesh
```

Read the image yourself as well — `gradient extract` gives values; you supply
composition, rhythm, and type observations.

## 2. Live URLs — exact CSS, at every breakpoint

`analyze-url` extracts real computed CSS via Playwright. Always capture all three
widths, always with a screenshot:

```bash
figma-cli analyze-url <url> -w 390  --screenshot   # mobile
figma-cli analyze-url <url> -w 834  --screenshot   # tablet
figma-cli analyze-url <url> -w 1440 --screenshot   # desktop
```

It returns: `color`, `backgroundColor`, `fontSize`, `fontWeight`, `fontFamily`,
`borderRadius`, `border`, `padding`, plus element geometry for headings, buttons,
inputs, and labels.

Record per breakpoint: type scale and its ratio, spacing rhythm, true colors, and
the reflow strategy (what stacks, what hides, where columns collapse).

Screenshots matter independently of the numbers. Values under-describe
composition; read the images.

Also available: `screenshot-url <url>` imports the screenshot into Figma as an
on-canvas reference. `recreate-url <url>` rebuilds a page as editable layers for
studying structure — **study only, never ship someone else's design.**

## 3. Motion and interaction from a URL

`analyze-url` does **not** capture motion. Its extraction is static only. Use
Playwright MCP directly.

**Declared motion** — `browser_navigate`, then `browser_evaluate`:

```js
// Collect declared motion from candidate elements.
const out = [];
document.querySelectorAll('button, [role="button"], a, [class*="modal"], [class*="menu"], [data-state]').forEach(el => {
  const cs = getComputedStyle(el);
  if (cs.transitionDuration !== '0s' || cs.animationName !== 'none') {
    out.push({
      tag: el.tagName.toLowerCase(),
      cls: el.className.toString().slice(0, 60),
      transitionProperty: cs.transitionProperty,
      transitionDuration: cs.transitionDuration,
      transitionTimingFunction: cs.transitionTimingFunction,
      transitionDelay: cs.transitionDelay,
      animationName: cs.animationName,
      animationDuration: cs.animationDuration,
      animationTimingFunction: cs.animationTimingFunction,
    });
  }
});
// @keyframes bodies, where readable.
const kf = [];
for (const sheet of document.styleSheets) {
  try {
    for (const rule of sheet.cssRules) {
      if (rule.type === CSSRule.KEYFRAMES_RULE) kf.push(rule.cssText.slice(0, 300));
    }
  } catch (e) { /* cross-origin sheet, skip */ }
}
return { motion: out.slice(0, 40), keyframes: kf.slice(0, 10) };
```

This yields the reference's real durations and cubic-beziers — the exact values
`MOTION.md` scores against. It also fingerprints libraries: a `--sonner` or
`--vaul` custom property, or a `data-state="open"` attribute, identifies provenance.

**Interaction states** — drive the page and screenshot each state:
`browser_hover` then screenshot; `browser_click` to open a menu or modal, then
screenshot; `browser_press_key` with Tab to capture focus rings. These are exactly
the states a Figma frame never contains and `/ship` must generate.

**Sequences** — successive screenshots across a transition record its trajectory
and whether it overshoots.

**Limits, stated plainly.** This reads *declared* CSS. JS-driven spring internals
(a Framer Motion spring's stiffness and damping are computed at runtime) are not
measurable, nor are scroll-linked timelines in full. For those, use
`animation-vocabulary` to name the effect precisely, take conforming values from
`MOTION.md`, and record the result in `TASTE.md` as **inferred**, never as measured.

## 4. Figma moodboard page

```bash
figma-cli extract --pages "Moodboard"
```

## 5. Existing Figma file or design system

```bash
figma-cli extract                              # full DESIGN.md
figma-cli extract --sections components        # variant matrices → registry.md
figma-cli extract --sections tokens,color,typography,spacing
figma-cli analyze colors --json
figma-cli analyze typography --json
figma-cli analyze spacing --json
figma-cli analyze clusters --json             # repeated patterns = component candidates
```

`analyze clusters` is both an intake step and a health check: three near-identical
cards are a component waiting to be named. Report them.

## 6. Code tokens, brand kit, Storybook

```bash
figma-cli import tailwind.config.js
figma-cli import src/globals.css
figma-cli import tokens.json
figma-cli import http://localhost:6006
```

## 7. Icon set

Record the chosen set in `TASTE.md`. Mixed icon sets are one of the fastest ways
a UI reads as assembled rather than designed — name exactly one primary set.

Resolution order:

```
Iconify-hosted set  → <Icon name="prefix:name" />   preferred: one call, no assets
Unhosted set        → <SVG>                          from a local or npm source
```

**Iconsax is not on Iconify.** Verified: neither `iconsax` nor `vuesax` appears in
its 231 collections (searched by prefix, name, and author; `/collection?prefix=`
returns *Not found* for both). Iconsax and Vuesax are the same project; it simply
is not hosted there. For Iconsax, ask the user for a local SVG directory or npm
package and use the `<SVG>` path, pinning the variant (Linear, Bold, Broken,
Outline, Two-tone, Bulk) so icons stay consistent.

To check whether a named set is hosted:

```bash
curl -s "https://api.iconify.design/collection?prefix=<prefix>" | head -c 200
```

If the user has no commitment, Iconify-hosted sets with comparable variant axes
include `solar` (7,401 icons: Linear, Bold, Broken, Line-duotone, Bold-duotone,
Outline), `ph` (9,072), `tabler` (6,184), `lucide` (1,756), `heroicons` (1,288).
Offer these as suggestions only — **the user's named set always wins, and an
unhosted set uses `<SVG>` rather than a silent lookalike substitution.**

Never hand-draw icon paths.
```

- [ ] **Step 5: Write `skills/taste/interview.md`**

```markdown
# Interview Mode

Use when the user has no references prepared. Ask one question at a time; prefer
concrete options over open prompts. Record answers directly into `TASTE.md`.

## Questions

1. **Subject and audience.** What is this product, who uses it, and what is the
   single job of the page or screen? Distinctive choices come from the subject's
   own world — its materials, instruments, artifacts, vernacular.

2. **Reference by contrast.** Name two products whose look you admire and one you
   dislike. What specifically is wrong with the one you dislike? Dislikes are
   often more precise than likes, and they populate the never list.

3. **Typography temperament.** Which reads right: geometric and neutral;
   editorial with a characterful serif; technical and monospaced; humanist and
   warm? Is there a typeface you already own or want to use?

4. **Density.** Airy with generous whitespace, or dense and information-rich?
   A dashboard and a landing page sit at opposite ends.

5. **Color temperament.** Dark or light foundation? One dominant color with a
   sharp accent, or a broader palette? Any brand colors that are fixed?

6. **Motion appetite.** Which is closest: near-zero motion, productivity-tool
   restraint (Linear, Raycast); considered polish at moments that matter; or
   expressive and playful? Note that keyboard-initiated actions never animate
   regardless of the answer.

7. **Icon set.** Do you have one? (See `intake.md` for resolution — Iconsax needs
   the `<SVG>` path.)

8. **Breakpoints.** Which widths must this hold at? Default 390 / 834 / 1440.

9. **Signature.** What is the one element this design should be remembered by?

10. **The never list.** What must never appear? Record it verbatim — this becomes
    an enforced constraint, not a preference.

## After the interview

Write `TASTE.md` with every field filled. Mark all values as **inferred from
interview** rather than measured. Then state plainly that adding real references
later via `/claude-design:taste` will sharpen the profile.
```

- [ ] **Step 6: Write `skills/taste/TASTE-template.md`**

```markdown
# Taste Profile: <project name>

Source: <interview | references | design system | combination>
Last updated: <date>

## Palette

4–6 named values. Mark each measured or inferred.

| Name | Value | Role | Source |
|---|---|---|---|
| | | dominant / accent / surface / text | measured \| inferred |

Accent appears in at most two placements per screen.

## Typography

| Role | Family | Weights | Source |
|---|---|---|---|
| Display | | | |
| Body | | | |
| Utility | | | |

Scale ratio: <e.g. 1.25>
Sizes: <the actual scale>
Measure: <target character count, default ~65>

## Spacing

Scale: <e.g. 4, 8, 12, 16, 24, 32, 48, 64>
Density stance: <airy | balanced | dense>

## Breakpoint behaviour

| Width | Layout | Notes |
|---|---|---|
| 390 | | what stacks, what hides |
| 834 | | |
| 1440 | | |

## Icon set

Primary: <prefix or local source>
Path: <Iconify `<Icon>` | local `<SVG>` directory>
Variant: <e.g. Linear>

## Motion

Appetite: <near-zero | restrained | considered | expressive>
Notable references: <measured values where available, marked inferred otherwise>

Standards in `MOTION.md` apply regardless of appetite.

## Signature element

The one thing this design is remembered by.

## Never list

Enforced constraints, recorded verbatim from the user.

-
```

- [ ] **Step 7: Run test to verify it passes**

Run: `bash tests/test-taste.sh`
Expected: `PASS=25 FAIL=0`

- [ ] **Step 8: Verify the skill loads and the description does not leak workflow**

Run: `claude plugin validate .`
Expected: `✔ Validation passed`

- [ ] **Step 9: Commit**

```bash
git add skills/taste tests/test-taste.sh
git commit -m "feat: /taste skill with five intake modes and interview fallback"
```

---

## Task 6: The `/design` skill with deterministic gates and QA loop

**Files:**
- Create: `skills/design/SKILL.md`
- Create: `skills/design/qa-brief.md`
- Create: `scripts/gates.sh`
- Create: `tests/test-design.sh`

**Interfaces:**
- Consumes: `.claude/design/TASTE.md` and `registry.md` from Task 5; `skills/design/RUBRIC.md`, `MOTION.md`, `TYPOGRAPHY.md`, `SLOP.md`, `FIGMA-CLI.md`; `skills/design/RUNTIMES.md`
- Produces: `scripts/gates.sh <nodeId>` — runs `lint --fix` then `spec --check`, exiting non-zero if the node is off-spec; `skills/design/qa-brief.md` — the exact sub-agent brief template

- [ ] **Step 1: Write the failing test**

Create `tests/test-design.sh`:

```bash
#!/usr/bin/env bash
set -uo pipefail
PASS=0; FAIL=0
has() { if grep -qiF "$2" "$1" 2>/dev/null; then echo "  PASS: $(basename $1) has '$2'"; PASS=$((PASS+1)); else echo "  FAIL: $(basename $1) missing '$2'"; FAIL=$((FAIL+1)); fi; }
ordered() { # $1 file, $2 earlier, $3 later
  local a b; a=$(grep -n "$2" "$1" | head -1 | cut -d: -f1); b=$(grep -n "$3" "$1" | head -1 | cut -d: -f1)
  if [ -n "$a" ] && [ -n "$b" ] && [ "$a" -lt "$b" ]; then echo "  PASS: '$2' before '$3'"; PASS=$((PASS+1));
  else echo "  FAIL: '$2' must come before '$3'"; FAIL=$((FAIL+1)); fi; }

S=skills/design/SKILL.md
has "$S" "TASTE.md"
has "$S" "registry.md"
has "$S" "instantiate"
has "$S" "render-batch"
has "$S" "--verify"
has "$S" "gates.sh"
has "$S" "sonnet"
has "$S" "3 QA passes"
has "$S" "refuse"
# The gate must run before the model-based QA pass:
ordered "$S" "gates.sh" "Dispatch"
# Registry lookup must precede building:
ordered "$S" "spec" "render-batch"

G=scripts/gates.sh
has "$G" "lint --fix"
has "$G" "spec --check"

Q=skills/design/qa-brief.md
has "$Q" "RUBRIC.md"
has "$Q" "evidence"
has "$Q" "full prose"
has "$Q" "escalate"

if [ -x scripts/gates.sh ] || [ -f scripts/gates.sh ]; then echo "  PASS: gates.sh exists"; PASS=$((PASS+1)); else echo "  FAIL: gates.sh missing"; FAIL=$((FAIL+1)); fi

echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/test-design.sh`
Expected: FAIL — no `skills/design/` or `scripts/gates.sh`.

- [ ] **Step 3: Write `scripts/gates.sh`**

```bash
#!/usr/bin/env bash
# Deterministic quality gates. Runs BEFORE any model-based critique so the
# expensive pass never spends attention on tool-detectable defects.
# Usage: gates.sh [nodeId] [component-name]
set -uo pipefail
NODE_ID="${1:-}"
COMPONENT="${2:-}"
GATE_FAIL=0

echo "GATE: lint"
if figma-cli lint --fix --json 2>/dev/null; then
  echo "GATE: lint OK (auto-fixed what it could)"
else
  echo "GATE: lint reported issues that need manual attention"
fi

if [ -n "$NODE_ID" ] && [ -n "$COMPONENT" ]; then
  echo "GATE: spec --check $COMPONENT against $NODE_ID"
  if figma-cli spec "$COMPONENT" --check "$NODE_ID" --tolerance 2; then
    echo "GATE: spec OK"
  else
    echo "GATE: spec VIOLATION - build is off-spec. Fix before critique."
    GATE_FAIL=1
  fi
else
  echo "GATE: spec --check skipped (no nodeId/component given)"
fi

echo "GATE: a11y audit"
figma-cli a11y audit ${NODE_ID:+"$NODE_ID"} 2>/dev/null || echo "GATE: a11y audit produced findings"

exit "$GATE_FAIL"
```

- [ ] **Step 4: Write `skills/design/SKILL.md`**

```markdown
---
name: design
description: Use when building or reshaping UI in Figma, creating screens or components, or when the user asks for a design, layout, or interface in a project that has a taste profile.
---

# Design

Composes UI in Figma from the project's registry and taste profile, checks its own
output, and only then shows the result.

## Preconditions

1. Run `bash scripts/preflight.sh`. Stop on hard failure.
2. Read `.claude/design/TASTE.md`. **If it does not exist, refuse** and direct the
   user to `/claude-design:taste`. Grounding is mandatory — building without it
   produces exactly the untethered output this plugin exists to prevent.
3. Read `.claude/design/registry.md`. If empty, warn that output will be generated
   rather than composed, then proceed.
4. Read `skills/design/FIGMA-CLI.md` for the JSX dialect before writing any JSX.

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

Use `<Icon name="prefix:name">` with the set from `TASTE.md`, or `<SVG>` for an
unhosted set. Never hand-draw paths.

### 5. Gate — deterministic, before any model critique
```bash
bash scripts/gates.sh <nodeId> "<ComponentName>"
```

This runs `lint --fix`, `spec --check`, and `a11y audit`. All are free and exact.
**A `spec --check` failure is a hard stop, not a finding** — the build is off-spec;
fix it before critique is worth running.

Running the model before this gate would pay Sonnet to find what `lint` finds free.

### 6. QA — dispatch a sub-agent
Dispatch per `skills/design/RUNTIMES.md` using
`qa-brief.md` as the brief. Model: **sonnet**. The screenshot and
standards load in the sub-agent's context; only findings return here. Do not read
the screenshot into this context.

### 7. Fix and re-verify
Apply the findings, re-render, re-gate. **Maximum 3 QA passes.** Escalate to opus
when `RUBRIC.md`'s condition is met (any dimension ≤ 2 twice). On exit after 3
passes, report remaining findings rather than looping silently.

### 8. Show
Only now present the result. The user sees post-QA work.

## On failure

- Figma unreachable → stop with instructions; never proceed blind.
- Bad build → `figma-cli undo`.
- `--verify` returned no screenshot → try `figma-cli verify <nodeId>`; if that also
  fails, say plainly that the visual QA pass could not run.
- Sub-agent failed → surface it. Never silently skip QA.
```

- [ ] **Step 5: Write `skills/design/qa-brief.md`**

```markdown
# QA Sub-Agent Brief

Substitute the bracketed values and send as the sub-agent prompt.

---

You are a senior design engineer auditing a Figma build. Default posture is to
flag; approval is earned.

**Read these files first:**
- `[plugin]/skills/design/RUBRIC.md` — your scoring method
- `[plugin]/skills/design/MOTION.md` — motion thresholds
- `[plugin]/skills/design/TYPOGRAPHY.md` — typography rules
- `[plugin]/skills/design/SLOP.md` — AI-default patterns
- `[project]/.claude/design/TASTE.md` — this project's taste profile

**Look at the screenshot:** `[screenshot path]`

**Context:** `[what was built and why; the brief it answers]`
**Pass number:** `[n]` of 3
**Prior findings, if any:** `[previous findings, so you do not repeat them]`

**Score all 8 dimensions** from `RUBRIC.md`: Typography, Palette, Spacing,
Hierarchy, Motion, Accessibility, Slop, Breakpoint behaviour.

**For every finding, give:**
1. The dimension and its score (0–5)
2. **Evidence** — what you actually observed, and where in the design
3. **An exact fix** — the precise value or change. Never "improve the spacing";
   instead "gap is 14px, off the 4-based scale — use 16px".

**Write full prose findings with your reasoning.** A terse list is not
acceptable; the reasoning is what makes a finding actionable. Depth here is the
point — you have the standards in context precisely so you can score against
numbers rather than impressions.

**If any dimension scores ≤ 2 and this is pass 2 or later**, say explicitly that
this warrants escalation to a stronger model, and why.

Return: the scores, the findings, and a one-line verdict — ship, fix, or escalate.
```

- [ ] **Step 6: Run test to verify it passes**

Run: `bash tests/test-design.sh`
Expected: `PASS=19 FAIL=0`

- [ ] **Step 7: End-to-end smoke test**

Open Figma Desktop, then:

```bash
figma-cli connect
bash scripts/preflight.sh
figma-cli render '<Frame flex="col" p={24} gap={16} bg="#ffffff" w={400}><Text size={24} weight="bold" color="#111111">Smoke test</Text></Frame>' --verify
```

Expected: a frame appears in Figma and the command prints a screenshot path.
Then `bash scripts/gates.sh` runs without crashing. Then `figma-cli undo`.

If Figma is not running, record that the smoke test could not execute — do not
mark this step complete.

- [ ] **Step 8: Commit**

```bash
git add skills/design scripts/gates.sh tests/test-design.sh
git commit -m "feat: /design skill with deterministic gates before delegated QA"
```

---

## Task 7: The `/ship` skill — pixel-perfect design to code

**Files:**
- Create: `skills/ship/SKILL.md`
- Create: `skills/ship/emit.md`
- Create: `skills/ship/states.md`
- Create: `tests/test-ship.sh`

**Interfaces:**
- Consumes: `skills/ship/FRAMEWORKS.md`, `skills/design/MOTION.md`, `.claude/design/TASTE.md`, `registry.md`; Emil's skills `find-animation-opportunities`, `pick-ui-library`, `animate`, `review-animations`
- Produces: emitted component files in the consuming project, plus a token file from `export css`/`tailwind`/`dtcg`

- [ ] **Step 1: Write the failing test**

Create `tests/test-ship.sh`:

```bash
#!/usr/bin/env bash
set -uo pipefail
PASS=0; FAIL=0
has() { if grep -qiF "$2" "$1" 2>/dev/null; then echo "  PASS: $(basename $1) has '$2'"; PASS=$((PASS+1)); else echo "  FAIL: $(basename $1) missing '$2'"; FAIL=$((FAIL+1)); fi; }
ordered() {
  local a b; a=$(grep -n "$2" "$1" | head -1 | cut -d: -f1); b=$(grep -n "$3" "$1" | head -1 | cut -d: -f1)
  if [ -n "$a" ] && [ -n "$b" ] && [ "$a" -lt "$b" ]; then echo "  PASS: '$2' before '$3'"; PASS=$((PASS+1));
  else echo "  FAIL: '$2' must precede '$3'"; FAIL=$((FAIL+1)); fi; }

S=skills/ship/SKILL.md
has "$S" "find-animation-opportunities"
has "$S" "pick-ui-library"
has "$S" "animate"
has "$S" "review-animations"
has "$S" "export-jsx"
has "$S" "export css"
has "$S" "diff"
has "$S" "did not run"
# Mandatory Emil sequence, in order:
ordered "$S" "find-animation-opportunities" "pick-ui-library"
ordered "$S" "pick-ui-library" "animate"
ordered "$S" "animate" "review-animations"
# Library choice must precede writing components:
ordered "$S" "pick-ui-library" "Emit"

E=skills/ship/emit.md
has "$E" "export-jsx"
has "$E" "scaffold"
has "$E" "export dtcg"
has "$E" "Auto Layout"
has "$E" "flexbox"

T=skills/ship/states.md
has "$T" "hover: hover"
has "$T" "focus-visible"
has "$T" "disabled"
has "$T" "loading"
has "$T" "empty"
has "$T" "error"
has "$T" "scale(0.97)"

echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/test-ship.sh`
Expected: FAIL — no `skills/ship/`.

- [ ] **Step 3: Write `skills/ship/SKILL.md`**

```markdown
---
name: ship
description: Use when converting a Figma design into code, implementing a design in React or another framework, when the user asks to build the design for real, or when they want the design turned into components.
---

# Ship

Converts a Figma design into production code with measured fidelity, in the
framework the project already uses.

Argument: an optional target — `react` (default), `vue`, `svelte`,
`react-native`, `html`.

## Preconditions

1. Read `skills/ship/FRAMEWORKS.md`. **Detect** the project's framework and styling
   system from `package.json` and existing components before asking. Never
   introduce a second styling paradigm into a project that has one.
2. Read `.claude/design/TASTE.md` and `registry.md`.
3. If the requested target is unsupported, say which are supported and stop.

## Order of operations

Motion and library decisions come **first**, because deciding them after writing
components is what produces fragile hand-rolled toasts and unjustified animation.

### 1. `find-animation-opportunities`
Invoke it on the design. Output: what should animate, and explicitly what must
not. The frequency matrix in `MOTION.md` governs — keyboard-initiated actions
never animate.

### 2. `pick-ui-library`
Invoke it before writing any component. Never hand-roll a toast, drawer,
popover, dialog, or combobox — hand-rolled versions reliably carry
accessibility, z-index, and focus-management defects.

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
duration, property, interruption, and exit. Values from `MOTION.md`.

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
Run `skills/design/RUBRIC.md` against the built result, so code is held to the
standard the design was held to.

## Token round trip

Tokens travel both directions by tool, never by retyping:

```
Figma variables ──export css/tailwind/dtcg──▶ code
code tokens ─────import tokens.json/globals.css──▶ Figma variables
```

If code and Figma drift, the shared token namespace makes it detectable and
correctable in whichever direction it appeared.
```

- [ ] **Step 4: Write `skills/ship/emit.md`**

```markdown
# Emit Procedure

## Three layers, two of them free

| Layer | Command | Cost |
|---|---|---|
| Structure | `export-jsx <nodeId> --pretty` | tool — exact, free |
| Token values | `export css` / `export tailwind` / `export dtcg` | tool — exact, free |
| Catalogue | `export-storybook <nodeId>` | tool — free |
| Idiom, states, motion | you | the only part needing judgement |

## What `export-jsx` is, and is not

It takes only `--output` and `--pretty` — no framework target, no token-binding
flag. So it produces a **structural scaffold**: correct hierarchy, nesting, and
layout intent, straight from the canvas.

It does **not** produce idiomatic framework code, token-bound values, interaction
states, or motion. Treat it as step zero of emit, not a replacement for it:

```
export-jsx        → structure       (exact, free)
export css/dtcg   → values          (exact, free)
you               → idiom, states, motion
```

This is why fidelity is achievable: the geometry is never re-derived by a model.

## Auto Layout maps onto flexbox

`extract --selection` returns Auto Layout values — padding, gap, alignment,
constraints, sizing. These map directly:

| Figma Auto Layout | CSS |
|---|---|
| direction horizontal / vertical | `flex-direction: row` / `column` |
| gap | `gap` |
| padding | `padding` |
| primary axis alignment | `justify-content` |
| counter axis alignment | `align-items` |
| fill container | `flex: 1` or `width: 100%` |
| hug contents | `width: fit-content` |

Because the values are extracted rather than estimated, conversion is
measurement, not interpretation.

## Mapping

1. Registry handle → existing project component. Check the project's component
   directory before creating anything new.
2. Bound Figma variable → the CSS variable of the same name emitted by
   `export css`. Keep the namespace identical across Figma and code; that shared
   namespace is what makes drift detectable later.
3. Never invent a value. If something is unbound in Figma, that is a finding to
   report, not a number to guess.
```

- [ ] **Step 5: Write `skills/ship/states.md`**

```markdown
# Interaction States

A Figma frame is one state. Production code needs all of them. Generate every
applicable state — their absence is the main reason converted designs feel
unfinished.

## Required states

| State | Requirement |
|---|---|
| Default | from the Figma frame |
| Hover | **gated**: `@media (hover: hover) and (pointer: fine)` — touch fires false hovers, leaving sticky states |
| Active / pressed | `transform: scale(0.97)`, 160ms `ease-out` |
| Focus-visible | a visible ring; never remove the outline without replacing it |
| Disabled | reduced contrast plus `cursor: not-allowed`; must still meet contrast minimums for readable text |
| Loading | a skeleton or spinner; reserve the final layout's space so nothing shifts on arrival |
| Empty | an invitation to act, not an apology. Say what to do next |
| Error | what went wrong and how to fix it, in the interface's voice. Never vague, never apologetic |

## Motion in states

Per `MOTION.md`:

- Hover and color shifts use `ease`.
- Entry and exit use `ease-out`; never `ease-in`.
- Animate only `transform` and `opacity`.
- Respect `prefers-reduced-motion`: keep opacity and color, drop transforms.
- Conditional renders need an exit animation wrapper, or the element snaps out of
  existence.

## Copy in states

Words are design material. Active voice; an action keeps the same name through the
whole flow, so a button that says "Publish" produces a toast that says
"Published". Name things by what people control, never by how the system is built.
```

- [ ] **Step 6: Run test to verify it passes**

Run: `bash tests/test-ship.sh`
Expected: `PASS=23 FAIL=0`

- [ ] **Step 7: Commit**

```bash
git add skills/ship tests/test-ship.sh
git commit -m "feat: /ship skill with mechanical export and measured fidelity"
```

---

## Task 8: The `/explore` and `/review` skills

**Files:**
- Create: `skills/explore/SKILL.md`
- Create: `skills/review/SKILL.md`
- Create: `tests/test-explore-review.sh`

**Interfaces:**
- Consumes: `skills/design/RUBRIC.md`, `SLOP.md`, `MOTION.md`; `.claude/design/TASTE.md`; `skills/design/RUNTIMES.md`; Emil's `prototype` and `improve-animations`
- Produces: `/explore` writes the chosen direction back into `TASTE.md` as the locked direction; `/review` emits a scored report and plan, changing no files

- [ ] **Step 1: Write the failing test**

Create `tests/test-explore-review.sh`:

```bash
#!/usr/bin/env bash
set -uo pipefail
PASS=0; FAIL=0
has() { if grep -qiF "$2" "$1" 2>/dev/null; then echo "  PASS: $(basename $1) has '$2'"; PASS=$((PASS+1)); else echo "  FAIL: $(basename $1) missing '$2'"; FAIL=$((FAIL+1)); fi; }

E=skills/explore/SKILL.md
has "$E" "three"
has "$E" "render-batch"
has "$E" "SLOP.md"
has "$E" "single message"
has "$E" "locked direction"
has "$E" "prototype"

R=skills/review/SKILL.md
has "$R" "RUBRIC.md"
has "$R" "read-only"
has "$R" "improve-animations"
has "$R" "review-animations"
has "$R" "sonnet"
has "$R" "escalate"

echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/test-explore-review.sh`
Expected: FAIL — neither skill exists.

- [ ] **Step 3: Write `skills/explore/SKILL.md`**

```markdown
---
name: explore
description: Use when the design direction is not settled, when the user wants options or alternatives before committing, at the start of a new project or screen, or when they ask to see different approaches.
---

# Explore

Generates three genuinely different directions as real Figma frames, so the
direction is chosen by looking rather than by describing. This front-loads taste
alignment and replaces the long correction thread that otherwise dominates cost.

## Preconditions

Read `.claude/design/TASTE.md` if it exists — explorations stay inside the never
list even while diverging on everything else. If it does not exist, explore
anyway; the outcome will seed the profile.

## Process

### 1. Define three directions
Each needs its own token set, type pairing, and signature element. They must
differ in *approach*, not in accent color.

Check each against `skills/design/SLOP.md` **before building**. If two directions
would land on the same AI-default cluster, replace one. Three variations on a
default is not an exploration.

### 2. Build in parallel
Dispatch one sub-agent per direction, **all in a single message** so they run
concurrently (see `skills/design/RUNTIMES.md`). Each builds its frame:

```bash
figma-cli render-batch '[…]' --verify
```

Position them side by side so they can be compared at a glance.

### 3. Present
Show all three with a one-line rationale each — what it commits to, and what it
gives up. State your recommendation and why.

### 4. Lock the winner
Once the user picks, write that direction into `.claude/design/TASTE.md` as the
**locked direction** for the project: its palette, type pairing, and signature
element become the profile's defaults.

## Interactive variants

For exploring behaviour rather than looks, invoke Emil's `prototype` skill —
it builds several genuinely different interactive versions with a live switcher,
which answers state-model questions that static frames cannot.
```

- [ ] **Step 4: Write `skills/review/SKILL.md`**

```markdown
---
name: review
description: Use when the user asks for design feedback, a design review, or an audit of existing UI, when they ask why something feels wrong or unpolished, or before shipping a design or component.
---

# Review

Scores existing work against the standards and reports. **Read-only** — it emits
findings and a plan, and changes no files.

## Scope

Works against either Figma frames or a code implementation.

## Process

### 1. Deterministic first
Free and exact, so run these before any model pass:

```bash
figma-cli lint --json            # mechanical issues
figma-cli a11y audit             # contrast, touch targets, text, focus order
figma-cli analyze clusters --json # components that should exist but do not
```

For code, invoke `improve-animations` for a repo-wide motion audit with
prioritized plans.

### 2. Capture
Figma: `figma-cli verify <nodeId>` for a screenshot.
Code: run it and screenshot with Playwright at each width in `TASTE.md`.

### 3. Score
Dispatch a sub-agent (model **sonnet**) with the brief in
`skills/design/qa-brief.md`, scoring all 8 dimensions from
`skills/design/RUBRIC.md`.

Escalate that pass to **opus** when any dimension scores ≤ 2 on two consecutive
passes, and say that you escalated and why.

### 4. Motion specifically
Invoke `review-animations` on the code diff or implementation. Its posture is
adversarial by design: approval is earned.

### 5. Report
Order findings by severity. Each carries evidence and an exact fix. Close with a
prioritized implementation plan the user or another agent can execute.

Never apply fixes from this skill. If the user wants them applied, that is
`/claude-design:design` or `/claude-design:ship`.
```

- [ ] **Step 5: Run test to verify it passes**

Run: `bash tests/test-explore-review.sh`
Expected: `PASS=12 FAIL=0`

- [ ] **Step 6: Commit**

```bash
git add skills/explore skills/review tests/test-explore-review.sh
git commit -m "feat: /explore parallel directions and /review read-only audit"
```

---

## Task 9: Consolidated runtime mapping and dual-distribution README

**Files:**
- Create: `skills/design/RUNTIMES.md`
- Create: `README.md`
- Create: `tests/test-runtimes.sh`

**Interfaces:**
- Consumes: the Claude Code section written in Task 4
- Produces: `skills/design/RUNTIMES.md` covering all four harnesses in one file, each with its action→tool mapping and degradation path; `README.md` documenting both install paths

One file rather than four, because under `npx skills add` only a skill's own
directory travels — a repo-root `references/runtimes/` would be left behind.

- [ ] **Step 1: Write the failing test**

Create `tests/test-runtimes.sh`:

```bash
#!/usr/bin/env bash
set -uo pipefail
PASS=0; FAIL=0
has() { if grep -qiF "$2" "$1" 2>/dev/null; then echo "  PASS: $(basename $1) has '$2'"; PASS=$((PASS+1)); else echo "  FAIL: $(basename $1) missing '$2'"; FAIL=$((FAIL+1)); fi; }
count() { local n; n=$(grep -ciF "$2" "$1" 2>/dev/null || echo 0); if [ "$n" -ge "$3" ]; then echo "  PASS: $(basename $1) has >=$3 '$2'"; PASS=$((PASS+1)); else echo "  FAIL: $(basename $1) has $n '$2', need $3"; FAIL=$((FAIL+1)); fi; }

R=skills/design/RUNTIMES.md
# All four harnesses in one file
has "$R" "Claude Code"
has "$R" "Codex"
has "$R" "Antigravity"
has "$R" "Grok"
# Claude Code
has "$R" "Agent"
has "$R" "sonnet"
# Codex
has "$R" "multi_agent = true"
has "$R" "spawn_agent"
has "$R" "~/.codex/config.toml"
# Antigravity
has "$R" "invoke_subagent"
has "$R" "IsArtifact"
has "$R" "task artifact"
# Grok
has "$R" "capability"
# Degradation stated for each of the four
count "$R" "degrade" 4

M=README.md
has "$M" "--plugin-dir"
has "$M" "npx skills@latest add"
has "$M" "npm i -g figma-ds-cli"
has "$M" "emilkowalski/skills"
has "$M" "taste"

echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/test-runtimes.sh`
Expected: FAIL — `RUNTIMES.md` has only the Claude Code section from Task 4, and `README.md` does not exist.

- [ ] **Step 3: Extend `skills/design/RUNTIMES.md` with the other three harnesses**

Append to the file created in Task 4:

```markdown
---

# Runtime: Codex

| Capability requested | Codex equivalent |
|---|---|
| Dispatch a sub-agent | `spawn_agent` / `wait_agent` / `close_agent` |
| Read an image | image input where supported |
| Run a command | shell tool |

## Enabling sub-agents

Sub-agent dispatch requires multi-agent support. Add to `~/.codex/config.toml`:

```toml
[features]
multi_agent = true
```

Without it, `spawn_agent` is unavailable.

## Degrade

If sub-agents are unavailable, run the QA pass **inline** in the main context.
More expensive, identical output — the rubric is what produces the quality, not
the isolation.

If image input is unavailable, skip the visual pass and **say so plainly**. Fall
back to `figma-cli lint`, `a11y audit`, and token-compliance checks, which need
no eyes. Never assert fidelity that was not measured.
```

- [ ] **Step 4: Append the Antigravity section to `skills/design/RUNTIMES.md`**

```markdown
---

# Runtime: Antigravity (`agy`)

| Capability requested | Antigravity equivalent |
|---|---|
| Dispatch a sub-agent | `invoke_subagent` — `TypeName: research` for read-only QA, `self` for full-capability work |
| Track multi-step work | a **task artifact**: `write_to_file` with `IsArtifact: true` and `ArtifactType: "task"` |
| Read an image | image input where supported |
| Run a command | shell tool |

## Task tracking

Antigravity has no todo tool — `manage_task` manages background processes, not a
checklist. When a skill asks for task tracking, maintain a markdown checklist as
a task artifact and edit it with `replace_file_content` as steps complete.

## QA dispatch

Use `TypeName: research` for the QA pass — it is read-only by nature, which
matches the pass exactly.

## Degrade

Same rules as every runtime: no sub-agents → run QA inline; no image input →
skip the visual pass and **say so plainly**, falling back to the deterministic
gates. Never claim unmeasured fidelity.
```

- [ ] **Step 5: Append the Grok section to `skills/design/RUNTIMES.md`**

```markdown
---

# Runtime: Grok (build mode)

Grok's tool surface varies by deployment, so **detect capabilities at runtime**
rather than assuming them.

| Capability requested | Resolution |
|---|---|
| Dispatch a sub-agent | use the harness's sub-agent facility if present; otherwise inline |
| Read an image | use image input if present; otherwise skip the visual pass |
| Run a command | shell tool |

## Detection

Before the QA pass, establish whether sub-agent dispatch and image input exist.
If either is missing, take the degradation path below rather than failing.

## Degrade

- No sub-agents → run the QA pass **inline** in the main context. The rubric
  supplies the quality; isolation only supplies the cost saving.
- No image input → skip the visual pass, run `figma-cli lint`, `a11y audit`, and
  token-compliance checks, and **state plainly** that visual verification did not
  run.

The pipeline must never require sub-agents to function.
```

- [ ] **Step 6: Write `README.md`**

```markdown
# claude-design

A design pipeline for Claude Code that grounds UI work in your taste, checks its
own output before showing it, and ships pixel-perfect code.

It reproduces the three mechanisms behind Anthropic's hosted Claude Design
product — component grounding, a closed-loop self-check, and parallel
explorations — locally, and adds motion, typography, and accessibility standards
that product does not enforce. It works on Amazon Bedrock, where the hosted
`/design-sync` path is unavailable.

## Requirements

```bash
npm i -g figma-ds-cli                        # Figma control, no API key
npx skills@latest add emilkowalski/skills    # motion + interaction layer (MIT)
```

Plus Figma Desktop, and Playwright MCP for the pixel-diff and motion extraction.

Emil's skills are optional but recommended. Without them, `skills/design/MOTION.md`
still enforces the motion rules; with them, they are authoritative.

## Install

Two ways, same repo.

**As a skill bundle** — works in Claude Code, Codex, Cursor, Antigravity, and any
agent the `skills` CLI supports:

```bash
npx skills@latest add emmanuel-chukwudebere/skills
```

Add one skill only, if you prefer:

```bash
npx skills@latest use emmanuel-chukwudebere/skills/skills/taste
```

**As a Claude Code plugin** — namespaced skills plus the helper scripts:

```bash
claude --plugin-dir /path/to/claude-design
```

Then `/reload-plugins` after edits.

Under the plugin, skills are namespaced (`/claude-design:taste`). Under
`npx skills add`, they install unnamespaced (`/taste`). Both work; the plugin also
brings `scripts/`, though every script has an inline equivalent documented in the
skill that uses it, so nothing depends on them.

## Use

| Command | When |
|---|---|
| `/claude-design:taste` | First, in any new project. Builds the taste profile |
| `/claude-design:explore` | Direction not settled — three real options |
| `/claude-design:design` | Build UI in Figma, self-checked before you see it |
| `/claude-design:ship` | Figma → code, framework of your choice |
| `/claude-design:review` | Scored audit of existing design or code |

Start with `taste`. The other skills refuse or warn without a profile, by design
— grounding is the whole thesis.

## How taste is stored

Universal craft standards ship inside the skills that use them. Your taste is
per-project, generated into the consuming project:

```
<your project>/.claude/design/
├── TASTE.md      palette, type, spacing, icons, motion, breakpoints, never list
└── registry.md   component handles + bound tokens
```

So a fintech dashboard and a children's app never share a profile.

## Why it costs less

Deterministic work runs as tool calls, not token generation: `figma-cli lint --fix`
and `spec --check` gate the build before any model critique; `export css` and
`export-jsx` emit tokens and structure exactly and free. The QA pass runs in a
sub-agent, so screenshots never enter the main context. And three upfront
explorations replace the long correction thread.

## Runtimes

Claude Code is the primary target. `skills/design/RUNTIMES.md` maps the two
harness-coupled actions — sub-agent dispatch and image reading — for Codex,
Antigravity, and Grok. Where a runtime lacks either, the pipeline degrades and
says so rather than asserting unverified results.

## License

MIT. Emil Kowalski's skills are MIT and separately installed.
```

- [ ] **Step 7: Run test to verify it passes**

Run: `bash tests/test-runtimes.sh`
Expected: `PASS=16 FAIL=0`

- [ ] **Step 8: Commit**

```bash
git add skills/design/RUNTIMES.md README.md tests/test-runtimes.sh
git commit -m "feat: cross-runtime references and README"
```

---

## Task 10: Full-suite verification and plugin validation

**Files:**
- Create: `tests/run-all.sh`
- Modify: `README.md` (add a Verify section)

**Interfaces:**
- Consumes: every `tests/test-*.sh` from Tasks 1–9
- Produces: `tests/run-all.sh` exiting 0 only when every suite passes

- [ ] **Step 1: Write the runner**

Create `tests/run-all.sh`:

```bash
#!/usr/bin/env bash
# Runs every test suite. Exits non-zero if any fails.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
TOTAL_FAIL=0
for t in tests/test-*.sh; do
  echo ""
  echo "=== $t ==="
  if bash "$t"; then echo "--- $t OK"; else echo "--- $t FAILED"; TOTAL_FAIL=$((TOTAL_FAIL+1)); fi
done
echo ""
if [ "$TOTAL_FAIL" -eq 0 ]; then echo "ALL SUITES PASSED"; else echo "$TOTAL_FAIL SUITE(S) FAILED"; fi
exit "$TOTAL_FAIL"
```

- [ ] **Step 2: Run the full suite**

Run: `bash tests/run-all.sh`
Expected: `ALL SUITES PASSED`. Fix any failures before continuing.

- [ ] **Step 3: Validate the plugin**

Run: `claude plugin validate .`
Expected: `✔ Validation passed` (or passed with warnings).

- [ ] **Step 4: Confirm structure satisfies BOTH install formats**

Run:

```bash
test -f .claude-plugin/plugin.json && echo "manifest OK"
test ! -d .claude-plugin/skills && echo "skills correctly NOT inside .claude-plugin"
ls skills/
# skills CLI requirement: every skill has SKILL.md with name + description
for d in skills/*/; do
  f="$d/SKILL.md"
  test -f "$f" || { echo "MISSING SKILL.md in $d"; continue; }
  grep -q "^name:" "$f" && grep -q "^description:" "$f" \
    && echo "OK  $(basename $d): frontmatter complete" \
    || echo "BAD $(basename $d): frontmatter missing name or description"
done
# No skill may depend on a repo-root standards/ dir that skills-CLI won't install
test ! -d standards && echo "OK: no repo-root standards/ (would not travel via npx skills add)"
```

Expected: manifest OK; skills not misplaced; five skill directories
(`taste`, `design`, `explore`, `review`, `ship`); every one reporting complete
frontmatter; and no repo-root `standards/`.

- [ ] **Step 4a: Verify standards travel with their skill**

Simulate a single-skill install and confirm the skill's standards came with it:

```bash
TMP=$(mktemp -d)
cp -r skills/design "$TMP/"
ls "$TMP/design/"
```

Expected: `SKILL.md`, `MOTION.md`, `TYPOGRAPHY.md`, `RUBRIC.md`, `SLOP.md`,
`FIGMA-CLI.md`, `qa-brief.md`, `RUNTIMES.md` all present. If a standard is missing,
it was placed at the repo root by mistake and will not install via the `skills` CLI.

Clean up: `rm -rf "$TMP"`

- [ ] **Step 5: Load the plugin and confirm skills register**

Run: `claude --plugin-dir .` then in-session `/help` and check the Custom
commands tab for the five `claude-design:` entries.

Record the actual result. If a skill does not appear, fix it before marking this
step complete.

- [ ] **Step 6: Add a Verify section to README.md**

Append:

```markdown
## Verify

```bash
bash tests/run-all.sh        # every suite
claude plugin validate .     # manifest and structure
```
```

- [ ] **Step 7: Commit**

```bash
git add tests/run-all.sh README.md
git commit -m "test: full-suite runner and plugin validation"
```

---

## Task 11: Live end-to-end validation against the spec's cases

**Files:**
- Create: `tests/MANUAL-VERIFICATION.md`

**Interfaces:**
- Consumes: the complete plugin from Tasks 1–10
- Produces: a recorded pass/fail per spec verification case, with actual observed output

This task requires Figma Desktop running and a real design task. It cannot be
faked — each case records what actually happened.

- [ ] **Step 1: Create the record**

Create `tests/MANUAL-VERIFICATION.md` with a section per case below, each with
fields: Command run, Observed output, Verdict (PASS/FAIL/BLOCKED), Notes.

- [ ] **Step 2: Case 1 — registry compliance**

Populate `registry.md`, then build a form with `/claude-design:design`.
Assert: zero raw hex values in the output, and `instantiate` used wherever a
handle existed. Record the actual JSX emitted.

- [ ] **Step 3: Case 2 — motion rubric catches planted violations**

Write a component containing all four: `ease-in` on entry, a 450ms dropdown,
`scale(0)` entry, and an animated `height`. Run `/claude-design:review`.
Assert all four are flagged. Record which were caught.

- [ ] **Step 4: Case 3 — slop detection**

Ask for a generic landing page with no direction given. Assert the QA pass flags
the AI-default cluster it lands on. Record the finding verbatim.

- [ ] **Step 5: Case 4 — taste adherence**

Write a `TASTE.md` with distinctive values, build against it, and assert the
output uses those values and nothing off-profile.

- [ ] **Step 6: Case 5 — escalation fires**

Force a dimension to score ≤ 2 on two consecutive passes. Assert escalation to
opus happens and is stated.

- [ ] **Step 7: Case 6 — deterministic gates run first**

Plant a lintable defect and an off-spec component. Assert `gates.sh` runs before
the sub-agent dispatch, and that a `spec --check` non-zero exit halts the build
rather than proceeding to critique.

- [ ] **Step 8: Case 7 — pixel fidelity**

Ship a Figma frame to React. Screenshot both at one viewport and diff. Record the
measured deltas for spacing, type size, and color, and confirm residuals are
reported rather than hidden.

- [ ] **Step 9: Case 8 — interaction completeness**

Assert shipped components include hover (gated behind
`@media (hover: hover) and (pointer: fine)`), active, focus-visible, disabled,
loading, empty, and error — even though the Figma frame contained none of them.

- [ ] **Step 10: Case 9 — Emil sequence order**

Ship a component needing a toast and a drawer. Assert
`find-animation-opportunities` and `pick-ui-library` both ran *before* any
component code was written, and that neither the toast nor the drawer was
hand-rolled.

- [ ] **Step 11: Case 10 — token export fidelity**

Compare `export css` output against the Figma variables. Assert every value
matches and no token value was transcribed by the model.

- [ ] **Step 12: Case 11 — registry generation**

Put three near-identical cards in a file. Assert `analyze clusters` surfaces them
as a component candidate and that `registry.md` was generated, not hand-written.

- [ ] **Step 13: Case 12 — responsive intake**

Run `/claude-design:taste` with a URL. Assert `analyze-url` ran at 390, 834, and
1440, that screenshots were captured at each, and that `TASTE.md` records type
scale, spacing, and reflow per breakpoint.

- [ ] **Step 14: Case 13 — motion extraction honesty**

Run motion intake against a page using CSS transitions: assert real durations and
timing functions are captured. Then against a page using JS-driven springs:
assert the result is recorded as **inferred**, not presented as measured.

- [ ] **Step 15: Case 14 — icon set adherence**

Set `TASTE.md` to an Iconify collection; assert every icon uses that prefix, with
no mixing. Then set it to a local Iconsax directory; assert the `<SVG>` path is
used, no lookalike collection is substituted, and no path is hand-drawn.

- [ ] **Step 16: Case 15 — graceful degradation**

Temporarily rename `~/.claude/skills/emil-design-eng` and `~/.agents/skills/emil-design-eng`,
run the motion audit, and assert `MOTION.md` alone still catches the planted
violations. Restore the directories afterward.

- [ ] **Step 17: Case 16 — cost baseline**

Build one screen with the plugin and one without. Record token counts for both.
This is the evidence for the cost claim — report the real numbers, including if
they contradict the expectation.

- [ ] **Step 17a: Case 17 — dual distribution installs cleanly**

Push the repo to GitHub, then verify the skill-bundle path actually works:

```bash
npx skills@latest add <owner>/skills
npx skills list
```

Assert all five skills install and appear in the list. Then confirm each one's
standards arrived beside it:

```bash
ls ~/.claude/skills/design/
```

Expected: `SKILL.md` plus `MOTION.md`, `TYPOGRAPHY.md`, `RUBRIC.md`, `SLOP.md`,
`FIGMA-CLI.md`, `qa-brief.md`, `RUNTIMES.md`.

Then invoke `/design` in a project with a `TASTE.md` and assert it runs without
the plugin loaded — no `scripts/` present, so it must use the inline command
equivalents. Record whether it degraded correctly or errored.

- [ ] **Step 18: Commit the results**

```bash
git add tests/MANUAL-VERIFICATION.md
git commit -m "test: record live end-to-end verification results"
```

---

## Self-Review

**1. Spec coverage**

| Spec section | Task |
|---|---|
| Component 1 `design-taste` | Task 5 |
| Component 2 `design-build` | Task 6 |
| Component 3 QA loop at Sonnet 5 | Tasks 3 (rubric), 6 (dispatch), 4 (runtime mapping) |
| Component 4 `design-explore` | Task 8 |
| Component 5 `design-review` | Task 8 |
| Component 6 `design-ship` pixel-perfect | Task 7 |
| Component 7 Emil orchestration | Tasks 2 (MOTION.md), 7 (mandatory sequence), 8 (review/improve) |
| Component 8 cross-runtime | Tasks 4 (Claude Code section), 9 (Codex, Antigravity, Grok appended to same file) |
| Dual distribution (plugin + `npx skills add`) | Task 9 (README), Task 10 Steps 4/4a (structure checks), Task 11 Case 17 (live install) |
| Three layers of mechanical export | Task 7 (`emit.md`) |
| Tokens as round-trip spine | Task 7 |
| URL intake + responsive breakpoints | Task 5 (`intake.md`) |
| Motion extraction from references | Task 5 (`intake.md`) |
| Icon set decision + Iconsax `<SVG>` path | Task 5 (`intake.md`) |
| JSX dialect | Task 3 (`skills/design/FIGMA-CLI.md`) |
| Deterministic gates (`lint`, `spec --check`) | Task 6 (`scripts/gates.sh`) |
| Registry generation (`analyze clusters`) | Tasks 5, 8 |
| Token economics | Tasks 6, 7 (mechanisms), 11 Case 16 (measurement) |
| Error handling | Tasks 1 (preflight), 6, 7, 9 (degradation) |
| Verification (16 cases) | Tasks 1–10 automated, Task 11 live |
| Build order | Task order matches spec: standards → taste → design → ship → explore/review → runtimes |

No gaps.

**2. Placeholder scan**

No "TBD", "TODO", "implement later", or "add error handling" instructions. Every
file's full content is given. Every test contains real assertions with expected
output. Task 11's cases specify exactly what to assert and require recording
actual observed output.

**3. Type and name consistency**

- Plugin name `claude-design` → namespace `/claude-design:<skill>` used consistently in Tasks 5–9 and README.
- Skill directory names `taste`, `design`, `explore`, `review`, `ship` match the `name:` frontmatter and the Task 10 Step 4 assertion.
- `.claude/design/TASTE.md` and `.claude/design/registry.md` — identical path in Tasks 5, 6, 7, 8, README.
- `scripts/gates.sh` signature `gates.sh [nodeId] [component-name]` — matches its invocation in Task 6 Step 4.
- `scripts/preflight.sh` `PREFLIGHT:` prefixes — asserted in Task 1's test, used in Tasks 5 and 6.
- Standards filenames `MOTION.md`, `TYPOGRAPHY.md`, `RUBRIC.md`, `SLOP.md`, `FRAMEWORKS.md`, `FIGMA-CLI.md` — consistent across all tasks and tests.
- `skills/design/qa-brief.md` — created in Task 6, referenced by Task 8's `/review`.
- Model names `sonnet` / `opus` — consistent in Task 4's runtime mapping, Task 6, Task 8.
- Curves, durations, and thresholds — identical between Global Constraints, Task 2's `MOTION.md`, and Task 2's test.
