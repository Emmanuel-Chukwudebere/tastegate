---
name: review
description: Use when the user asks for design feedback, a design review, or an audit of existing UI, when they ask why something feels wrong or unpolished, or before shipping a design or component.
---

# Review

Scores existing work against the standards and reports. **Read-only** — it emits
findings and a plan, and changes no files.

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

For code, invoke `improve-animations` for a repo-wide motion audit with
prioritized plans.

### 2. Capture
Figma: `figma-cli verify <nodeId>` for a screenshot.
Code: run it and screenshot with Playwright at each width in `TASTE.md`.

### 3. Score
Dispatch a sub-agent (model **sonnet**) with the brief in
`skills/design/qa-brief.md`, scoring all 8 dimensions from
`skills/design/RUBRIC.md`.

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
