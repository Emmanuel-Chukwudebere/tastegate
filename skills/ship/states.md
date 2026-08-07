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
| Focus-visible | a visible ring; never remove the outline without replacing it |
| Disabled | reduced contrast plus `cursor: not-allowed`; must still meet contrast minimums for readable text |
| Loading | a skeleton or spinner; reserve the final layout's space so nothing shifts on arrival |
| Empty | an invitation to act, not an apology. Say what to do next |
| Error | what went wrong and how to fix it, in the interface's voice. Never vague, never apologetic |

## Motion in states

Per `MOTION.md`:

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
