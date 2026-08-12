# UX Laws

The 30 principles at [lawsofux.com](https://lawsofux.com/) (Jon Yablonski, CC BY-NC-SA
4.0). They give `CONFLICT.md` a citable basis: a named law and a measured number beats
"this feels wrong", and a user can disagree with a citation in a way they cannot
disagree with taste.

**Most of these are not thresholds, and using them as gates is a misuse.** Sort them
before applying them.

## The split that matters

| Kind | What it licenses |
|---|---|
| **Quantified** — a number in the law itself | A gate. Cite it in a conflict per `CONFLICT.md`. |
| **Directional** — a real effect, no number | Reasoning in a critique. Never a pass/fail. |

Miller's Law states the trap outright — takeaway 1 is
**"Don't use the 'magical number seven' to justify unnecessary design limitations."**
A law invoked to justify a constraint the law does not actually impose is worse than not
citing it: it launders a preference as a standard.
If you cannot quote the law's own number, you are reasoning, not gating.

## Quantified — usable as thresholds

**Doherty Threshold — feedback within 400ms.** "Productivity soars when a computer and
its users interact at a pace (<400ms) that ensures that neither has to wait on the
other." Applies to system *feedback*, not to animation duration. A control that
acknowledges input in under 400ms satisfies it; a 400ms transition does not — that
fails `MOTION.md`'s 300ms limit for a different reason. Do not conflate them.

The law also notes the inverse: "purposefully adding a delay to a process can actually
increase its perceived value and instill a sense of trust."
A deliberate delay is a design decision, not a defect — do not flag one that `TASTE.md` asks for.

**Miller's Law — 7±2 items in working memory.** Cite it for *chunking* content, which
is takeaway 2, never for capping menu items or form fields, which takeaway 1 forbids.
Capacity "will vary per individual, based on their prior knowledge and situational
context", so it is not a hard cap on anything an interface displays.

## Directional — reasoning, never gates

Where a numeric threshold exists for one of these, **it comes from WCAG or platform
guidance, not from the law.** Cite the real source.

**Fitts's Law** — "the time to acquire a target is a function of distance to and size
of the target." Its takeaways are "large enough", "ample spacing", "easily acquired" —
**no numbers at all.** So the 24×24 minimum in `RUBRIC.md` is **WCAG 2.5.8 Target Size
(Minimum)**, and 44×44 is Apple's HIG. Cite those for the gate and Fitts's Law for the
*reason*. Attributing a pixel value to Fitts's Law is a fabricated citation.

**Hick's Law** — decision time grows with the number and complexity of choices. Good
for arguing a simplification; there is no threshold count.

**Jakob's Law** — "users prefer sites to work similarly to other sites they already
know", and will transfer expectations from a product that merely *looks* similar. The
useful half is the cost model: **deviating from convention is not wrong, it is
expensive**, and the expense is paid in relearning. So a novel pattern needs to buy
something. This is the closest thing here to a real argument against an unconventional
brand choice — and it is still an argument, not a gate. The profile can decide the
novelty is worth its cost.

**Aesthetic-Usability Effect** — the one that justifies this whole mechanism, and
worth quoting in full: "Visually pleasing design can mask usability problems and
prevent issues from being discovered during usability testing." People are "more
tolerant of minor usability issues when the design is aesthetically pleasing."

This is why a beautiful build is not self-validating, and why the deterministic gates
run before any visual critique. A model looking at an attractive screenshot is subject
to the same effect — it will rate a handsome frame as more usable than it is.
**The gate is not there because measurement is more rigorous; it is there because looking is biased in a known direction.**

**The Gestalt group** — Proximity, Common Region, Similarity, Uniform Connectedness,
Prägnanz. These explain *why* a spacing or grouping finding is real: elements grouped
by proximity read as related whether or not they are. Cite one when explaining a
grouping defect, which makes the finding concrete rather than stylistic.

**The rest** — Aesthetic-Usability's siblings in the cognitive-bias set (Peak-End Rule,
Serial Position Effect, Von Restorff Effect, Zeigarnik, Goal-Gradient, Choice Overload,
Selective Attention, Flow, Mental Model, Chunking, Cognitive Load, Working Memory,
Paradox of the Active User, Pareto, Parkinson's, Postel's, Occam's Razor, Tesler's
Law). Real and useful for reasoning. None carries a number. Tesler's Law is worth
remembering when tempted to simplify: "every system has inherent complexity that cannot
be reduced" — only moved, usually onto the user.

## How to cite one in a finding

A law strengthens the *why*; it does not supply the threshold unless it is quantified:

```
Hierarchy 2/5 — the CTA and the secondary link have equal weight, 8px apart.
WHY: Law of Proximity — at 8px they read as one group, so the eye finds no
primary action. The signature element in TASTE.md is the CTA, so this
inverts the intended focal order.
FIX: gap 8 → 24 (on scale), secondary link to 15pt regular.
```

Never cite a law for a value it does not contain. Never cite one to override
`TASTE.md` on taste — the profile wins every aesthetic disagreement, and a law used as
cover for a preference is the failure mode this file exists to prevent.

## What this does not license

These are not a rubric dimension and not a checklist. Do not score against them, do
not enumerate them in a report, and do not raise a "Jakob's Law violation" because a
design is unfamiliar to you. `RUBRIC.md`'s eight dimensions remain the scoring
instrument; the laws are the vocabulary for explaining a finding it already produced.
