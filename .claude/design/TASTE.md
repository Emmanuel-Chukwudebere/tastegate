# Taste Profile: Vela — dark waitlist hero

Source: combination — reference intake (`C:\Users\imman\Downloads\Mobile.png`,
pixel-measured) + design-system extract (open Figma file "Spry", 3 variable
collections, 44 primitives / 42 semantic per mode)
Last updated: 2026-08-10

Reference geometry was measured in pixel space and converted at **1.3410 px/pt**
(screen 523px wide ÷ 390pt). Every "measured" row below traces to a pixel probe or
a `figma-cli` read, not to an impression.

## Palette

Dark mode is the only mode this direction ships. Values are the file's own
`Semantic - Dark` aliases; the "reference" column is what the image actually
contains, so drift is visible rather than assumed.

| Name | Value | Role | Reference measured | Source |
|---|---|---|---|---|
| `bg` → `neutral/950` | `#0a0a0b` | dominant surface | `#060505` | measured (both) |
| `text` → `neutral/50` | `#f7f7f8` | headline, CTA label, proof | `#f5f5f5` | measured (both) |
| `text-muted` → `neutral/500` | `#6b6b72` | sub-copy, micro-copy | `#6b6b6b` | measured (both) |
| `accent` → `blue/500` | `#2e6bff` | CTA fill, eyebrow text | `#4f6ef7` | measured (both) |
| `border` → `neutral/850` | `#1d1d20` | nav pill hairline | `#1d1d20` (inferred from stroke) | measured / inferred |
| `on-accent` → `neutral/white` | `#ffffff` | CTA label on accent | `#f5f5f5` | measured (both) |

**Known drift, accepted:** the reference accent `#4f6ef7` sits between the file's
`blue/500` `#2e6bff` and `blue/400` `#5c86ff`. **The token wins** — a hero that
hardcodes `#4f6ef7` breaks theme switching and desyncs from every other Spry
surface. Same ruling for `bg`: reference `#060505` is 4 points darker than
`neutral/950`; bind the token.

Accent appears in exactly two placements: the eyebrow pill and the CTA. Nothing else.

## Typography

| Role | Family | Weights | Source |
|---|---|---|---|
| Display | Outfit | 600 | measured — identified by rendering an 8-family specimen at 44pt and comparing glyphs against the reference crop; matched on single-storey `a`, geometric bowls, tall x-height, and the `fl` ligature |
| Body | Outfit | 400, 500 | measured — same specimen pass |
| Utility | Outfit | 500 (eyebrow, tracked +0.08em, uppercase) | measured |

Scale ratio: ~1.35 display step, 1.0 body
Sizes (pt, measured from the reference): **44** headline / **17** sub-copy /
**17** CTA label / **15** micro-copy + proof / **12** eyebrow
Line heights (measured): **64** headline / **26** sub-copy / **20** micro
Measure: sub-copy wraps at 3 lines inside 342pt ≈ 42 characters — deliberately
narrow, not the ~65 default. Hold it.

**Outfit is not one of the file's existing families** (Syne display + Plus Jakarta
Sans text). This profile intentionally diverges because the reference is a distinct
product surface; do not "correct" it back to Syne, and do not mix the two on one
screen.

## Spacing

Scale: 4, 8, 12, 16, 24, 32, 48, 64
Density stance: airy — the hero's whole argument is negative space

Measured vertical rhythm (pt from screen top): status bar 44 · nav 173–221 ·
eyebrow 296–337 · headline 401–510 · sub-copy 537–606 · CTA 687–740 ·
micro 765–781 · proof 836–861
Side padding: **24** on every element, no exceptions (CTA = 342pt = 390 − 48)

## Breakpoint behaviour

| Width | Layout | Notes |
|---|---|---|
| 390 | single column, everything centered | the reference; the canonical case |
| 834 | single column, max-width 560, still centered | headline 56pt; sub-copy holds 3 lines by widening measure, not by adding a line |
| 1440 | single column, max-width 640, centered | headline 72pt; nav gains inline links, burger hides |

Centered at every width. This direction has no asymmetric variant.

## Icon set

Primary: Iconsax (local instances in this file, `vuesax/…`)
Path: local `<Icon name="vuesax/twotone/…">` instances — 18 components already in file
Variant: **twotone**, exclusively

Hero needs: a 4-point sparkle for the eyebrow, a burger for the nav. Where twotone
has no equivalent, draw it as `<SVG>` rather than substituting another variant.

## Motion

Appetite: restrained
Notable references (all **inferred** — a still image carries no timing):
- Eyebrow + headline + sub-copy + CTA: staggered fade-and-rise on load, 60ms apart,
  ~400ms each, `cubic-bezier(0.16, 1, 0.3, 1)`, y-offset 12px
- CTA hover: `accent` → `accent-hover` (`blue/400`), 150ms
- CTA press: scale 0.98, 100ms
- Ambient: the background's soft caustic streaks suggest a very slow drift; if
  animated, ≥20s and `prefers-reduced-motion` must disable it

`design/MOTION.md` applies regardless of appetite.

## Signature element

**The 44/64 headline breaking across two lines in near-white Outfit 600, floating in
almost pure black with nothing competing.** The line break is load-bearing — "Your
work," / "finally in flow." The comma ends line one; the period ends line two. If the
headline is not the first and most memorable thing the eye lands on, the build failed
regardless of its scorecard.

## Never list

Recorded from the reference and this session's constraints.

- Never mix Iconsax variants — twotone only, no linear, no bold
- Never hardcode a hex where a token exists; `var:` slash form only
- Never let Inter appear in output — it means a font failed to bind
- Never use more than two accent placements per screen
- Never widen the sub-copy measure past 3 lines at 390
- Never left-align the hero stack; centered at every breakpoint
- Never add a second CTA, a feature grid, or a "trusted by" logo row to this hero
