#!/usr/bin/env bash
# footprint-setup.sh — create the local home for footprint-audit.
# Safe + idempotent: makes ~/footprint/{reports,config} and scaffolds a config
# template. Never overwrites an existing config.md. Read/writes only ~/footprint.
#
# Usage:
#   footprint-setup.sh           # create dirs + template (default)
#   footprint-setup.sh --status  # show what exists, change nothing
set -euo pipefail

ROOT="$HOME/footprint"
REPORTS="$ROOT/reports"
CONFIG="$ROOT/config"
EXAMPLE="$CONFIG/config.example.md"
LIVE="$CONFIG/config.md"

status() {
  echo "footprint-audit setup status:"
  for p in "$ROOT" "$REPORTS" "$CONFIG" "$EXAMPLE" "$LIVE"; do
    if [ -e "$p" ]; then echo "  ✓ $p"; else echo "  ✗ $p (missing)"; fi
  done
}

if [ "${1:-}" = "--status" ]; then
  status
  exit 0
fi

mkdir -p "$REPORTS" "$CONFIG"

# .gitignore so nothing personal can ever land in a repo if this folder is nested.
cat > "$ROOT/.gitignore" <<'EOF'
# Everything here is personal — never commit it.
*
!.gitignore
EOF

# Write the template every run (it's a template, safe to refresh).
cat > "$EXAMPLE" <<'EOF'
# footprint-audit config (template)
# Fill this in, save as config.md in the same folder, then run the audit.
# Nothing here is inferred — the audit only uses what you type.

names_aliases:   First Last; maiden/variant spellings; nicknames
city_state:      City, ST
emails:          you@example.com, you@work.com
phones:          555-555-5555 (personal), 555-555-5556 (public/VoIP)

# PROTECT = flag as exposure if found (suppress these):
protect:         home address; personal cell; kids' names
# KEEP  = expected/wanted visibility, do NOT flag as a problem:
keep:            Business Name; YouTube channel; business email/phone
EOF

# Only create the live config from the template if it doesn't exist yet.
if [ ! -f "$LIVE" ]; then
  cp "$EXAMPLE" "$LIVE"
  CREATED_LIVE=1
else
  CREATED_LIVE=0
fi

echo "✅ footprint-audit home ready at: $ROOT"
echo "   • reports → $REPORTS"
echo "   • config  → $CONFIG"
if [ "$CREATED_LIVE" = "1" ]; then
  echo "   • created $LIVE from the template — fill it in next."
else
  echo "   • $LIVE already exists — left untouched."
fi
echo ""
echo "Next: fill in $LIVE (names, city, emails, phones, protect/keep), then ask"
echo "Claude to run the footprint audit."
