#!/usr/bin/env bash
set -uo pipefail
PASS=0; FAIL=0
has() { if grep -qiF "$2" "$1" 2>/dev/null; then echo "  PASS: $(basename $1) has '$2'"; PASS=$((PASS+1)); else echo "  FAIL: $(basename $1) missing '$2'"; FAIL=$((FAIL+1)); fi; }
count() { local n; n=$(grep -ciF "$2" "$1" 2>/dev/null || echo 0); if [ "$n" -ge "$3" ]; then echo "  PASS: $(basename $1) has >=$3 '$2'"; PASS=$((PASS+1)); else echo "  FAIL: $(basename $1) has $n '$2', need $3"; FAIL=$((FAIL+1)); fi; }

R=skills/design/RUNTIMES.md
# All four harnesses in one file
has "$R" "# Runtime: Claude Code"
has "$R" "# Runtime: Codex"
has "$R" "# Runtime: Antigravity (\`agy\`)"
has "$R" "# Runtime: Grok (build mode)"
# Claude Code
has "$R" '| Dispatch a sub-agent | `Agent` tool, `subagent_type: "general-purpose"` |'
has "$R" 'Dispatch with `model: "sonnet"` for the QA pass.'
# Must restate RUBRIC.md's escalation condition as same-dimension, not any-dimension:
has "$R" "escalation condition is met (the same dimension ≤ 2 on two"
# Codex
has "$R" "Sub-agent dispatch requires multi-agent support. Add to \`~/.codex/config.toml\`:"
has "$R" '| Dispatch a sub-agent | `spawn_agent` / `wait_agent` / `close_agent` |'
has "$R" "Without it, \`spawn_agent\` is unavailable."
# Antigravity
has "$R" '| Dispatch a sub-agent | `invoke_subagent` — `TypeName: research` for read-only QA, `self` for full-capability work |'
has "$R" 'a **task artifact**: `write_to_file` with `IsArtifact: true` and `ArtifactType: "task"`'
has "$R" "a task artifact and edit it with \`replace_file_content\` as steps complete."
# Grok
has "$R" "Grok's tool surface varies by deployment, so **detect capabilities at runtime** rather than assuming them."
# Degradation stated for each of the four sections individually, one
# anchored check per runtime, rather than a bare "degrade" word count that
# would pass even if a section's degrade prose were gutted or inverted
# elsewhere. Each anchor sits on that section's own degradation sentence and
# includes its negation/modal ("Never" / "unavailable" / "no ... no" /
# "must never") so a reversed rule fails the check.
has "$R" "code and state plainly that visual verification did not run. Never assert"
has "$R" "If sub-agents are unavailable, run the QA pass **inline** in the main context."
has "$R" "Same rules as every runtime: no sub-agents → run QA inline; no image input →"
has "$R" "The pipeline must never require sub-agents to function."
# The sub-agent-half anchors above stop at "no image input →" / "must never
# require sub-agents" — they say nothing about what happens when image input
# itself is missing. That consequence ("skip the visual pass" / "say so
# plainly" — the guard against asserting unverified fidelity) needs its own
# anchor per runtime, with the consequence inside the anchor, not just the
# trigger. Codex's and Antigravity's action and reporting each share one
# line; Grok's are on two different lines, so it gets both halves anchored
# separately.
has "$R" "If image input is unavailable, skip the visual pass and **say so plainly**. Fall"
has "$R" "skip the visual pass and **say so plainly**, falling back to the deterministic"
has "$R" 'No image input → skip the visual pass, run `figma-cli lint`, `a11y audit`, and'
has "$R" 'token-compliance checks, and **state plainly** that visual verification did not'

M=README.md
has "$M" "claude --plugin-dir /path/to/claude-design"
has "$M" "npx skills@latest add emmanuel-chukwudebere/claude-design"
has "$M" "npm i -g figma-ds-cli                        # Figma control, no API key"
has "$M" "npx skills@latest add emilkowalski/skills    # motion + interaction layer (MIT)"
# Grounding must stay mandatory in the README, and the router must be documented as
# the default entry point — a router nobody knows about routes nothing.
has "$M" "Every stage refuses or warns without a taste profile, by design"
has "$M" "**Don't know which stage? Start here.**"
has "$M" "and \`design\` before \`ship\` so the"

echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
