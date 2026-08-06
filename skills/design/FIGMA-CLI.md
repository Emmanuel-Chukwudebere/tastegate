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
