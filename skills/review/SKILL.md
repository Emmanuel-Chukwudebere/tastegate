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
an exact fix, never "improve the spacing." Escalate to opus when the same
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
Code: run it and screenshot with Playwright at each width in `TASTE.md`. **If
`.claude/design/TASTE.md` does not exist, say so once and proceed with the
default widths 390 / 834 / 1440 rather than failing or silently skipping the
breakpoint dimension.**

### 3. Score
Dispatch a sub-agent (model **sonnet**) per `design/RUNTIMES.md`, with the brief in
`design/qa-brief.md`, scoring all 8 dimensions from `design/RUBRIC.md`.

Escalate that pass to **opus** when the same dimension scores ≤ 2 on two
consecutive passes, and say that you escalated and why.

The brief carries four things, and the pass degrades badly without them:

1. **The step-1 output as established fact.** `lint`, `a11y audit`, and cluster
   findings are already measured — free and exact. An audit told to score eight
   dimensions with no facts goes measuring instead of judging: one such pass spent
   **195 tool calls** re-deriving what the gate had handed it.
2. **A tool-call budget**, with instructions to report what it has when spent. An
   uncapped audit surfaces ever-smaller findings until it exhausts its context.
3. **The reference**, where one exists — the site capture, moodboard, or the
   `TASTE.md` direction. Without it the pass can only check rules; with it, it can
   say the work missed the direction, which is the finding that matters most.
4. **`## Accepted exceptions` from `TASTE.md`**, so a settled decision is not
   re-litigated as a fresh finding.

**Dispatch one sub-agent per breakpoint, all in a single message**, so the widths audit
concurrently rather than in sequence. Screenshots load in each sub-agent; **never read
them into this context** — that is the cost mechanism, and a three-breakpoint blocking
audit measured 144 minutes against a fraction of that overlapped.

**Without sub-agent support**, run the pass inline and say so once. The rubric produces
the quality; isolation produces the cost saving.

### 4. Motion specifically
Invoke `review-animations` on the code diff or implementation. Its posture is
adversarial by design: approval is earned.

### 5. Report
Order findings by severity. Each carries evidence and an exact fix. Close with a
prioritized implementation plan the user or another agent can execute.

**Where `TASTE.md` itself is the cause of a threshold failure**, report it per
`design/CONFLICT.md` — measured value, threshold crossed, smallest brand-preserving
fix — rather than either passing it because it was specified or presenting a redesign.
Skip anything under `## Accepted exceptions` in `TASTE.md`: list it once as an
accepted exception with its date, never as a new finding. And hold the line on the
other side too — a design that diverges from convention because the profile says so
is not a finding at all.

Never apply fixes from this skill. If the user wants them applied, that is
`/claude-design:design` or `/claude-design:ship`.
