#!/usr/bin/env bash
# Rasterise the two PNGs the crawlers need, from the HTML sources next to this
# script. Everything on the site itself is SVG; these exist only because
# LinkedIn, Facebook, Slack and WhatsApp will not render an SVG og:image, and
# Google wants a raster for an Organization logo.
#
#   ./scripts/make-images.sh
#
# Requires Google Chrome. Re-run after editing og-card.html or logo-card.html.
# The output is NOT fingerprinted by deploy.sh — see README § "Updating".

set -euo pipefail
cd "$(dirname "$0")/.."

CHROME="${CHROME:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"
[[ -x "$CHROME" ]] || { echo "Chrome not found at: $CHROME (set CHROME=...)" >&2; exit 1; }

shot() { # src.html  out.png  W  H
  local tmp; tmp="$(mktemp -d)"
  "$CHROME" --headless --disable-gpu --hide-scrollbars \
    --force-device-scale-factor=1 --window-size="$3,$4" \
    --screenshot="$tmp/out.png" "file://$(pwd)/$1" >/dev/null 2>&1
  [[ -s "$tmp/out.png" ]] || { echo "render failed: $1" >&2; exit 1; }
  mv "$tmp/out.png" "$2"; rm -rf "$tmp"
  echo "  $2  ($(du -h "$2" | cut -f1))"
}

echo "==> rendering"
shot scripts/og-card.html   assets/img/og-card.png    1200 630
shot scripts/logo-card.html assets/img/larva-logo.png  512 512
echo "==> done"
