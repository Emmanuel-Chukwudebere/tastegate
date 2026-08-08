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
