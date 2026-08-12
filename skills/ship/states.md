# Interaction States

A Figma frame is one state. Production code needs all of them. Generate every
applicable state — their absence is the main reason converted designs feel
unfinished.

## Required states

| State | Requirement |
|---|---|
| Default | from the Figma frame |
| Hover | **gated**: `@media (hover: hover) and (pointer: fine)` — touch fires false hovers, leaving sticky states |
| Active / pressed | `transform: scale(0.97)`, 160ms `ease-out` |
| Focus-visible | a visible ring; never remove the outline without replacing it. The ring needs ≥ 3:1 against **both** the component and the page behind it |
| Disabled | reduced contrast plus `cursor: not-allowed`; text still ≥ 4.5:1. "Disabled" is not permission to make it unreadable — dim the background, not the label |
| Loading | a skeleton or spinner; reserve the final layout's space so nothing shifts on arrival |
| Empty | an invitation to act, not an apology. Say what to do next |
| Error | what went wrong and how to fix it, in the interface's voice. Never vague, never apologetic |

## When the profile has no answer

Figma frames carry almost no states, so `TASTE.md` usually says nothing about
disabled, focus, or error. Derive them from the profile's palette rather than
inventing new colors — and where the derived value crosses a threshold above, that is
a conflict, not a judgement call: raise it per `design/CONFLICT.md` with the measured
value and the smallest fix. A focus ring is the common case, because a brand accent
chosen for large type routinely fails 3:1 as a 2px ring.

## Motion in states

Per `design/MOTION.md`:

- Hover and color shifts use `ease`.
- Entry and exit use `ease-out`; never `ease-in`.
- Animate only `transform` and `opacity`.
- Respect `prefers-reduced-motion`: keep opacity and color, drop transforms.
- Conditional renders need an exit animation wrapper, or the element snaps out of
  existence.

## Copy in states

Words are design material. Active voice; an action keeps the same name through the
whole flow, so a button that says "Publish" produces a toast that says
"Published". Name things by what people control, never by how the system is built.
