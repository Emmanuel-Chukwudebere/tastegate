# Vela hero — Figma → React

Shipped from Figma node `373:8840` in the file "Spry" via `/claude-design:ship`.
Kept as a worked example of what the pipeline emits, including what it could not verify.

```
tokens.json            figma-cli export dtcg — aliases intact
src/tokens.css         generated from tokens.json by scripts/dtcg-to-css.js
src/Hero.tsx           component, all states
src/Hero.module.css    styles, motion, breakpoints
```

## Regenerating the tokens

```bash
figma-cli export dtcg tokens.json
node ../../scripts/dtcg-to-css.js tokens.json > src/tokens.css
```

**Do not use `figma-cli export css`.** It cannot resolve variable aliases and emits
`--accent: #NaNNaNNaN;` for all 21 semantic tokens. The DTCG export keeps them as
`{blue.500}` references, which `dtcg-to-css.js` converts to `var(--blue-500)` — so the
indirection survives and a light/dark switch still works.

## What was measured

| Property | Source |
|---|---|
| Type family (Outfit) | identified by rendering an 8-family specimen at 44pt and comparing glyphs against the reference crop — single-storey `a`, geometric bowls, `fl` ligature |
| Type sizes | reference cap-heights at 1.4308 px/pt, then a probe render to get Outfit's own cap ratio |
| Colors | `figma-cli export dtcg`; reference values sampled per region from the source PNG |
| Geometry | pixel-measured against the reference's true screen bounds |
| Contrast | `figma-cli a11y audit 373:8840` |
| Fonts | the font gate in `scripts/gates.sh` |

## What was NOT verified

**The pixel diff did not run.** `ship/SKILL.md` step 7 requires screenshotting the
built UI at the Figma frame's width and diffing it against the frame — that needs a
dev server, and this repo is the plugin itself with no React app to host the
component. So the numbers above are measured from Figma and from the reference image;
**the rendered browser output was never compared to either.**

To close that gap, drop `src/` into any React app with CSS Modules and:

```bash
# with the app running at :3000
figma-cli export node 373:8840 --scale 2 -o figma.png
# then Playwright at 390 wide, screenshot, and compare
```

Expect real deltas: browser font rasterization differs from Figma's, and `text-wrap:
balance` may break the headline differently than the hard `<br>` intends at some widths.

## Residual deltas from the Figma build

The build stopped inside the convergence band (±8pt position, ±3pt cap-height) rather
than at zero. Measured against the reference at 390pt:

| Element | Reference top / cap-height | Build | Delta |
|---|---|---|---|
| CTA | 563 / 49 | 563 / 56 | 0 / +7 (DS Button Large is 56; the component wins) |
| social proof | 702 / 25 | 702 / 25 | 0 / 0 |
| headline L1 | 296 / 29 | 296 / 26 | 0 / −3 |
| sub-copy | 423 | 430 | +7 |
| eyebrow | 204 | 194 | −10 |

The eyebrow is the one value outside the band, at −10pt.

## Deliberate divergences from the reference

Ruled in `.claude/design/TASTE.md`; do not "fix" these:

- **Accent** is `blue/500` `#2e6bff`, not the reference's sampled `#4f6ef7`.
  Hardcoding the sample would break theme switching and desync from every other
  Spry surface.
- **Background** is `neutral/950` `#0a0a0b`, not `#060505`.
- **CTA height** is 56, the DS Button Large, not the reference's 49.
- **Logo** is a placeholder mark. The reference is Vela's; the Figma build stands in
  Spry's `SPRY_ICON_ON_BLACK`.
- **Micro-copy** uses `--neutral-400`, not `--text-muted`. `text-muted` measured
  3.74:1 against `bg` — below the 4.5:1 minimum.

## Component fonts

The reused Spry components brought their own type: the Button label arrived as
Syne/SemiBold and the Avatar initials as Plus Jakarta Sans/SemiBold, inside an
otherwise all-Outfit hero. `TASTE.md` forbids mixing families, so both were overridden
in Figma. The font gate now reports family count and names which families come from
inside instances, since a "no Inter" check passes right over this.
