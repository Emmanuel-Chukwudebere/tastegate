#!/usr/bin/env bash
set -uo pipefail
PASS=0; FAIL=0
has() { if grep -qiF "$2" "$1" 2>/dev/null; then echo "  PASS: $(basename $1) has '$2'"; PASS=$((PASS+1)); else echo "  FAIL: $(basename $1) missing '$2'"; FAIL=$((FAIL+1)); fi; }
nothas() { if grep -qiF "$2" "$1" 2>/dev/null; then echo "  FAIL: $(basename $1) must NOT have '$2'"; FAIL=$((FAIL+1)); else echo "  PASS: $(basename $1) omits '$2'"; PASS=$((PASS+1)); fi; }

S=skills/taste/SKILL.md
has "$S" "description: Use when starting design work in a project that has no taste profile yet"
has "$S" "\`.claude/design/TASTE.md\` — the taste profile"
has "$S" "already exists, **amend it**. Read it first"
# Description must state triggers only, not summarize workflow:
nothas "$S" "description: Builds a taste profile by"
# analyze clusters is optional (needs figma-use); registry build must have a stated fallback:
has "$S" "(\`npm i -g figma-use\`); when it is unavailable, build the registry"

I=skills/taste/intake.md
has "$I" "\`analyze-url\` extracts real computed CSS via Playwright."
has "$I" "figma-cli analyze-url <url> -w 390  --screenshot   # mobile"
has "$I" "figma-cli analyze-url <url> -w 834  --screenshot   # tablet"
has "$I" "figma-cli analyze-url <url> -w 1440 --screenshot   # desktop"
has "$I" "widths, always with a screenshot:"
has "$I" "figma-cli gradient extract <image>            # real colors + gradient geometry"
has "$I" "figma-cli extract --pages \"Moodboard\""
has "$I" "\`analyze clusters\` is both an intake step and a health check: three near-identical"
has "$I" "\`browser_navigate\`, then \`browser_evaluate\`:"
has "$I" "transitionTimingFunction: cs.transitionTimingFunction,"
has "$I" "as **inferred**, never as measured."
# analyze-url is optional (needs playwright); fallback must mark values inferred:
has "$I" "if it is unavailable, capture the reference visually via Playwright MCP"
has "$I" "**Iconsax is not on Iconify.**"
has "$I" "unhosted set uses \`<SVG>\` rather than a silent lookalike substitution.**"

V=skills/taste/interview.md
has "$V" "**Typography temperament.** Which reads right: geometric and neutral;"
has "$V" "4. **Density.** Airy with generous whitespace, or dense and information-rich?"
has "$V" "expressive and playful? Note that keyboard-initiated actions never animate"
has "$V" "10. **The never list.** What must never appear? Record it verbatim"

T=skills/taste/TASTE-template.md
has "$T" "Accent appears in at most two placements per screen."
has "$T" "Path: <Iconify \`<Icon>\` | local \`<SVG>\` directory>"
has "$T" "## Breakpoint behaviour"
has "$T" "Enforced constraints, recorded verbatim from the user."

echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
