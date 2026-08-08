#!/usr/bin/env bash
# Deterministic quality gates. Runs BEFORE any model-based critique so the
# expensive pass never spends attention on tool-detectable defects.
# Usage: gates.sh [nodeId] [component-name]
set -uo pipefail
NODE_ID="${1:-}"
COMPONENT="${2:-}"
GATE_FAIL=0

echo "GATE: lint"
if figma-cli lint --fix --json 2>/dev/null; then
  echo "GATE: lint OK (auto-fixed what it could)"
else
  echo "GATE: lint reported issues that need manual attention"
fi

if [ -n "$NODE_ID" ] && [ -n "$COMPONENT" ]; then
  echo "GATE: spec --check $COMPONENT against $NODE_ID"
  if figma-cli spec "$COMPONENT" --check "$NODE_ID" --tolerance 2; then
    echo "GATE: spec OK"
  else
    echo "GATE: spec VIOLATION - build is off-spec. Fix before critique."
    GATE_FAIL=1
  fi
else
  echo "GATE: spec --check skipped (no nodeId/component given)"
fi

echo "GATE: a11y audit"
figma-cli a11y audit ${NODE_ID:+"$NODE_ID"} 2>/dev/null || echo "GATE: a11y audit produced findings"

exit "$GATE_FAIL"
