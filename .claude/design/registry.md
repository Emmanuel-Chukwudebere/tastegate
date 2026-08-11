# Component Registry

Generated: 2026-08-10 from the open Figma file "Spry".
Source: `figma-cli extract --sections components` (43 components, 4 pages, 57,158 nodes)
        + `figma-cli analyze clusters --json` (20 clusters detected, figma-use available)

**Never hand-edit.** Regenerate with the two commands above.

## Handles

| Component | Variants | Page | Node | Key |
|---|---|---|---|---|
| Button | 60 variants | Style Guide | `103:229` | `6171d67ef7fe…` |
| IconButton | 9 variants | Style Guide | `135:1101` | `62a8f864cb1e…` |
| Input | 15 variants | Style Guide | `146:1264` | `de2850b7bd26…` |
| Toggle | 3 variants | Style Guide | `150:1286` | `2e3bacc10b1d…` |
| SegmentedControl | 3 variants | Style Guide | `152:1339` | `413e5ff71b62…` |
| Chip | 4 variants | Style Guide | `152:1360` | `ab82d2884ad4…` |
| Badge | 10 variants | Style Guide | `153:1385` | `fb6f4eb399d5…` |
| Checkbox | 4 variants | Style Guide | `155:2503` | `d80e7ba24afe…` |
| Radio | 3 variants | Style Guide | `156:2518` | `0be7ff6d934c…` |
| Textarea | 4 variants | Style Guide | `161:1709` | `c999dd8d591c…` |
| Select Trigger | 6 variants | Style Guide | `162:1774` | `16f545bc2f7a…` |
| MenuItem | 4 variants | Style Guide | `163:1796` | `78cbcbdba015…` |
| ActionMenuItem | 4 variants | Style Guide | `169:1978` | `aefea4cfb05e…` |
| Divider | 2 variants | Style Guide | `172:2037` | `f1a432e2705b…` |
| Tooltip | 4 variants | Style Guide | `176:2096` | `1cf0f1be8fff…` |
| TabItem | 6 variants | Style Guide | `187:2117` | `f8ce13601a28…` |
| Logo | 4 variants | Style Guide | `197:2328` | `ea91708b70ba…` |
| Stepper | 4 variants | Style Guide | `197:2330` | `a8ed54463f21…` |
| Slider | 2 variants | Style Guide | `200:2343` | `89e5a3b655e2…` |
| Avatar | 9 variants | Style Guide | `200:2379` | `fcf5896c1955…` |
| Card | 3 variants | Style Guide | `202:2395` | `341a6dede074…` |
| Sheet | 2 variants | Style Guide | `204:2431` | `e339dcaaa649…` |
| DatePicker Trigger | 4 variants | Style Guide | `205:2502` | `f7c4b8a15c8f…` |
| AmountText | 9 variants | Style Guide | `217:2352` | `2ec2881d089d…` |
| CategoryChip | 3 variants | Style Guide | `222:2430` | `c57f8e64d9a3…` |
| TxnRow | 4 variants | Style Guide | `223:2483` | `07f78ea051f9…` |
| StatCard | 2 variants | Style Guide | `240:2838` | `e6d3fd28901a…` |
| BudgetBar | 3 variants | Style Guide | `243:2984` | `a22b952db209…` |
| PriceTag | 16 variants | Style Guide | `245:3077` | `6f108a2c9709…` |
| DebtRow | 8 variants | Style Guide | `246:3210` | `be47eac3e78c…` |
| MessageBubble | 2 variants | Style Guide | `251:3763` | `cf549ef11f23…` |
| VoiceButton | 3 variants | Style Guide | `255:3913` | `2e1fd8222d51…` |
| AttachmentPreview | 3 variants | Style Guide | `258:3949` | `523661eb843b…` |
| Composer | 6 variants | Style Guide | `264:4174` | `86e54c2ab345…` |
| BottomNav | 4 variants | Style Guide | `272:4597` | `d0959aee2af4…` |
| TopBar | 2 variants | Style Guide | `290:4041` | `8a9e458c6412…` |
| NudgeRow | 12 variants | Style Guide | `292:4242` | `d01cb573cca8…` |
| Toast | 4 variants | Style Guide | `295:4753` | `c1817b43196d…` |
| EmptyState | 4 variants | Style Guide | `301:5317` | `bad88cff90b7…` |
| PaywallSheet | 6 variants | Style Guide | `323:3919` | `e11a92e46a72…` |
| onboarding varient | 3 variants | Mobile Design | `232:1418` | `afb3212762df…` |
| Frame 13 | 3 variants | Mobile Design | `232:1157` | `8c2cea54cb2a…` |
| Frame 53 | 3 variants | Mobile Design | `277:2318` | `58bd89fde04c…` |

## Bound tokens

Three collections, resolved via `figma-cli var list` and a Plugin API alias walk.
`var:` references must use the **slash** form.

Primitives (44): `neutral/950…50`, `neutral/white`, `blue/50…900`,
`green|amber|red/50…900`, `status/{green,amber,red}-500`

Semantic — Dark (42, the mode this direction uses):

| Token | Alias | Hex |
|---|---|---|
| `bg` | `neutral/950` | `#0a0a0b` |
| `bg-elevated` | `neutral/900` | `#141416` |
| `surface` | `neutral/950` | `#0a0a0b` |
| `surface-2` | `neutral/900` | `#141416` |
| `border` | `neutral/850` | `#1d1d20` |
| `text` | `neutral/50` | `#f7f7f8` |
| `text-muted` | `neutral/500` | `#6b6b72` |
| `text-faint` | `neutral/600` | `#45454d` |
| `accent` | `blue/500` | `#2e6bff` |
| `accent-hover` | `blue/400` | `#5c86ff` |
| `on-accent` | `neutral/white` | `#ffffff` |
| `focus-ring` | `blue/500` | `#2e6bff` |

Semantic — Light (42): same token names, light aliases. Switch with
`figma-cli use "Semantic - Light"`.

## Relevant to this hero

| Need | Handle | Fit |
|---|---|---|
| CTA button | `Button` · Style=Primary, Size=Large, State=Default | **use** — 60 variants incl. Hover/Pressed/Disabled |
| Nav pill | `Button` · Style=Ghost or Quiet, Size=Medium | **use** — outlined pill |
| Burger | `IconButton` · Style=Ghost, Size=Medium | **use** |
| Eyebrow pill | `Badge` · Scale=Info, Variant=Subtle | **check** — 52×24 at 4/10 padding vs the reference's 318×41; likely too small, compose if so |
| Social proof stack | `Avatar` · Type=Image, Size=Small (32×32) | **use** — overlap by −8 |
| Logo | `Logo` · Variant=SPRY_ICON_ON_BLACK | **substitute** — the reference is Vela's mark, not Spry's; Spry's icon-on-black is the correct stand-in |

## Type styles in file

Measured by `figma-cli analyze typography`. Note **Outfit is absent** — this
direction introduces it (see `TASTE.md` § Typography).

| Family | Nodes | Role in file |
|---|---|---|
| Plus Jakarta Sans | 534 | body / UI text |
| Product Sans | 378 | Vuesax icon-sheet labels only — not a DS family |
| Syne | 74 | display |
| Inter | 17 | **unbound-font residue**, not intentional |
