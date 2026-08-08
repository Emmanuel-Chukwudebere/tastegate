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

## The five gotchas

| Wrong | Right |
|---|---|
| `layout="horizontal"` | `flex="row"` |
| `padding={24}` | `p={24}` |
| `fill="#fff"` | `bg="#fff"` |
| `cornerRadius={12}` | `rounded={12}` |
| `bg="var:neutral-900"` (hyphen, from `export css`) | `bg="var:neutral/900"` (slash, from `var list`) |

## Slash vs. hyphen: the token-name gotcha

Variables are named with slashes as their path separator, exactly as
`var list` prints them: `neutral/900`, `colors/brand-blue`. `export css`
flattens those slashes to hyphens to produce valid CSS custom-property
names: `--neutral-900`. **A `var:` reference must use the slash form,
matching `var list`, not the hyphen form from `export css`.** The hyphenated
name is a CSS artifact, not the variable's name in Figma.

Live evidence from a real design system (collections `Primitives`,
`Semantic - Light`, `Semantic - Dark`): `export css` emitted
`--neutral-900: #141416;`, and `var list` showed the same variable as
`neutral/900 (COLOR)`. Rendering with the CSS-derived form —
`bg="var:neutral-900"` — produced:

```
⚠ 3 variable reference(s) could not be resolved:
  neutral-300, neutral-900, neutral-white
  These bindings rendered as grey placeholders.
```

**An unresolved `var:` reference does not fail the render.** It warns,
renders a grey placeholder, and the command still exits 0 — so it is only
caught by reading the warning or by the visual pass, never by exit code
alone. Re-rendering with `bg="var:neutral/900"` resolved cleanly with no
warnings.

Verify names with `figma-cli var list` (and `figma-cli collections list`)
before writing `var:` references, rather than inferring them from
`export css` output. Where multiple collections exist (as here — three
collections, each defining its own `neutral/900`), pin resolution with
`-c <collection>` (e.g. `-c Primitives`), or use the fully qualified
`var:collection:name` form.

## Inter is every text node's initial state, so a font that never binds stays Inter

**Inter Regular is the default `fontName` of a newly created text node**, not a
fallback the tool chooses. Verified directly: `figma.createText()` reports
`{"family":"Inter","style":"Regular"}` before any font is loaded, and reports the
intended family only after `loadFontAsync` resolves and the style is assigned.

So text rendering in Inter does not mean a wrong weight vocabulary — it means the
font binding did not complete. `render` reports success and exits 0 either way,
because the node was created; only the binding lagged.

What was observed live: `weight="semibold" font="Syne"` at 105px left the node on
Inter, while `weight="600" font="Syne"` bound correctly, and both forms bind
correctly when set after an explicit `loadFontAsync`. Treat the numeric form as the
more reliable one for a family whose style names are non-obvious, but understand the
failure as a load-order problem rather than a rejected keyword.

This matters beyond aesthetics: Inter arriving uninvited is the "generic type" entry
in `SLOP.md`, so an unbound font plants the exact defect the rubric exists to catch,
in the most-repeated text on the page.

**Probe the result rather than trusting the render.** Weight is not visible in
`render`'s output, so verify it mechanically — see the font-binding gate in
`SKILL.md` step 5. To repair unbound text, load the font first, then assign:

```js
await figma.loadFontAsync({family:'Syne', style:'SemiBold'});
node.fontName = {family:'Syne', style:'SemiBold'};
```

Confirm the styles a family actually offers before assigning one:

```bash
figma-cli eval "(async () => (await figma.listAvailableFontsAsync()).filter(f => /syne/i.test(f.fontName.family)).map(f => f.fontName.style))()"
```

`figma-cli eval` and `run` reject top-level `await` and bare `return`. Wrap the
body in an async IIFE — `(async () => { … })();` — and end with the value.

## `verify` writes to `/tmp`, which is `C:\tmp` on Windows

`figma-cli verify <nodeId>` saves to `/tmp/figma-verify-<id>.png`. Node resolves
that to `C:\tmp` on Windows, so it fails with `ENOENT` until the directory exists:

```bash
mkdir -p /c/tmp
```

`render --verify` and `render-batch --verify` are unaffected — they write to the
real `%TEMP%`. Prefer them, since they return the screenshot in the same call.

## Command map

| Purpose | Command |
|---|---|
| Connect / health | `connect`, `status`, `diagnose` |
| Build | `render '<Frame>…' --verify`, `render-batch '[…]' --verify` |
| See | `verify [nodeId]` (add `--base64` for inline) |
| Undo | `undo` (removes nodes from the last render) |
| Reuse | `spec <component>`, `instantiate <name>` |
| Enforce | `spec <component> --check <nodeId> --tolerance 2` (exit 1 on violation) |
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
