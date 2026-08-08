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
`RUBRIC.md`'s escalation condition is met (the same dimension ≤ 2 on two
consecutive passes).

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

---

# Runtime: Codex

| Capability requested | Codex equivalent |
|---|---|
| Dispatch a sub-agent | `spawn_agent` / `wait_agent` / `close_agent` |
| Read an image | image input where supported |
| Run a command | shell tool |

## Enabling sub-agents

Sub-agent dispatch requires multi-agent support. Add to `~/.codex/config.toml`:

```toml
[features]
multi_agent = true
```

Without it, `spawn_agent` is unavailable.

## Degrade

If sub-agents are unavailable, run the QA pass **inline** in the main context.
More expensive, identical output — the rubric is what produces the quality, not
the isolation.

If image input is unavailable, skip the visual pass and **say so plainly**. Fall
back to `figma-cli lint`, `a11y audit`, and token-compliance checks, which need
no eyes. Never assert fidelity that was not measured.

---

# Runtime: Antigravity (`agy`)

| Capability requested | Antigravity equivalent |
|---|---|
| Dispatch a sub-agent | `invoke_subagent` — `TypeName: research` for read-only QA, `self` for full-capability work |
| Track multi-step work | a **task artifact**: `write_to_file` with `IsArtifact: true` and `ArtifactType: "task"` |
| Read an image | image input where supported |
| Run a command | shell tool |

## Task tracking

Antigravity has no todo tool — `manage_task` manages background processes, not a
checklist. When a skill asks for task tracking, maintain a markdown checklist as
a task artifact and edit it with `replace_file_content` as steps complete.

## QA dispatch

Use `TypeName: research` for the QA pass — it is read-only by nature, which
matches the pass exactly.

## Degrade

Same rules as every runtime: no sub-agents → run QA inline; no image input →
skip the visual pass and **say so plainly**, falling back to the deterministic
gates. Never claim unmeasured fidelity.

---

# Runtime: Grok (build mode)

Grok's tool surface varies by deployment, so **detect capabilities at runtime** rather than assuming them.

| Capability requested | Resolution |
|---|---|
| Dispatch a sub-agent | use the harness's sub-agent facility if present; otherwise inline |
| Read an image | use image input if present; otherwise skip the visual pass |
| Run a command | shell tool |

## Detection

Before the QA pass, establish whether sub-agent dispatch and image input exist.
If either is missing, take the degradation path below rather than failing.

## Degrade

- No sub-agents → run the QA pass **inline** in the main context. The rubric
  supplies the quality; isolation only supplies the cost saving.
- No image input → skip the visual pass, run `figma-cli lint`, `a11y audit`, and
  token-compliance checks, and **state plainly** that visual verification did not
  run.

The pipeline must never require sub-agents to function.
