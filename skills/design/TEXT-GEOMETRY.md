# Text Geometry: why Figma and CSS disagree vertically

A Figma-to-code pixel diff that compares `node.y` against
`getBoundingClientRect().top` is comparing **two different reference lines**. The
resulting delta is an artifact, not a defect — and it cannot be closed by moving
anything. This document exists because chasing one cost roughly 20
measure-adjust-export rounds in a real session, which is the single most expensive
failure this pipeline has produced.

## The two error sources

Both are per-node and both scale with font size, so neither shows up as a global
offset you can subtract.

### 1. Box height: Figma AUTO ≠ CSS `normal` ≠ CSS ratio

Figma's AUTO line-height gives a text node a box of exactly
`fontAscent + fontDescent`. CSS `line-height` computes a different box, and the
difference changes sign depending on which form you used.

Measured (Chromium, Arial, via `measureText` + `getBoundingClientRect`):

| Size | Figma AUTO | CSS `1` | CSS `normal` | CSS `1.2` |
|---|---|---|---|---|
| 17pt | 19 | 17 (**−2**) | 20 (**+1**) | 20.4 (**+1.4**) |
| 34pt | 38 | 34 (**−4**) | 38.4 (**+0.4**) | 40.8 (**+2.8**) |
| 41pt | 46 | 41 (**−5**) | 47.2 (**+1.2**) | 49.2 (**+3.2**) |
| 105pt | 117 | 105 (**−12**) | 120.8 (**+3.8**) | 126 (**+9**) |

**`line-height: 1` is shorter than Figma AUTO; a `1.2` ratio is taller.** In a flex
column every text node contributes its own error to every sibling below it, so the
deltas accumulate downward. A column of 105 + 41 + 17 + 17 accumulates **+15pt** by
the fourth element at `1.2`, and **−21pt** at `1`.

A page that mixes both forms produces a drift that **flips sign partway down** —
elements pulled up above, pushed down below.
That signature is diagnostic: a uniform offset cannot produce it, which is why
subtracting a constant makes such a diff worse rather than better.

### 2. Half-leading: CSS centres the glyph, Figma does not

CSS distributes `(lineBox − emBox)` evenly above and below the text — half-leading.
Figma's AUTO box has none. So **even when both boxes have identical tops, the glyph
inside sits lower in CSS**, by an amount that grows with both size and line-height.

Cap-top offset from box top (Arial), verified two independent ways — from font
metrics, and by rasterising a glyph and scanning for the first row of ink:

| Size | `line-height: 1` | `line-height: 1.2` | Difference |
|---|---|---|---|
| 17pt | 2px | 4px | 2px |
| 41pt | 5px | 9px | 4px |
| 105pt | 14px | 25px | **11px** |

Predicted and pixel-scanned values agreed within 1px in all six cases, so this is
real rendered geometry, not a metrics-API quirk. **At the same font size, in a box
with the same top, the glyph moves 11px purely from line-height.**

## The rule

**Compare ink to ink. Never compare box to box.**

A cap-top is the same physical thing in both tools; a box top is not. Measure the
rendered cap-top on both sides and diff those:

```js
// Browser side: cap-top in page coordinates, independent of line-height.
const r = el.getBoundingClientRect();
const cs = getComputedStyle(el);
const c = document.createElement('canvas').getContext('2d');
c.font = `${cs.fontWeight} ${cs.fontSize} ${cs.fontFamily}`;
const m = c.measureText('H');
const emBox = m.fontBoundingBoxAscent + m.fontBoundingBoxDescent;
const halfLeading = (parseFloat(cs.lineHeight) - emBox) / 2;   // NaN when `normal`
const capTop = r.top + halfLeading + (m.fontBoundingBoxAscent - m.actualBoundingBoxAscent);
```

`parseFloat` returns `NaN` for `line-height: normal`, which silently poisons the
result — resolve `normal` by measuring a rendered probe instead of assuming a ratio.
This is the same failure as deriving type size from an assumed cap-height ratio: one
render answers it exactly, and a constant never does.

## Prevention, which is cheaper than measurement

**Set an explicit line-height on both sides, in pixels, and never use AUTO or
`normal`.** Then the two boxes are identical by construction and the whole problem
disappears — no cap-top arithmetic, no accumulation, nothing to chase.

- Figma: `lineHeight = {value: N, unit: "PIXELS"}` — never leave it AUTO.
- CSS: `line-height: Npx` — a unitless ratio re-derives a different number per size,
  and `normal` is font-dependent.

`scripts/lint-node.js` flags AUTO line-height for this reason. It is not a
stylistic warning; it is the input to an unclosable diff.

## Why this is a speed rule, not a fidelity rule

A delta produced by mismatched reference lines is **unclosable by construction**.
Every correction moves the box, re-measures, and finds the artifact still there —
so the loop cannot terminate on success, only on a pass cap or exhaustion. That is
precisely how a build spends 20 rounds and still reports a non-zero residual.

Two guards, both of which must hold:

1. **Compare the right thing** (ink to ink), so a real delta can actually close.
2. **Stop at the tolerance** (±8pt position, ±3pt cap-height), so a residual inside
   the band is recorded rather than chased.

Without the first, the second is what saves you — the loop stops, but the build is
declared "converged" carrying a delta nobody understood. Fix the comparison and the
residual becomes real information.
