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

**Elements:** `<Frame> <Text> <Rect>`/`<Rectangle>` `<Ellipse>`/`<Circle>` `<Image>` `<Icon>` `<Slot>`

That list is the parser's tag regex verbatim. **There is no `<SVG>` and no `<Line>`**, and
`<Instance>` parses but cannot render — see the icon section below for what to use instead.

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

## `<Icon>` reaches Iconify only, and a miss renders as an empty frame with exit 0

`<Icon name="prefix:name">` fetches from `api.iconify.design` at render time. Three
consequences, all verified live:

1. **A local component is not reachable through `<Icon>`.** `name="vuesax/twotone/menu"`
   has no colon, never becomes a fetch, and produces a frame with **zero children** —
   invisible, with no warning and exit 0.
2. **Iconsax is not on Iconify.** Neither `iconsax` nor `vuesax` is a collection there
   (`/collections?prefixes=iconsax,vuesax` returns nothing; searching `magic-star`
   returns only `reicon:`). A file whose taste profile pins Iconsax must source glyphs
   from its own local components.
3. **A fetch failure is silent.** `prefetchIconSvgs` swallows the error and falls back to
   a placeholder rectangle, so a wrong prefix renders as a filled square and a network
   failure renders as nothing. Both exit 0.

**`<SVG>` does not exist.** The parser's tag list is
`Frame|Text|Icon|Rect|Rectangle|Ellipse|Circle|Image|Slot|Instance` — there is no `SVG`
element, and using one fails with `SVG is not defined`.

**`<Instance>` parses but its codegen is unreachable**, so it also fails with
`Instance is not defined`. To place a local component, use the Plugin API through
`eval`/`run`:

```js
const comp = await figma.getNodeByIdAsync('38:30805');
const inst = comp.createInstance();
parent.appendChild(inst);
```

For a glyph that exists in neither Iconify nor the local set, build it with
`figma.createNodeFromSvg(svgString)`, clear the wrapper's fills, resize, then recolor
the children — `createNodeFromSvg` returns a Frame whose fill shows as a filled square
if left alone.

**Always assert icon children after rendering.** The count is the only signal:

```bash
figma-cli eval "(async () => { const n = await figma.getNodeByIdAsync('<id>'); \
  return n.findAll(x => x.name === 'Icon').map(x => x.name + ':' + x.children.length).join(' '); })();"
```

## Speed: check the daemon, and never trust `status` for it

**A stale daemon token costs 6.6× on every call, and nothing reports it.**
`figma-cli status` prints `Connected to Figma` whenever CDP is reachable — it says
nothing about whether the daemon's auth actually works. When the token is stale,
every `eval`/`run` silently falls back to a cold Node spawn plus CDP handshake.

Measured in one session: **20.1s per `eval` round-trip with a mismatched token, 3.0s
after `daemon restart`.** The work itself was ~1s; the rest was process startup. Across
~30 calls that is eight minutes of pure overhead, invisible in every command's output.

```bash
figma-cli daemon status     # the only command that reveals it
figma-cli daemon restart    # regenerates the token
```

`daemon status` reports `auth failed (token mismatch)` in this state. Check it in
preflight and after any `Unauthorized` error — and re-time a call to confirm the fix,
since the error stops appearing before the speed comes back.

## `lint` cannot be scoped, so it is unusable on a large file

`figma-cli lint` has **no node argument and no scoping flag, and it ignores the current
selection** — `figma-cli select <id>` then `lint` still walks the whole document.
Measured against a 57,158-node design system: **36–41s, then `CDP timeout` and a
non-zero exit.** It never completes, so it cannot gate anything there.

Worse: **`lint --fix` at that scope rewrites the entire design system** to "fix" one
new frame. Do not run it to gate a single build.

Use `scripts/lint-node.js` instead — the same checks (unbound colors, off-scale
spacing, empty icon frames, detached instances, AUTO line-height) over one subtree
via the Plugin API, in ~2s with a healthy daemon.

## `run` returns nothing when a file starts with `//` comments

`figma-cli run <file>` **silently produces no output, no error, and exit 0** if the
file carries leading `//` comment lines before the opening `(async () => {`.

Verified by stripping an 11-line header from an otherwise byte-identical file: header
present = empty output; header removed = correct output. The bodies diffed clean, so
the header alone caused it.

Put every comment **inside** the IIFE, as a `/* … */` block:

```js
(async () => {
  /* rationale goes here, not above the IIFE */
  …
})();
```

This failure mode is especially dangerous in a gate: an empty result reads as "clean".

## Generated scripts need a path both the shell and figma-cli can open

On Git Bash, `mktemp` returns a POSIX path (`/tmp/foo.js`) that the shell resolves but
`figma-cli` — a Windows Node process — cannot. And `cygpath -u "$TEMP"` returns `/tmp`
while `cygpath -m /tmp` maps to `AppData\Local\Temp`: **two different directories**, so
the shell writes one file and the CLI reads another that is not there. Empty output,
exit 0, gate appears to pass.

Pick the shell-side directory first, then convert that exact path:

```bash
SCRATCH_SH="${TMPDIR:-/tmp}"
SCRATCH_WIN="$(cygpath -m "$SCRATCH_SH" 2>/dev/null || echo "$SCRATCH_SH")"
printf '%s' "$script" > "$SCRATCH_SH/gen.js"
figma-cli run "$SCRATCH_WIN/gen.js"
```

## An invisible node exports a blank PNG at exit 0

`export node` and `verify` both succeed on a node with `visible = false`, printing
`✓ Exported … (390x840)` and writing a **~149-byte fully transparent PNG**. Nothing in
the output distinguishes it from a real export.

