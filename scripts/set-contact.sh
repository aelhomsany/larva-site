#!/usr/bin/env bash
# Replace the placeholder company details across every page of the Larva site.
#
# Everything this script touches is a literal placeholder string, so it is safe
# to run once, or to run again later with different values — as long as you pass
# the values that are *currently* in the files.
#
#   ./scripts/set-contact.sh
#
# Edit the block below, then run it from the repository root.

set -euo pipefail

cd "$(dirname "$0")/.."

# ---------------------------------------------------------------------------
# 1. Fill these in.
# ---------------------------------------------------------------------------

DOMAIN="https://leaveo.net"          # no trailing slash, apex (www 301s here)

# Real mailboxes, live on the Leaveo domain. If Larva later runs its own
# (hello@ / careers@ on the Larva domain), add a line here and one subst below.
EMAIL_SALES="sales@leaveo.net"
EMAIL_SUPPORT="support@leaveo.net"

# The registered office. Footer form is compact; full form is used on the
# contact page. Use <br> between lines in both.
ADDRESS_FOOTER='Larva LLC<br>Cairo<br>Egypt'
ADDRESS_FULL='<strong>Larva LLC</strong>Cairo<br>Egypt'

# ---------------------------------------------------------------------------
# 2. Nothing below here normally needs changing.
# ---------------------------------------------------------------------------

PAGES=(index.html capabilities.html leaveo.html contact.html 404.html)
FEEDS=(sitemap.xml robots.txt)

# BSD sed (macOS) and GNU sed disagree about -i. Use a temp file instead.
subst() { # subst <find> <replace> <file...>
  local find="$1" repl="$2"; shift 2
  local f tmp
  for f in "$@"; do
    tmp="$(mktemp)"
    FIND="$find" REPL="$repl" perl -pe 's/\Q$ENV{FIND}\E/$ENV{REPL}/g' "$f" > "$tmp"
    mv "$tmp" "$f"
  done
}

subst 'https://leaveo.net' "$DOMAIN"            "${PAGES[@]}" "${FEEDS[@]}"
subst 'sales@leaveo.net'   "$EMAIL_SALES"   "${PAGES[@]}"
subst 'support@leaveo.net' "$EMAIL_SUPPORT" "${PAGES[@]}"

subst 'Larva LLC<br>Cairo<br>Egypt' \
      "$ADDRESS_FOOTER" "${PAGES[@]}"
subst '<strong>Larva LLC</strong>Cairo<br>Egypt' \
      "$ADDRESS_FULL" "${PAGES[@]}"

echo "Updated: ${PAGES[*]} ${FEEDS[*]}"
echo "Check the canonical domain:  grep -h 'rel=\"canonical\"' ./*.html"
