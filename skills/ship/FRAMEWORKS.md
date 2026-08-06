# Framework Targets

Default target is **React**. The user may name another: `/claude-design:ship vue`,
`… svelte`, `… react-native`, `… html`.

**Detect before asking.** Read `package.json`, config files, and existing
components to determine the framework and styling system already in use. Never
introduce a second styling paradigm into a project that has one — if the project
uses Tailwind, emit Tailwind; if it uses CSS modules, emit CSS modules.

| Target | Styling | Motion |
|---|---|---|
| React (default) | CSS custom properties, or Tailwind if the project uses it | CSS transitions; Framer Motion only for spring physics, drag, or layout morphing |
| Vue | same token variables | native `<Transition>`, same curves |
| Svelte | same token variables | native transitions, same curves |
| React Native | `StyleSheet` derived from the same tokens | Reanimated, curves ported to its easing API |
| Plain HTML | CSS custom properties | CSS transitions |

## Token source

Never hand-write token values. Generate them:

- `figma-cli export css` → CSS custom properties
- `figma-cli export tailwind` → Tailwind config
- `figma-cli export dtcg tokens.json` → W3C DTCG JSON

Then reference those variables in emitted components.

## Unsupported targets

If the requested target is not listed, say which targets are supported and stop.
Do not guess at an unfamiliar framework's idioms.

## Motion per target

All targets use the curves and durations in `MOTION.md`. Only the expression
differs. React Native has no CSS, so curves are ported to Reanimated's easing
functions while preserving the same timing values.
