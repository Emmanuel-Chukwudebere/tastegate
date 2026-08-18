#!/usr/bin/env bash
# Publication metadata: authorship, licence grant, and frontmatter portability.
#
# Why this suite exists: a SKILL.md travels ALONE. It gets installed one at a time
# (`npx skills@latest add`), copied into ~/.claude/skills/, or uploaded to claude.ai,
# and arrives with no repository around it — so a licence that lives only in LICENSE
# does not travel with the file, and an unattributed SKILL.md sitting in someone
# else's skills directory carries nothing that says whose work it is. Verified live:
# all five of this plugin's skills were installed under ~/.agents/skills/ next to
# nine third-party skills, with nothing in any of them naming an author.
set -uo pipefail
PASS=0; FAIL=0
ok()  { echo "  PASS: $1"; PASS=$((PASS+1)); }
bad() { echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

# Frontmatter only — grepping the whole file would match prose about licences.
fm() { awk 'NR==1 && $0=="---"{f=1;next} f && $0=="---"{exit} f' "$1"; }
fmhas() { if fm "$1" | grep -qF "$2"; then ok "$1 frontmatter has '$2'"; else bad "$1 frontmatter missing '$2'"; fi; }
has() { if grep -qF "$2" "$1" 2>/dev/null; then ok "$1 has '$2'"; else bad "$1 missing '$2'"; fi; }

HOLDER="Emmanuel Chukwudebere"

# --- The grant itself -------------------------------------------------------
# plugin.json declared "license": "MIT" for six versions with no licence text
# anywhere in the repo. A declared licence with no text grants nothing: there is
# no copyright holder named and no permission actually extended.
if [ -f LICENSE ]; then ok "LICENSE exists"; else bad "LICENSE missing — a declared licence with no text grants nothing"; fi
has LICENSE "MIT License"
has LICENSE "Copyright (c) 2026 $HOLDER"
# This clause is what makes attribution binding on anyone who copies a skill.
has LICENSE "The above copyright notice and this permission notice shall be included in all"

# --- Manifests --------------------------------------------------------------
P=.claude-plugin/plugin.json
has "$P" "\"license\": \"MIT\""
# A handle is not an authorship claim. The marketplace manifest already published
# the real name, so a plugin.json reading "imman" was the inconsistent one.
has "$P" "\"name\": \"$HOLDER\""
has "$P" "\"url\": \"https://github.com/Emmanuel-Chukwudebere\""
has "$P" "\"repository\": \"https://github.com/Emmanuel-Chukwudebere/claude-design\""
M=.claude-plugin/marketplace.json
has "$M" "\"name\": \"$HOLDER\""
has "$M" "\"url\": \"https://github.com/Emmanuel-Chukwudebere\""

# --- Every skill, including any added later ---------------------------------
# The loop is the point: a new skill directory adds its own checks and fails
# until it is stamped, so this cannot be forgotten once rather than enforced.
COUNT=0
for f in skills/*/SKILL.md; do
  COUNT=$((COUNT+1))
  fmhas "$f" "license: MIT"
  fmhas "$f" "metadata:"
  fmhas "$f" "author: $HOLDER"
  fmhas "$f" "homepage: https://github.com/Emmanuel-Chukwudebere/claude-design"
done
if [ "$COUNT" -ge 6 ]; then ok "all $COUNT skills checked"; else bad "expected at least 6 skills, found $COUNT"; fi

# --- Portability: the six-key limit ----------------------------------------
# The Agent Skills spec allows exactly six top-level frontmatter keys. Anything
# else is a HARD ERROR on claude.ai upload, the Skills API, and package_skill.py
# — "Unexpected key(s) in SKILL.md frontmatter" — not a field that gets ignored.
# Claude Code itself accepts far more, so a bad key here loads fine locally and
# only fails at publication, which is the worst possible time to find out.
# This is why `author` sits inside `metadata`: there is no top-level author field.
ALLOWED="allowed-tools compatibility description license metadata name"
for f in skills/*/SKILL.md; do
  BADKEYS=""
  for k in $(fm "$f" | grep -E '^[A-Za-z][A-Za-z0-9_-]*:' | sed 's/:.*//'); do
    case " $ALLOWED " in *" $k "*) ;; *) BADKEYS="$BADKEYS $k";; esac
  done
  if [ -z "$BADKEYS" ]; then ok "$f uses only spec-allowed frontmatter keys"
  else bad "$f has non-spec frontmatter key(s):$BADKEYS — upload fails hard on these"; fi
done

# The two keys most likely to be reached for next, both fatal at upload. Other
# plugins ship a top-level `version:`, which is exactly why this is pinned here.
for f in skills/*/SKILL.md; do
  if fm "$f" | grep -qE '^(author|version):'; then
    bad "$f has a top-level author:/version: — put it under metadata:"
  else ok "$f keeps author/version under metadata"; fi
done

# --- README states the holder ----------------------------------------------
has README.md "Copyright (c) 2026 $HOLDER"
has README.md "Full text in [\`LICENSE\`](LICENSE)"
# The reason has to survive, or the next edit "simplifies" the per-skill grant away.
has README.md "because a skill travels on its own"
has README.md "The Agent"
# Emil Kowalski's skills are a dependency, not vendored — the distinction is what
# keeps this plugin's MIT grant clean, so the credit must stay.
has README.md "Emil Kowalski's skills are MIT and separately installed"

echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
