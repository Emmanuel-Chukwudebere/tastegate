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

# Optional: playwright powers analyze-url, screenshot-url, and recreate-url.
# Check the global npm root and node's own resolver rather than invoking the
# CLI itself — a missing package must never be discovered via a download or
# a hanging spawn (that is exactly what timed out in the field).
NPM_G="$(npm root -g 2>/dev/null)"
if [ -d "${NPM_G:-/nonexistent}/playwright" ] || node -e "require.resolve('playwright')" >/dev/null 2>&1; then
  echo "PREFLIGHT: playwright OK"
else
  echo "PREFLIGHT: playwright ABSENT - analyze-url, screenshot-url, and recreate-url will fail."
  echo "PREFLIGHT: playwright install with: npm i -g playwright"
fi

# Optional: figma-use backs the analyze subcommands and node operations.
# Same rule: check the global npm root only, never run `npx figma-use`.
if [ -d "${NPM_G:-/nonexistent}/figma-use" ]; then
  echo "PREFLIGHT: figma-use OK"
else
  echo "PREFLIGHT: figma-use ABSENT - analyze (clusters, colors, typography, spacing) and node (tree, bindings, to-component) will fail."
  echo "PREFLIGHT: figma-use install with: npm i -g figma-use"
fi

exit "$HARD_FAIL"
