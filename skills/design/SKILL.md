---
name: design
description: Use when building or reshaping UI in Figma, creating screens or components, or when the user asks for a design, layout, or interface in a project that has a taste profile.
---

# Design

Composes UI in Figma from the project's registry and taste profile, checks its own
output, and only then shows the result.

## Locating standards

A standard named without a path sits beside this SKILL.md — read it directly.
A standard named `<skill>/<FILE>` belongs to a sibling skill: look beside this
SKILL.md first, then in that sibling skill's own directory (for example
`../design/RUBRIC.md` under a full plugin install, or wherever the harness
installed that skill). A single-skill install ships only this directory, so a
sibling standard may be absent — when that happens, say so once, apply the
rule stated inline in this skill, and continue. Never fail, and never
silently skip a check while implying it ran.

## Preconditions

1. Run `bash scripts/preflight.sh`. Stop on hard failure. **Without `scripts/`**
   (a single-skill install), run its checks directly: `figma-cli --version` and
   `figma-cli status` (hard — stop if either fails), whether
   `~/.claude/skills/emil-design-eng` or `~/.agents/skills/emil-design-eng`
   exists (soft), and whether `playwright` and `figma-use` resolve via `npm root
   -g` (soft — both are optional dependencies).
2. Read `.claude/design/TASTE.md`. **If it does not exist, refuse** and direct the
   user to `/claude-design:taste`. Grounding is mandatory — building without it
   produces exactly the untethered output this plugin exists to prevent.
3. Read `.claude/design/registry.md`. If empty, warn that output will be generated
   rather than composed, then proceed.
4. Read `FIGMA-CLI.md` for the JSX dialect before writing any JSX.

## Loop

### 1. Load
`TASTE.md` and `registry.md`. Work from handles, not node trees.

### 2. Plan
Do this in thinking, not in output — it is cheap to discard. Produce a compact
plan: the tokens this screen uses, an ASCII wireframe, and the signature element
from `TASTE.md`.

Review the plan against `SLOP.md` before building. If any part reads as the
generic default you would produce for any similar brief, revise it and say what
you changed and why.

### 3. Reuse before building
For every element, check the registry first:

```bash
figma-cli spec "<ComponentName>"        # does a handle exist?
figma-cli instantiate "<ComponentName>" # if yes, use it
```

**Never rebuild what exists.** Composing by handle costs a fraction of emitting
geometry, and keeps the component tree linked.

### 4. Build
```bash
figma-cli render-batch '["<Frame>…</Frame>","<Frame>…</Frame>"]' --verify
```

`--verify` returns a screenshot in the same call, so seeing the result costs no
extra round trip. Bind every color to a token: `bg="var:surface"`, never `bg="#fff"`.
Resolve real variable names with `figma-cli var list` before writing a `var:`
reference — `export css`'s hyphenated names (`--neutral-900`) are not valid
`var:` targets; the slash form (`var:neutral/900`) is, per `FIGMA-CLI.md`.

Use `<Icon name="prefix:name">` with the set from `TASTE.md`, or `<SVG>` for an
unhosted set. Never hand-draw paths.

### 5. Gate — deterministic, before any model critique
```bash
bash scripts/gates.sh <nodeId> "<ComponentName>"
```

This runs `lint --fix`, `spec --check`, and `a11y audit`. All are free and exact.
**A `spec --check` failure is a hard stop, not a finding** — the build is off-spec;
fix it before critique is worth running. **Without `scripts/`**, run the same
three `figma-cli` calls directly in that order — nothing in `gates.sh` beyond
composing them.

**An unresolved-variable warning from `render` is a build failure, not a
cosmetic warning.** It is free to detect from the command's own output, so
fix it before the QA pass — never let it reach the QA model or the user.

Running the model before this gate would pay Sonnet to find what `lint` finds free.

### 6. QA — dispatch a sub-agent
Dispatch per `RUNTIMES.md` using
`qa-brief.md` as the brief. Model: **sonnet**. The screenshot and
standards load in the sub-agent's context; only findings return here. Do not read
the screenshot into this context.

### 7. Fix and re-verify
Apply the findings, re-render, re-gate. **Maximum 3 QA passes.** Escalate to opus
when `RUBRIC.md`'s condition is met (the same dimension ≤ 2 twice). On exit after
3 passes, report remaining findings rather than looping silently.

### 8. Show
Only now present the result. The user sees post-QA work.

## On failure

- Figma unreachable → stop with instructions; never proceed blind.
- Bad build → `figma-cli undo`.
- `--verify` returned no screenshot → try `figma-cli verify <nodeId>`; if that also
  fails, say plainly that the visual QA pass could not run.
- Sub-agent failed → surface it. Never silently skip QA.
