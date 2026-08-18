#!/usr/bin/env bash
# Verifies preflight reports each dependency and exits non-zero when Figma is unreachable.
set -uo pipefail
PASS=0; FAIL=0
check() { if eval "$2"; then echo "  PASS: $1"; PASS=$((PASS+1)); else echo "  FAIL: $1"; FAIL=$((FAIL+1)); fi; }

OUT="$(bash scripts/preflight.sh 2>&1)"
RC=$?

check "reports figma-cli presence" 'grep -q "PREFLIGHT: figma-cli" <<<"$OUT"'
check "reports figma desktop check" 'grep -q "PREFLIGHT: figma-desktop" <<<"$OUT"'
check "reports emil skills check"   'grep -q "PREFLIGHT: emil-skills" <<<"$OUT"'
check "reports playwright check"    'grep -q "PREFLIGHT: playwright" <<<"$OUT"'
check "reports figma-use check"     'grep -q "PREFLIGHT: figma-use" <<<"$OUT"'
check "manifest is valid json"      'node -e "JSON.parse(require(\"fs\").readFileSync(\".claude-plugin/plugin.json\",\"utf8\"))"'
check "manifest name is tastegate" 'node -e "const m=JSON.parse(require(\"fs\").readFileSync(\".claude-plugin/plugin.json\",\"utf8\"));process.exit(m.name===\"tastegate\"?0:1)"'

# Test exit code: preflight must exit non-zero when figma-cli is absent
TMPDIR_STUB="$(mktemp -d)"
trap "rm -rf \"$TMPDIR_STUB\"" EXIT
OUT_NO_CLI="$(PATH="$TMPDIR_STUB:/usr/bin:/bin" bash scripts/preflight.sh 2>&1)"
RC_NO_CLI=$?
check "exits non-zero when figma-cli absent" '[ "$RC_NO_CLI" -ne 0 ]'

# Exit code must match the state of EVERY hard dependency, and there are two:
# reachability (`status`) and daemon health. Predicting the exit code from `status`
# alone is the same mistake the daemon gotcha exists to document -- `status` prints
# "Connected to Figma" whenever CDP is reachable and says nothing about the daemon,
# so it exits 0 while preflight correctly exits 1 on a dead or stale-token daemon.
# Observed live: status rc=0, daemon "not running", preflight rc=1 -- all correct.
check "reports daemon check" 'grep -q "PREFLIGHT: figma-daemon" <<<"$OUT"'

DAEMON_OK=1
case "$(figma-cli daemon status 2>&1 || true)" in *"is running"*) DAEMON_OK=0 ;; esac

if figma-cli status >/dev/null 2>&1 && [ "$DAEMON_OK" -eq 0 ]; then
  check "exits 0 when hard deps satisfied" '[ "$RC" -eq 0 ]'
else
  check "exits non-zero when a hard dep is missing" '[ "$RC" -ne 0 ]'
fi

# The daemon must be a HARD failure, not a warning: a stale token costs ~20s per
# eval/run versus ~3s, invisibly. Verify the polarity from the script itself, so a
# regression to a soft warning fails here even on a machine with a healthy daemon.
check "daemon failure sets HARD_FAIL" \
  'grep -A3 "token mismatch" scripts/preflight.sh | grep -q "HARD_FAIL=1"'
check "absent daemon sets HARD_FAIL" \
  'grep -A3 "NOT RUNNING" scripts/preflight.sh | grep -q "HARD_FAIL=1"'

echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
