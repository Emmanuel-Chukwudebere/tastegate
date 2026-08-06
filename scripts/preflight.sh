#!/usr/bin/env bash
# Checks every dependency the design pipeline needs. Exits non-zero if a hard
# dependency is missing. Optional dependencies warn but do not fail.
set -uo pipefail
HARD_FAIL=0

if command -v figma-cli >/dev/null 2>&1; then
  echo "PREFLIGHT: figma-cli OK ($(figma-cli --version 2>/dev/null | head -1))"
else
  echo "PREFLIGHT: figma-cli MISSING - install with: npm i -g figma-ds-cli"
  HARD_FAIL=1
fi

if figma-cli status >/dev/null 2>&1; then
  echo "PREFLIGHT: figma-desktop OK"
else
  echo "PREFLIGHT: figma-desktop UNREACHABLE - open Figma Desktop, then run: figma-cli connect"
  HARD_FAIL=1
fi

if [ -d "$HOME/.claude/skills/emil-design-eng" ] || [ -d "$HOME/.agents/skills/emil-design-eng" ]; then
  echo "PREFLIGHT: emil-skills OK"
else
  echo "PREFLIGHT: emil-skills ABSENT - motion standards still enforced via skills/design/MOTION.md."
  echo "PREFLIGHT: emil-skills install with: npx skills@latest add emilkowalski/skills"
fi

exit "$HARD_FAIL"