Check the file size, not the exit code. A real 390×840 frame is tens of kilobytes:

```bash
figma-cli export node <id> --scale 2 -o out.png
[ "$(wc -c < out.png)" -gt 1000 ] || echo "BLANK EXPORT — check node.visible"
```

Found live: a hero frame silently became `visible=false` mid-session with all eight
child sections still `visible=true`, so the tree looked healthy and every export was
empty. `figma-cli get <id>` reports the flag; `visible` is the first thing to check
when an export looks wrong.

## `getNodeByIdAsync` hangs on a nonexistent id rather than returning null

A wrong node id does **not** resolve to `null` — the call never settles, and the CLI
dies at its 90s execution timeout, then falls back to a sync path that also times out:

```
✗ Execution timeout (90s). Try reconnecting: node src/index.js connect
⚠ Daemon error, trying sync path...
✗ spawnSync … ETIMEDOUT
```

So the usual guard is not enough on its own — `if (!node) return "not found"` never
runs, because control never reaches it:

```js
const node = await figma.getNodeByIdAsync(id);
if (!node) return "not found";   // unreachable when `id` does not exist
```

Keep the guard (it catches a node deleted mid-session), but **verify an id exists
before evaluating against it** — `figma-cli find <name>` or `figma-cli get <id>` both
fail fast. A 90s hang inside a gate reads as a hung pipeline, not as a bad argument,
which is what makes this expensive to diagnose.

## `spec` and `instantiate` cannot see a registry in a dot-directory

Both auto-locate a `DESIGN.md` by scanning cwd and one level of subdirectories, and
that scan **skips every entry beginning with `.`** — which is exactly where this
plugin writes its registry (`.claude/design/registry.md`). So the reuse path is dead
by default:

```bash
figma-cli spec "Button"                                   # ✗ No DESIGN.md found
figma-cli spec "Button" --file .claude/design/registry.md  # Button (60 variants)
```

Verified live against a real 42-component registry: the bare call reported
`✗ No DESIGN.md found`, the `--file` call returned the full spec. **Always pass
`--file`.** The same applies to `instantiate` and to `spec --check`, so
`scripts/gates.sh` passes it too — without it, the spec gate never ran at all and
reported a skip that looked like a pass.

Two further constraints on the file itself:

1. **Auto-locate requires the literal marker `Sample variant structure:`.** A `.md`
   without it is not a candidate, even in cwd, even named `DESIGN.md`.
2. **A component block needs `### Name`, a `· N variants` line, and a `Reuse:` line.**
   `findComponentSpec` silently skips any block missing them, so a
   plausible-looking hand-written registry parses to zero components.

**The two failure messages are indistinguishable in practice.**
`✗ No DESIGN.md found` and `✗ No component matching "Button"` are both a red `✗` at
exit 1 — so "the registry is unreachable" reads the same as "this component does not
exist," and the sensible response to the second (build it) is catastrophic for the
first: the design system is never consulted and every build re-draws it. This is the
mechanism behind "it keeps drifting from my components."

## `extract` needs its output directory to exist, and times out unscoped

Three failures, all found on a 6,287-component file:

| Call | Result |
|---|---|
| `extract … .tmp/DESIGN.md` (no `.tmp/`) | `✖ ENOENT: no such file or directory` |
| `extract --sections components` (unscoped) | `✖ Extraction failed: Connection timeout` |
| `extract --pages "Components"` (no such page) | `✖ No pages match "Components"` |
| `extract --sections components --pages "Style Guide"` | ✔ 55,915 nodes, 42 components |

`mkdir -p` the target directory first, and scope with `--pages` using a name from
`figma.root.children`, not a guess. All three failures exit non-zero, but all three
print a `✖` that reads like a connection problem rather than a bad argument.

## Extracting an image fill: `export node` is the wrong tool

`export node` rasterises the node **as composited on canvas** — every scrim, overlay,
and vignette baked in, at whatever `--scale` you pass. Measured on one 1440×900 hero:
a **4.07MB PNG** re-render versus the **766KB original JPEG** the fill actually holds.
The re-render is both larger and wrong, since the overlays must stay live in CSS.

Read the source bytes instead, via the fill's hash:

```js
const paint = node.fills.find(p => p.type === "IMAGE");
const image = figma.getImageByHash(paint.imageHash);
const bytes = await image.getBytesAsync();      // the original asset, byte-exact
const size  = await image.getSizeAsync();       // natural dimensions
```

`scripts/extract-image.js` does this and prints base64 for the shell to decode.
Verified byte-identical: 765,831 bytes in Figma, 765,831 on disk.

Three things to carry across with it:

| Figma | CSS |
|---|---|
| `scaleMode: "FILL"` | `object-fit: cover` |
| `scaleMode: "FIT"` | `object-fit: contain` |
| `scaleMode: "CROP"` | `cover` plus an offset from `imageTransform` |
| `scaleMode: "TILE"` | `background-image` + `background-repeat` |

**The fill's natural aspect ratio decides whether `object-position` does anything.**
A portrait source in a landscape box has zero horizontal overflow, so a horizontal
bias is a silent no-op — measured live: `object-position: 22%` and `50%` rendered
identically on a 1920×2880 fill in a 1440×900 frame. Compute the overflow before
tuning a crop, or the tuning is imaginary.

The format is not recorded on the paint, so **sniff the magic bytes** (`FF D8` JPEG,
`89 50` PNG, `47 49` GIF, `52 49` WebP). Naming a JPEG `.png` renders fine in a
browser and breaks every image pipeline downstream.

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
