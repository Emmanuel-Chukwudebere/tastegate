# Interview Mode

Use when the user has no references prepared. Ask one question at a time; prefer
concrete options over open prompts. Record answers directly into `TASTE.md`.

## Questions

1. **Subject and audience.** What is this product, who uses it, and what is the
   single job of the page or screen? Distinctive choices come from the subject's
   own world — its materials, instruments, artifacts, vernacular.

2. **Reference by contrast.** Name two products whose look you admire and one you
   dislike. What specifically is wrong with the one you dislike? Dislikes are
   often more precise than likes, and they populate the never list.

3. **Typography temperament.** Which reads right: geometric and neutral;
   editorial with a characterful serif; technical and monospaced; humanist and
   warm? Is there a typeface you already own or want to use?

4. **Density.** Airy with generous whitespace, or dense and information-rich?
   A dashboard and a landing page sit at opposite ends.

5. **Color temperament.** Dark or light foundation? One dominant color with a
   sharp accent, or a broader palette? Any brand colors that are fixed?

6. **Motion appetite.** Which is closest: near-zero motion, productivity-tool
   restraint (Linear, Raycast); considered polish at moments that matter; or
   expressive and playful? Note that keyboard-initiated actions never animate
   regardless of the answer. Translate a vague description ("bouncy", "snappy",
   "the iOS rubber-band thing") into its exact term and curve with Emil's
   `animation-vocabulary` skill before recording it. If the answer calls for a
   native, gesture-driven feel — direct manipulation, velocity handoff,
   translucent materials — invoke `apple-design` and record that stance in
   `TASTE.md` so `/ship` builds toward it later.

7. **Icon set.** Do you have one? (See `intake.md` for resolution — Iconsax needs
   a local source or the file's own icon sheet — there is no `<SVG>` element.)

8. **Breakpoints.** Which widths must this hold at? Default 390 / 834 / 1440.

9. **Signature.** What is the one element this design should be remembered by?

10. **The never list.** What must never appear? Record it verbatim — this becomes
    an enforced constraint, not a preference.

## After the interview

Write `TASTE.md` with every field filled. Mark all values as **inferred from
interview** rather than measured. Then state plainly that adding real references
later via `/claude-design:taste` will sharpen the profile.
