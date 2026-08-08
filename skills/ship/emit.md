# Emit Procedure

## Three layers, two of them free

| Layer | Command | Cost |
|---|---|---|
| Structure | `export-jsx <nodeId> --pretty` | tool — exact, free |
| Token values | `export css` / `export tailwind` / `export dtcg` | tool — exact, free |
| Catalogue | `export-storybook <nodeId>` | tool — free |
| Idiom, states, motion | you | the only part needing judgement |

## What `export-jsx` is, and is not

It takes only `--output` and `--pretty` — no framework target, no token-binding
flag. So it produces a **structural scaffold**: correct hierarchy, nesting, and
layout intent, straight from the canvas.

It does **not** produce idiomatic framework code, token-bound values, interaction
states, or motion. Treat it as step zero of emit, not a replacement for it:

```
export-jsx        → structure       (exact, free)
export css/dtcg   → values          (exact, free)
you               → idiom, states, motion
```

This is why fidelity is achievable: the geometry is never re-derived by a model.

## Auto Layout maps onto flexbox

`extract --selection` returns Auto Layout values — padding, gap, alignment,
constraints, sizing. These map directly:

| Figma Auto Layout | CSS |
|---|---|
| direction horizontal / vertical | `flex-direction: row` / `column` |
| gap | `gap` |
| padding | `padding` |
| primary axis alignment | `justify-content` |
| counter axis alignment | `align-items` |
| fill container | `flex: 1` or `width: 100%` |
| hug contents | `width: fit-content` |

Because the values are extracted rather than estimated, conversion is
measurement, not interpretation.

## Mapping

1. Registry handle → existing project component. Check the project's component
   directory before creating anything new.
2. Bound Figma variable → the CSS variable of the same name emitted by
   `export css`. Keep the namespace identical across Figma and code; that shared
   namespace is what makes drift detectable later. The spelling changes at the
   boundary: Figma names variables with slashes (`neutral/900`, matching
   `var list`), and `export css` flattens each slash to a hyphen for a valid
   CSS custom-property name (`--neutral-900`). That flattening is mechanical
   and one-to-one, not a mismatch — the code-side hyphenated form and the
   Figma-side `var:` slash form are the same token under two spellings, and a
   `var:` reference in JSX must use the slash form, not the CSS one.
3. Never invent a value. If something is unbound in Figma, that is a finding to
   report, not a number to guess.
