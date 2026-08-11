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
`npx skills add`, they install unnamespaced (`/taste`). Both work.

The plugin also brings `scripts/`. `preflight.sh` and `gates.sh` only compose
`figma-cli` calls, and each skill documents that sequence inline — so a single-skill
install degrades cleanly. Two scripts have **no inline equivalent**, because the
commands they replace are broken rather than merely absent:

- **`lint-node.js`** — `figma-cli lint` cannot be scoped and times out on a large
  file. Never substitute it; see the Speed section.
- **`dtcg-to-css.js`** — `figma-cli export css` emits `#NaNNaNNaN` for aliased
  tokens.

Without `scripts/`, those two checks do not run, and the skill says so rather than
implying they passed.

## Updating

Installs do not track the repo — both paths copy the files, so pushing a change
does not reach an existing install.

**Skill bundle:**

```bash
npx skills@latest update            # all installed skills
npx skills@latest update design     # or one by name
```

**Plugin:** both commands, in this order, and the plugin name **must carry its
marketplace suffix**:

```bash
claude plugin marketplace update emmanuel-chukwudebere      # fetches the repo
claude plugin update claude-design@emmanuel-chukwudebere    # installs the new version
```

Then restart the session.

Three traps here, each of which silently leaves you on the old version:

- **`/reload-plugins` does not fetch.** It re-reads what is already on disk. The
  marketplace clone lives at
  `~/.claude/plugins/marketplaces/<name>/` and only moves when you run
  `marketplace update` — so reloading against a three-day-old clone reports the old
  version forever, with no error.
- **The bare name fails.** `claude plugin update claude-design` exits with
  `Plugin "claude-design" not found`. The installed key is
  `claude-design@emmanuel-chukwudebere`; use it.
- **Skipping the marketplace step is a silent no-op.** `plugin update` compares
  against the local clone, so without the fetch it correctly finds nothing to do.

To confirm which version is actually live:

```bash
ls ~/.claude/plugins/cache/emmanuel-chukwudebere/claude-design/
```

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

Deterministic work runs as tool calls, not token generation. `scripts/gates.sh`
checks lint, spec, accessibility, font bindings, and a non-blank export in ~7s
before any model critique — a model hunting what a gate finds free is the single
most expensive mistake in this pipeline. The QA pass runs in a sub-agent with a
tool-call budget and the reference image, so screenshots never enter the main
context. Three upfront explorations replace the long correction thread.

Measured savings from one live build: a blocking, reference-less audit of three
frames took 195 tool calls and 144 minutes; the same work overlapped, gated, and
handed the reference took 11 calls and 6.6 minutes.

## Speed

Three costs dominate, all of them silent. Each is now checked rather than assumed:

| Cost | Measured | Fix |
|---|---|---|
| Stale daemon token | **20.1s** per `eval`, vs 3.0s healthy | hard preflight check — `figma-cli status` still prints "Connected" |
| Unscoped `figma-cli lint` | **36–41s, then CDP timeout** on 57k nodes | `scripts/lint-node.js`, one subtree, ~2s |
| `export-jsx` | **timed out at 120s** | daemon-side tree dump, ~3s |

The daemon one is the trap: nothing reports it, so a whole session can run at 6.6×
cost with no error anywhere. Check `figma-cli daemon status`, and after a restart
re-time a call — the error message stops before the speed comes back.

Two more that exit 0 and look like success: `figma-cli run` returns **nothing** when
a script has leading `//` comments before the IIFE, and a node with `visible = false`
exports a **149-byte transparent PNG** with a `✓ Exported` message. Both are gated;
`skills/design/FIGMA-CLI.md` has the evidence.

`figma-cli export css` cannot resolve variable aliases and emits `#NaNNaNNaN` for
every semantic token. Use `export dtcg` plus `scripts/dtcg-to-css.js`, which
converts each alias to a `var()` reference so theming survives into CSS.

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
