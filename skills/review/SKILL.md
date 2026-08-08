---
name: review
description: Use when the user asks for design feedback, a design review, or an audit of existing UI, when they ask why something feels wrong or unpolished, or before shipping a design or component.
---

# Review

Scores existing work against the standards and reports. **Read-only** — it emits
findings and a plan, and changes no files.

## Locating standards

A standard named `<skill>/<FILE>` (for example `design/RUBRIC.md`) belongs to a
sibling skill: look beside this SKILL.md first, then in `design/`'s own
directory (`../design/RUBRIC.md` under a full plugin install, or wherever the
harness installed that skill). This skill ships alone under a single-skill
install, so `design/qa-brief.md` and `design/RUBRIC.md` may be absent. **If
absent, say so once, then fall back to the compact rule below and continue —
never fail, and never silently skip the check while implying it ran.** The
sibling file is authoritative whenever it is present; treat the summary below
only as this skill's own fallback rule.

**Inline fallback for `design/RUBRIC.md`** — score all eight dimensions
(Typography, Palette, Spacing, Hierarchy, Motion, Accessibility, Slop,
Breakpoint behaviour) on a 0-5 scale, each finding carrying cited evidence and
an exact fix, never "improve the spacing." Escalate to opus when any
dimension scores ≤ 2 on two consecutive passes.

## Scope

Works against either Figma frames or a code implementation.

## Process

### 1. Deterministic first
Free and exact, so run these before any model pass:

```bash
figma-cli lint --json            # mechanical issues
figma-cli a11y audit             # contrast, touch targets, text, focus order
figma-cli analyze clusters --json # components that should exist but do not
```

`analyze clusters` requires `figma-use` (`npm i -g figma-use`); when it is
unavailable, report the cluster-detection health check as not run rather than
passed, rather than silently skipping it.

For code, invoke `improve-animations` for a repo-wide motion audit with
prioritized plans.

### 2. Capture
Figma: `figma-cli verify <nodeId>` for a screenshot.
Code: run it and screenshot with Playwright at each width in `TASTE.md`.

### 3. Score
Dispatch a sub-agent (model **sonnet**) with the brief in
`design/qa-brief.md`, scoring all 8 dimensions from
`design/RUBRIC.md`.

Escalate that pass to **opus** when any dimension scores ≤ 2 on two consecutive
passes, and say that you escalated and why.

### 4. Motion specifically
Invoke `review-animations` on the code diff or implementation. Its posture is
adversarial by design: approval is earned.

### 5. Report
Order findings by severity. Each carries evidence and an exact fix. Close with a
prioritized implementation plan the user or another agent can execute.

Never apply fixes from this skill. If the user wants them applied, that is
`/claude-design:design` or `/claude-design:ship`.
