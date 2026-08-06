# Motion Standards

Authority: when `emilkowalski/skills` is installed, `emil-design-eng` and
`review-animations` are authoritative and this file defers to them. This file is
the numeric extract the QA pass scores against without loading the full skill set.
When those skills are absent, this file alone enforces the standard.

## 1. Should this animate at all?

Frequency decides presence. Check this before anything else.

| Frequency | Directive |
|---|---|
| 100+ times/day | No animation. Ever. |
| Tens of times/day | Remove or drastically reduce — opacity or color only |
| Occasional | Standard animation |
| Rare / first-time | Delight permitted |

**Never animate keyboard-initiated actions.** Command palettes, shortcuts, and
terminal prompts repeat constantly; motion reads as lag.

## 2. Purpose

Every animation needs a stated justification: spatial consistency (a toast
enters and exits on the same axis so swipe-to-dismiss feels right), state
indication, or preventing a jarring appearance. Reject "it looks cool" —
especially on frequently seen elements.

## 3. Easing — decision order

1. Entry / exit → `ease-out`
2. Moving / morphing → `ease-in-out`
3. Hover / color → `ease`
4. Constant motion → `linear`
5. Default → `ease-out`

**`ease-in` is banned on UI.** It delays the first moment the user is watching.

Custom curves:
- `ease-out`: `cubic-bezier(0.23, 1, 0.32, 1)`
- `ease-in-out`: `cubic-bezier(0.77, 0, 0.175, 1)`
- `ease-drawer`: `cubic-bezier(0.32, 0.72, 0, 1)`

## 4. Duration

**UI animations stay under 300ms.**

| Element | Range |
|---|---|
| Button press | 100–160ms |
| Tooltip / popover | 125–200ms |
| Dropdown | 150–250ms |
| Modal / drawer | 200–500ms |
| Micro-interaction | 100–150ms |
| Standard UI | 150–250ms |

Where ranges conflict, the tighter bound wins.

Asymmetric timing: deliberate user actions (press, hold, destructive confirm)
animate slower for weight; system responses snap. Symmetric timing on a
press-and-release is a finding.

Stagger: 30–80ms between items. Never block interaction.

## 5. Physicality

- **Never `scale(0)`.** Entry starts at `scale(0.9)`–`scale(0.97)` + `opacity: 0`.
- Popovers, dropdowns, tooltips scale from their trigger via `transform-origin`.
- Modals are the exception — center origin, they belong to the viewport.
- Button press: `scale(0.97)` on `:active`, 160ms `ease-out`.
- Crossfades use a blur to bridge states; without it two states visibly overlap.

## 6. Performance

- Animate **only `transform` and `opacity`**. These skip layout and paint.
- Never animate `width`, `height`, `margin`, `padding`, `top`, `left`.
- Never drive child transforms from a CSS variable on the parent — it forces
  style recalculation for every nested child.
- Framer Motion shorthands (`x`, `y`, `scale`) are not hardware-accelerated;
  they run on the main thread via rAF and drop frames. Use full CSS transform
  strings (`transform: translateY(10px)`) even inside Framer Motion.
- CSS transitions interrupt smoothly; keyframes restart from zero — avoid
  keyframes for rapidly retriggered motion.
- Engine choice: CSS for predetermined motion; WAAPI for interruptible JS-driven
  motion; Framer Motion for spring physics, drag, and layout morphing.
- `useSpring` for drag with momentum, "alive" elements, and interruptible gestures.

## 7. Gesture

- Momentum dismissal: compute velocity (distance ÷ elapsed ms), dismiss above `0.11`.
  Never use a bare distance threshold.
- Damping at boundaries: dragging past a natural edge takes progressively more effort.
- Pointer capture on drag start, so the element tracks a cursor that leaves its bounds.
- Multi-touch protection: ignore additional touch points once a drag begins.

## 8. Accessibility

```css
@media (prefers-reduced-motion: reduce) {
  /* keep opacity and color; drop transforms */
}
@media (hover: hover) and (pointer: fine) {
  /* gate all hover effects — touch fires false hovers */
}
```

Reduced motion means fewer and gentler animations, not zero.

## 9. Motion gaps

A conditional render (`{isOpen && <Modal />}`) with no exit animation wrapper
snaps out of existence. Flag it.
