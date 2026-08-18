---
name: explore
description: Use when the design direction is not settled, when the user wants options or alternatives before committing, at the start of a new project or screen, or when they ask to see different approaches.
license: MIT
metadata:
  author: Emmanuel Chukwudebere
  homepage: https://github.com/Emmanuel-Chukwudebere/tastegate
---

# Explore

Generates three genuinely different directions as real Figma frames, so the
direction is chosen by looking rather than by describing. This front-loads taste
alignment and replaces the long correction thread that otherwise dominates cost.

## Locating standards

A standard named `<skill>/<FILE>` (for example `design/SLOP.md`) belongs to a
sibling skill: look beside this SKILL.md first, then in `design/`'s own
directory (`../design/SLOP.md` under a full plugin install, or wherever the
harness installed that skill). This skill ships alone under a single-skill
install, so `design/SLOP.md` and `design/RUNTIMES.md` may be absent. **If
absent, say so once, then fall back to the compact rule below and continue —
never fail, and never silently skip the check while implying it ran.** The
sibling file is authoritative whenever it is present; treat the summary below
only as this skill's own fallback rule.

**Inline fallback for `design/SLOP.md`** — reject the AI-default clusters:
warm cream (near `#F4F1EA`) paired with serif display and terracotta; near-black
with a single acid-green or vermilion accent; broadsheet (hairline rules, zero
radius, dense columns); and purple gradient on white.

## Preconditions

Read `.claude/design/TASTE.md` if it exists — explorations stay inside the never
list even while diverging on everything else. If it does not exist, explore
anyway; the outcome will seed the profile.

## Process

### 1. Define three directions
Each needs its own token set, type pairing, and signature element. They must
differ in *approach*, not in accent color.

Check each against `design/SLOP.md` **before building**. If two directions
would land on the same AI-default cluster, replace one. Three variations on a
default is not an exploration.

### 2. Build in parallel
Dispatch one sub-agent per direction, **all in a single message** so they run
concurrently (see `design/RUNTIMES.md`). Each builds its frame:

```bash
figma-cli render-batch '[…]' --verify
```

Position them side by side so they can be compared at a glance.

### 3. Present
Show all three with a one-line rationale each — what it commits to, and what it
gives up. State your recommendation and why.

### 4. Lock the winner
Once the user picks, write that direction into `.claude/design/TASTE.md` as the
**locked direction** for the project: its palette, type pairing, and signature
element become the profile's defaults.

## Interactive variants

For exploring behaviour rather than looks, invoke Emil's `prototype` skill —
it builds several genuinely different interactive versions with a live switcher,
which answers state-model questions that static frames cannot.
