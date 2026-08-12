# When brand and usability conflict

The profile in `TASTE.md` is the user's stated intent, and following it is the
default. But a profile can encode something that measurably harms use — and
shipping that silently is not obedience, it is withholding a finding.

**Surface the conflict, propose the smallest fix that keeps the brand intact, and let the user decide.**
Never silently override the profile, and never silently comply with a violation.

## Only real conflicts, and the difference is measurable

The distinction is not taste-versus-taste. It is whether the requirement crosses a
threshold that exists independently of any brand.

| Push back | Do not push back |
|---|---|
| Body text at 4.1:1 (WCAG AA needs 4.5:1) | A palette you find drab |
| A 20×20 tap target (needs ≥ 24×24) | An unfashionable layout |
| A 400ms hover transition (>300ms drags) | Sharp corners where you would round |
| A control with no feedback for 600ms (Doherty: <400ms) | A deliberate delay the profile asks for |
| Text over an image with no scrim, contrast unmeasurable | A dense grid, when the profile says dense |
| Motion with no `prefers-reduced-motion` path | An accent used more sparingly than you would |
| Placeholder-only labels (lost on input) | Type larger or smaller than your instinct |
| Disabled state at 2:1 against its background | An unconventional nav position |

The right column is **the profile winning, which is correct**. A brand that looks
unlike your defaults is the entire point of grounding — `SLOP.md` exists because the
generic default is the failure mode. Aesthetic disagreement is not a finding, and
treating it as one is how a tool becomes exhausting to use.

The left column is different in kind: each crosses a numeric threshold from WCAG,
`MOTION.md`, platform touch guidance, or a quantified UX law.
**If you cannot name the threshold and the measured value, you do not have a conflict — you have a preference.**
Do not raise it.

`UX-LAWS.md` lists which laws carry numbers and which do not. Cite the source that
actually holds the value: WCAG 2.5.8 for 24×24, not Fitts's Law, which specifies none.
A law cited for a number it does not contain launders a preference as a standard, and
Miller's Law explicitly warns against exactly that. The directional laws still belong in
the **WHY IT MATTERS** line — Jakob's Law is the honest way to say an unconventional
pattern costs relearning — but they never justify raising a conflict on their own.

## How to raise one

Four lines, before building, not after:

```
CONFLICT: TASTE.md sets body text #8A8A8E on #F4F1EA — 3.2:1, WCAG AA needs 4.5:1.
WHY IT MATTERS: fails for low-vision users and in sunlight; it is the body copy, so it affects every screen.
SMALLEST FIX: darken to #5F5F63 — 4.6:1, same hue family, same perceived warmth.
YOUR CALL: [1] apply the fix  [2] ship as specified, recorded as a known exception  [3] apply it here only, profile unchanged
```

Then **build option 1 while waiting**, unless the fix would change layout. The
decision is the user's; the wait need not be idle.

Rules for the fix you propose:

- **Smallest change that clears the threshold**, not the change you would prefer.
  Clear 4.5:1 at 4.6, not 7.0 — every extra step spends brand equity that is not
  yours to spend.
- **Hold the hue, weight, and family.** Adjust lightness. A conflict is not an
  opening to redesign.
- **Name the measured before and after.** "Darken it" is not a fix; "#8A8A8E → #5F5F63,
  3.2:1 → 4.6:1" is.
- **One conflict, one decision.** Batch all conflicts into a single message rather
  than interrupting per finding, and never bundle a preference in with them.

## Record the decision, so it is asked once

A conflict resolved and then re-raised next session is worse than one never raised —
it teaches the user to ignore the mechanism.

When the user chooses **[2] ship as specified**, append to `TASTE.md` under
`## Accepted exceptions`:

```markdown
## Accepted exceptions

- Body text #8A8A8E on #F4F1EA = 3.2:1, below WCAG AA 4.5:1. Accepted 2026-08-12:
  brand grey is fixed by the parent identity. Do not re-raise.
```

Then **do not raise it again** — not in `design`, not in `review`, not in a QA pass.
`review` reports it once as an accepted exception with its date, never as a new
finding.

When the user chooses **[1] apply the fix**, update the profile itself, so the
corrected value becomes the ground truth rather than a per-build patch that decays.

## The default when there is no answer

If the user does not respond — a headless or scripted run — **follow the profile and
report the conflict in the output.** The user's stated intent outranks your judgement
of it, and an unattended run is not consent to redesign their brand. Say plainly that
it shipped as specified with an open accessibility finding, so the decision is
deferred rather than silently resolved.

The one exception: **never ship a state that cannot be perceived at all** — text at
or below 1.5:1 against its background, or a control with no visible focus path. That
is not a brand choice being overridden, it is content that does not exist for some
users. Ship the smallest fix, and say prominently that you overrode the profile and why.
