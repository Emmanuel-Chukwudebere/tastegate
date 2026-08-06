# Runtime: Claude Code

Skills in this plugin request capabilities rather than naming tools. This file
resolves them for Claude Code.

| Capability requested | Claude Code tool |
|---|---|
| Dispatch a sub-agent | `Agent` tool, `subagent_type: "general-purpose"` |
| Read an image | `Read` tool with the PNG path |
| Run a command | `Bash` tool |
| Write a file | `Write` / `Edit` |
| Drive a browser | Playwright MCP (`browser_navigate`, `browser_evaluate`, `browser_hover`, `browser_click`, `browser_take_screenshot`) |
| Track multi-step work | `TaskCreate` / `TaskUpdate` |

## QA sub-agent dispatch

Dispatch with `model: "sonnet"` for the QA pass. Escalate to `model: "opus"` when
`RUBRIC.md`'s escalation condition is met (any dimension ≤ 2 on two consecutive
passes).

The sub-agent brief must include: the screenshot path, the relevant standards
file paths, and `TASTE.md`. Screenshots and standards load in the sub-agent's
context; only findings return to the main session. This is the cost mechanism —
do not read screenshots into the main context.

## Degrade

Claude Code supports sub-agent dispatch and image reading natively, so this
runtime does not need to degrade. Both the visual QA pass and the pixel diff run
in full.

If a Playwright MCP call fails, the pixel diff is the only thing lost: emit the
code and state plainly that visual verification did not run. Never assert
fidelity that was not measured.

## Parallel dispatch

For `/explore`, send multiple `Agent` calls in a single message so directions
generate concurrently rather than in sequence.
