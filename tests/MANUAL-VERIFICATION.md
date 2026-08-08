# Live end-to-end verification

Recorded against a real Figma design system: file **Spry**, 3 variable
collections (`Primitives` 44 vars, `Semantic - Light` 42, `Semantic - Dark` 42),
`figma-ds-cli` v2.1.0, daemon on port 3456.

Canvas state was captured before any write (3 elements) and confirmed restored to
3 elements afterward. The user's file was not altered.

Cases requiring the full `/design` and `/ship` agent loops are marked NOT RUN with
the reason. Nothing below is claimed as verified unless its actual output is
recorded.

---

## Case: `render --verify` returns a screenshot in one call — PASS

The plugin's "sight" mechanism, and the basis of the visual QA pass.

Command:

```
figma-cli render '<Frame flex="col" p={24} gap={16} bg="var:neutral/900" rounded={16} w={360} name="claude-design-smoketest2"><Text size={24} weight="bold" color="var:neutral/white">Smoke test</Text><Text size={14} color="var:neutral/300">Slash-form token references.</Text></Frame>' --verify -c Primitives
```

Output:

```
✓ Rendered: 334:5467
  name: claude-design-smoketest2
{"verify":{"id":"334:5467","name":"claude-design-smoketest2","width":360,"height":110,"saved":"C:\\Users\\imman\\AppData\\Local\\Temp\\figma-verify-334-5467.png"}}
```

Reading that PNG showed a dark card, white bold heading, muted subtext — bound to
Spry's real tokens. Build and screenshot in a single call, no extra round trip.

## Case: the visual pass catches what text output only warns about — PASS

**The most valuable result of the whole exercise.** An earlier render used the
hyphenated names taken from `export css`:

```
figma-cli render '<Frame ... bg="var:neutral-900"><Text color="var:neutral-white">Smoke test</Text>...' --verify
```

Output — note it reports success and exits 0:

```
✓ Rendered: 334:5464
⚠ 3 variable reference(s) could not be resolved:
  neutral-300, neutral-900, neutral-white
  These bindings rendered as grey placeholders.
```

Reading the screenshot showed a featureless grey box with no visible text. The
text output called this a success with a warning; the image showed a failed
design. This is the argument for the visual pass, demonstrated rather than
asserted.

Fixed in commit `53313ae` — see the token-form case below.

## Case: token export fidelity — PASS

`figma-cli export css` emitted Spry's real values verbatim:

```
:root {
  --neutral-950: #0a0a0b;
  --neutral-900: #141416;
  --neutral-850: #1d1d20;
  ...
  --blue-500: #2e6bff;
  --status-green-500: #1f9e6b;
```

No value passed through a language model. The token layer is generated, exactly
as the design claims.

## Case: slash-vs-hyphen token reference form — FIXED

Root cause of the grey-placeholder failure above.

- `var list` prints `neutral/900` (slash separator)
- `export css` flattens to `--neutral-900` (valid CSS custom property)
- a `var:` reference must use the **slash** form
- an unresolved `var:` **warns but still exits 0**, so it ships silently without a
  visual check

Verified both directions live: `var:neutral-900` warned and rendered grey;
`var:neutral/900 -c Primitives` resolved with no warnings and rendered correctly.

Documented in `skills/design/FIGMA-CLI.md`, made a build failure in
`skills/design/SKILL.md`, and reconciled across the code/Figma boundary in
`skills/ship/emit.md`. Commit `53313ae`.

## Case: `a11y contrast` runs live — PASS

```
figma-cli a11y contrast
```

Output:

```
  Contrast Check (WCAG AA)
  ✓ Pass: 15/19   ✗ Fail: 4/19

  Failing elements:
  ✗ Label - "Home"
    Ratio: 4.44:1 (need 4.5:1)  FG: #2e6bff  BG: #fdfdfe  Size: 12px
    ID: I323:1666;272:4565
```

Real findings on real content, with node ids — usable directly by the
deterministic gate.

## Case: optional dependencies missing — FIXED

Two documented commands failed on this machine for missing optional
dependencies, and `preflight.sh` checked for neither.

`figma-cli analyze clusters --json`:

```
npm warn exec The following package was not found and will be installed: figma-use@0.13.5
Error: spawnSync C:\Windows\system32\cmd.exe ETIMEDOUT
```

`figma-cli analyze-url "https://linear.app" -w 390`:

```
- Analyzing https://linear.app with Playwright...
Error: Cannot find module 'playwright'
```

Affected: `analyze-url`, `screenshot-url`, `recreate-url` (need `playwright`);
`analyze` subcommands and `node` operations (need `figma-use`).

Preflight now reports both without failing the run, and the documents that build
on them state the dependency and the honest fallback — record values as
**inferred**, never present estimates as measured. Commit `6a220cd`.

Current preflight output:

```
PREFLIGHT: figma-cli OK (2.1.0)
PREFLIGHT: figma-desktop OK
PREFLIGHT: emil-skills OK
PREFLIGHT: playwright ABSENT - analyze-url, screenshot-url, and recreate-url will fail.
PREFLIGHT: playwright install with: npm i -g playwright
PREFLIGHT: figma-use ABSENT - analyze (clusters, colors, typography, spacing) and node (tree, bindings, to-component) will fail.
PREFLIGHT: figma-use install with: npm i -g figma-use
exit=0
```

Exit 0 is correct: both are optional, so canvas-only work is unaffected.

## Case: `undo` restores the canvas — PASS

```
figma-cli undo
✓ Removed 1 node(s) from the last render:
  claude-design-smoketest2
```

`undo` removes only the last render's nodes, so the earlier test frame needed
`figma-cli delete 334:5464`. `canvas info` then reported 3 elements, matching the
pre-test capture.

Worth knowing operationally: after several renders, `undo` alone will not clean
up everything.

## Case: registry generation via `analyze clusters` — NOT RUN

Blocked by the missing `figma-use` dependency above. The fallback is documented:
build the registry from `extract --sections components` alone and report the
cluster health check as not run rather than passed.

## Case: responsive intake at 390 / 834 / 1440 — NOT RUN

Blocked by the missing `playwright` dependency above. Fallback documented in
`skills/taste/intake.md`: capture visually via Playwright MCP and record values as
inferred rather than measured.

## Cases requiring the full agent loop — NOT RUN

These need `/taste` to have produced a `TASTE.md` for a project and then a full
`/design`, `/explore`, `/ship`, or `/review` invocation. They are behavioural
rather than mechanical, so they are validated by using the plugin on real work,
not by a shell command:

- registry compliance (zero raw hex where a handle existed)
- motion rubric catching planted violations
- slop detection on an undirected brief
- taste adherence to a distinctive profile
- escalation firing after two consecutive low scores
- gates running before the QA dispatch
- pixel fidelity diff between built UI and Figma frame
- interaction-state completeness
- the mandatory Emil sequence order
- cost baseline with and without the plugin

The static suite covers the *instructions* for each of these — 218 checks across
10 suites, every anchored to the rule it guards and mutation-tested. What remains
unproven is the model's adherence to those instructions in a real session.

## Case: dual distribution install — NOT RUN

Requires the repo pushed to GitHub. Structure verified locally instead: all five
skills carry complete `name`/`description` frontmatter, there is no repo-root
`standards/` that the skills CLI would leave behind, and a simulated single-skill
copy confirmed each skill's standards travel with it (`design/` 8 files, `taste/`
4, `ship/` 4, `explore/` and `review/` 1 each — the last two relying on the
inline fallbacks added in commit `be04ec6`).
