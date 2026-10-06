#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)"
DEPLOY_DIR="$(cd -- "$SCRIPT_DIR/.." >/dev/null 2>&1 && pwd -P)"
ENV_FILE="$DEPLOY_DIR/.env"
COMPOSE_FILE="$DEPLOY_DIR/compose.yaml"

[[ -f "$ENV_FILE" ]] || {
  printf 'Eksik dosya: %s\n' "$ENV_FILE" >&2
  exit 1
}

COMPOSE=(docker compose --env-file "$ENV_FILE" --file "$COMPOSE_FILE")
CERTBOT_ARGS=(renew --webroot --webroot-path /var/www/certbot --quiet)
if [[ "${1:-}" == "--dry-run" ]]; then
  CERTBOT_ARGS+=(--dry-run)
fi

"${COMPOSE[@]}" --profile tools run --rm certbot "${CERTBOT_ARGS[@]}"
"${COMPOSE[@]}" exec gateway nginx -s reload
