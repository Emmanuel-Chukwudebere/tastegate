---
name: claude-design
description: Use as the single entry point for any design work — the router that decides which pipeline stages a request needs and runs them in order. Use when the user asks to design, build, redesign, or ship a screen or component and has not named a stage, when they say "design this" or "build this in Figma" or "make this real", or when they want the whole path from reference to code.
license: MIT
metadata:
  author: Emmanuel Chukwudebere
  homepage: https://github.com/Emmanuel-Chukwudebere/claude-design
---

# claude-design

One entry point for the whole pipeline. Reads the request, decides which stages it
needs, runs them in the right order, and carries state between them.

Use this when the stage is not obvious. Call a stage directly when it is —
`/claude-design:review` on an existing screen needs no router.

## The stages

| Stage | Owns | Produces |
|---|---|---|
| `taste` | what "good" means here | `.claude/design/TASTE.md`, `registry.md` |
| `explore` | direction, when unsettled | 3 parallel directions, one chosen |
| `design` | building in Figma | gated, self-checked frames |
| `ship` | Figma → code | components with states and motion |
| `review` | scoring existing work | 8-dimension audit |

## Routing

Read the request, then answer three questions in order.
**Do not ask the user which stage they want** — that is what this skill exists to decide.

**1. Does `.claude/design/TASTE.md` exist?**

No → run `taste` first, always. Every other stage depends on it, and skipping it
produces exactly the untethered output this plugin exists to prevent.
**Do not ask permission; grounding is not optional.** Say one line about why, then run it.

Yes → read it. If the request contradicts it (a light hero when the profile is
dark-only), surface the conflict before building — the profile is not automatically
right, but the divergence must be deliberate.

Two kinds of conflict, handled differently. **Request vs. profile** is the one above:
name the divergence and confirm which wins. **Profile vs. usability** — where
`TASTE.md` itself crosses a measurable threshold — is `design/CONFLICT.md`: raise the
measured value, the threshold, and the smallest brand-preserving fix, then let the
user decide. Neither is a licence to override the profile on taste. If you cannot
name a threshold and a number, the profile wins.

**2. Is the direction settled?**

A reference image, a URL, or an explicit description settles it → skip `explore`.

"Something like…", "some options", a new product surface with no reference → run
`explore` first. Three directions in parallel cost less than one long correction
thread.

**3. What is the endpoint?**

| The request says | Stages |
|---|---|
| "design this", "build this in Figma", "mock this up" | → `design` |
| "build this for real", "in React", "make it work" | → `design` → `ship` |
| "convert this Figma frame", pointing at existing frames | → `ship` |
| "what's wrong with this", "review", "why does it feel off" | → `review` |
| "redesign this" | → `review` → `design` |

When the endpoint is code, run `design` first even if the user only said "build it in
React" — a gated Figma frame is the input `ship` measures against, and skipping it
means shipping code with nothing to verify fidelity against.

## Carrying state between stages

Each stage's output is the next stage's input. Hand it over explicitly rather than
letting the next stage rediscover it:

- `taste` → everything: the profile path, and **the reference captures**. `design`'s
  QA pass compares images against the direction, so a discarded reference forces it
  back to rule-checking.
- `explore` → `design`: the winning direction's node id, as the reference image.
- `design` → `ship`: the frame node id, the gate output, and the residual deltas the
  build stopped at. `ship` should not re-derive geometry a gate already measured.
- any stage → `review`: the standards are the same eight dimensions throughout.

## Before the first stage

Run `bash scripts/preflight.sh` once, here, rather than in every stage. It is the
same check, and one failure should stop the pipeline rather than each stage
rediscovering it.

**Check `figma-cli daemon status` specifically.** A stale token makes every `eval`
and `run` cost ~20s instead of ~3s, and `figma-cli status` reports `Connected`
regardless — so a whole pipeline can run at 6.6× cost with no error anywhere. If it
reports a token mismatch, `figma-cli daemon restart`, then re-time one call to
confirm the fix landed; the error message stops before the speed returns.

## Speed

The pipeline's cost is dominated by round-trips, not by generation. Three rules:

1. **Gate before critique.** Deterministic checks are free and exact; a model hunting
   what `lint` finds is neither. `scripts/gates.sh <nodeId>` runs all four in ~7s.
2. **Overlap the audit.** Dispatch QA in the background and keep building. Wall-clock
   becomes the slowest single audit, not the sum. Every audit in this pipeline is a
   **dispatched sub-agent**, never an inline pass: `design` step 6, `ship` step 4 (per
   component, as it lands) and step 8, `review` step 3, and one agent per direction in
   `explore`. Two reasons, and the second matters more — screenshots stay out of this
   context, and a fresh context reviews code the way a reader will, rather than
   re-reading the reasoning that produced it. Give every one a tool-call budget and the
   gate's findings as established fact.
3. **Stop at the tolerance.** ±8pt position, ±3pt cap-height is converged. A
   measurement always returns something; without a stated band the loop never ends.
   One hero spent ~20 measure-adjust-export rounds closing invisible deltas.
4. **Compare ink to ink, never box to box.** Figma `node.y` and CSS
   `getBoundingClientRect().top` are different reference lines, so part of that
   ~20-round chase was an artifact no correction could close. See
   `design/TEXT-GEOMETRY.md` — and prevent it by setting an explicit pixel
   line-height on both sides.

## Reporting

Say which stages you are running and why, in one line, before starting. Then run them
without stopping to ask between stages — the routing decision is already made.

At the end, report per stage: what it produced, what it measured, and what it left
open. A stage that could not run (no dev server for the pixel diff, Playwright
absent) must say so plainly rather than being silently dropped.
