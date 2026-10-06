#!/usr/bin/env bash
set -Eeuo pipefail

NGINX_BIN="$(command -v nginx 2>/dev/null || true)"
[[ -n "$NGINX_BIN" ]] || NGINX_BIN="/usr/sbin/nginx"
[[ -x "$NGINX_BIN" ]] || {
  printf 'Gerekli komut bulunamadı: nginx\n' >&2
  exit 1
}

if [[ "$EUID" -eq 0 ]]; then
  SUDO=()
else
  command -v sudo >/dev/null 2>&1 || {
    printf 'sudo bulunamadı. Scripti root olarak çalıştırın.\n' >&2
    exit 1
  }
  SUDO=(sudo -n)
fi

CERTBOT_ARGS=(
  renew
  --webroot
  --webroot-path /var/www/certbot
  --quiet
  --no-random-sleep-on-renew
)
if [[ "${1:-}" == "--dry-run" ]]; then
  CERTBOT_ARGS+=(--dry-run)
elif [[ $# -ne 0 ]]; then
  printf 'Bilinmeyen argüman: %s\n' "$1" >&2
  exit 1
fi

"${SUDO[@]}" certbot "${CERTBOT_ARGS[@]}"
"${SUDO[@]}" "$NGINX_BIN" -t
"${SUDO[@]}" systemctl reload nginx
