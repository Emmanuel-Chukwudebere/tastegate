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

Requires `playwright` (`npm i -g playwright`); if it is unavailable, capture the reference visually via Playwright MCP or a screenshot instead, and record the resulting values as **inferred rather than measured**.

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
`design/MOTION.md` scores against. It also fingerprints libraries: a `--sonner` or
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
`design/MOTION.md`, and record the result in `TASTE.md` as **inferred**, never as measured.

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
