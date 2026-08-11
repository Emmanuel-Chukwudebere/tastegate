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

# The daemon is a HARD dependency for speed, and its failure mode is silent.
# `figma-cli status` prints "Connected to Figma" whenever CDP is reachable, even
# when the daemon's auth token is stale — every `eval`/`run` then falls back to a
# cold Node spawn plus CDP handshake. Measured on a real session: 20.1s per call
# with a mismatched token, 3.0s after `daemon restart`. A 6.6x tax on every call,
# invisible in `status` output and invisible in command results.
DAEMON_STATUS="$(figma-cli daemon status 2>&1 || true)"
case "$DAEMON_STATUS" in
  *"is running"*)
    echo "PREFLIGHT: figma-daemon OK"
    ;;
  *"token mismatch"*|*"auth failed"*)
    echo "PREFLIGHT: figma-daemon AUTH FAILED - every eval/run costs ~20s instead of ~3s."
    echo "PREFLIGHT: figma-daemon fix with: figma-cli daemon restart"
    HARD_FAIL=1
    ;;
  *)
    echo "PREFLIGHT: figma-daemon NOT RUNNING - render, set-batch, and eval will fail."
    echo "PREFLIGHT: figma-daemon fix with: figma-cli daemon start"
    HARD_FAIL=1
    ;;
esac

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
