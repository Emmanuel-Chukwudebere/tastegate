# claude-design

A design pipeline for Claude Code that grounds UI work in your taste, checks its
own output before showing it, and ships pixel-perfect code.

It reproduces the three mechanisms behind Anthropic's hosted Claude Design
product — component grounding, a closed-loop self-check, and parallel
explorations — locally, and adds motion, typography, and accessibility standards
that product does not enforce. It works with 3rd-party login on Claude Code, where the hosted
`/design-sync` path is unavailable.

## Requirements

```bash
npm i -g figma-ds-cli                        # Figma control, no API key
npx skills@latest add emilkowalski/skills    # motion + interaction layer (MIT)
```

Plus Figma Desktop, and Playwright MCP for the pixel-diff and motion extraction.

Emil's skills are optional but recommended. Without them, `skills/design/MOTION.md`
still enforces the motion rules; with them, they are authoritative.

## Install

Three ways, same repo.

**As a skill bundle** — works in Claude Code, Codex, Cursor, Antigravity, and any
agent the `skills` CLI supports:

```bash
npx skills@latest add emmanuel-chukwudebere/claude-design
```

Add one skill only, if you prefer:

```bash
npx skills@latest use emmanuel-chukwudebere/claude-design/skills/taste
```

**As a Claude Code plugin, from the marketplace** — namespaced skills plus the
helper scripts:

```bash
claude plugin marketplace add Emmanuel-Chukwudebere/claude-design
claude plugin install claude-design@emmanuel-chukwudebere
```

**As a Claude Code plugin, from a local checkout** — for development:

```bash
claude --plugin-dir /path/to/claude-design
```

Then `/reload-plugins` after edits.

Under the plugin, skills are namespaced (`/claude-design:taste`). Under
`npx skills add`, they install unnamespaced (`/taste`). Both work; the plugin also
brings `scripts/`, though every script has an inline equivalent documented in the
skill that uses it, so nothing depends on them.

## Updating

Installs do not track the repo — both paths copy the files, so pushing a change
does not reach an existing install.

**Skill bundle:**

```bash
npx skills@latest update            # all installed skills
npx skills@latest update design     # or one by name
```

**Plugin:**

```bash
claude plugin marketplace update emmanuel-chukwudebere
claude plugin update claude-design
```

Then `/reload-plugins`, or restart the session.

**If you publish changes, bump `version` in `.claude-plugin/plugin.json`.** Users
only receive plugin updates when that field changes; leave it alone and
`plugin update` finds nothing to do even though the repo moved. (Omit `version`
entirely and the commit SHA is used instead, making every commit an update — fine
for a fast-moving fork, noisy for a published plugin.)

**Developing?** Skip both. `claude --plugin-dir /path/to/claude-design` reads the
working tree directly, so `/reload-plugins` picks up an edit with no version bump
and no reinstall.

## Use

| Command | When |
|---|---|
| **`/claude-design`** | **Don't know which stage? Start here.** Routes the request and runs the stages in order |
| `/claude-design:taste` | First, in any new project. Builds the taste profile |
| `/claude-design:explore` | Direction not settled — three real options |
| `/claude-design:design` | Build UI in Figma, self-checked before you see it |
| `/claude-design:ship` | Figma → code, framework of your choice |
| `/claude-design:review` | Scored audit of existing design or code |

The router decides which stages a request needs — it runs `taste` when no profile
exists, `explore` when the direction is unsettled, and `design` before `ship` so the
code has a gated frame to measure against. Call a stage directly when you already
know which one you want.

Every stage refuses or warns without a taste profile, by design — grounding is the
whole thesis.

## How taste is stored

Universal craft standards ship inside the skills that use them. Your taste is
per-project, generated into the consuming project:

```
<your project>/.claude/design/
├── TASTE.md      palette, type, spacing, icons, motion, breakpoints, never list
└── registry.md   component handles + bound tokens
```

So a fintech dashboard and a children's app never share a profile.

## Why it costs less

Deterministic work runs as tool calls, not token generation: `figma-cli lint --fix`
and `spec --check` gate the build before any model critique; `export css` and
`export-jsx` emit tokens and structure exactly and free. The QA pass runs in a
sub-agent, so screenshots never enter the main context. And three upfront
explorations replace the long correction thread.

## Runtimes

Claude Code is the primary target. `skills/design/RUNTIMES.md` maps the two
harness-coupled actions — sub-agent dispatch and image reading — for Codex,
Antigravity, and Grok. Where a runtime lacks either, the pipeline degrades and
says so rather than asserting unverified results.

## License

MIT. Emil Kowalski's skills are MIT and separately installed.

## Verify

```bash
bash tests/run-all.sh        # every suite
claude plugin validate .     # manifest and structure
```
