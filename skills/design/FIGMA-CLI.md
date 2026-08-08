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
