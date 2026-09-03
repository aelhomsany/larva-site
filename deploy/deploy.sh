#!/usr/bin/env bash
# Publish the site to the server. Copies files only — it does not touch nginx,
# TLS, or anything else on the box.
#
#   ./deploy/deploy.sh root@203.0.113.10
#   SSH_PORT=2222 REMOTE_ROOT=/var/www/larva ./deploy/deploy.sh deploy@leaveo.net
#
# Requires: rsync and ssh on this machine, rsync on the server.

set -euo pipefail

TARGET="${1:-}"
REMOTE_ROOT="${REMOTE_ROOT:-/var/www/larva}"
SSH_PORT="${SSH_PORT:-22}"

if [[ -z "$TARGET" ]]; then
  echo "usage: $0 user@host" >&2
  exit 2
fi

cd "$(dirname "$0")/.."

if ! grep -q 'rel="canonical" href="https://leaveo.net/"' index.html 2>/dev/null; then
  echo "WARNING: the canonical domain in index.html is not https://leaveo.net."
  echo "         Set DOMAIN in ./scripts/set-contact.sh and re-run it, or press Enter"
  echo "         to publish anyway."
  read -r _
fi

# ---- asset fingerprints ----------------------------------------------------
# nginx serves CSS and JS with max-age=604800 (7 days) and the filenames never
# change, so without this a returning visitor keeps the old stylesheet for a
# week after a redesign. Stamp the content hash onto the two asset URLs; it only
# changes when the file does, and re-running is a no-op.
hash_of() {
  if command -v md5 >/dev/null 2>&1; then md5 -q "$1" | cut -c1-8
  else md5sum "$1" | cut -d' ' -f1 | cut -c1-8; fi
}
CSS_V="$(hash_of assets/css/site.css)"
JS_V="$(hash_of assets/js/site.js)"
perl -pi -e "s{/assets/css/site\.css(\?v=[0-9a-f]+)?}{/assets/css/site.css?v=${CSS_V}}g" ./*.html
perl -pi -e "s{/assets/js/site\.js(\?v=[0-9a-f]+)?}{/assets/js/site.js?v=${JS_V}}g"    ./*.html
echo "==> assets stamped: css=${CSS_V} js=${JS_V}"

echo "==> publishing $(pwd) to ${TARGET}:${REMOTE_ROOT}"

rsync -avz --delete \
  -e "ssh -p ${SSH_PORT}" \
  --exclude '.git' \
  --exclude '.DS_Store' \
  --exclude 'deploy/' \
  --exclude 'scripts/' \
  --exclude 'README.md' \
  ./ "${TARGET}:${REMOTE_ROOT}/"

ssh -p "${SSH_PORT}" "${TARGET}" "chown -R www-data:www-data ${REMOTE_ROOT} 2>/dev/null || true; find ${REMOTE_ROOT} -type d -exec chmod 755 {} +; find ${REMOTE_ROOT} -type f -exec chmod 644 {} +"

echo "==> done"
