---
name: explore
description: Use when the design direction is not settled, when the user wants options or alternatives before committing, at the start of a new project or screen, or when they ask to see different approaches.
---

# Explore

Generates three genuinely different directions as real Figma frames, so the
direction is chosen by looking rather than by describing. This front-loads taste
alignment and replaces the long correction thread that otherwise dominates cost.

## Preconditions

Read `.claude/design/TASTE.md` if it exists — explorations stay inside the never
list even while diverging on everything else. If it does not exist, explore
anyway; the outcome will seed the profile.

## Process

### 1. Define three directions
Each needs its own token set, type pairing, and signature element. They must
differ in *approach*, not in accent color.

Check each against `skills/design/SLOP.md` **before building**. If two directions
would land on the same AI-default cluster, replace one. Three variations on a
default is not an exploration.

### 2. Build in parallel
Dispatch one sub-agent per direction, **all in a single message** so they run
concurrently (see `skills/design/RUNTIMES.md`). Each builds its frame:

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
