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

set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a

: "${FRONTEND_DOMAIN:?FRONTEND_DOMAIN tanımlanmalıdır}"
: "${API_DOMAIN:?API_DOMAIN tanımlanmalıdır}"
: "${POSTGRES_DB:?POSTGRES_DB tanımlanmalıdır}"
: "${POSTGRES_USER:?POSTGRES_USER tanımlanmalıdır}"
: "${POSTGRES_PASSWORD:?POSTGRES_PASSWORD tanımlanmalıdır}"

if [[ ! "$POSTGRES_PASSWORD" =~ ^[[:xdigit:]]{64}$ ]]; then
  printf 'POSTGRES_PASSWORD, openssl rand -hex 32 ile üretilmiş 64 karakterlik hex değer olmalıdır.\n' >&2
  exit 1
fi

CERTIFICATE_PATH="/etc/letsencrypt/live/$FRONTEND_DOMAIN/fullchain.pem"
[[ -f "$CERTIFICATE_PATH" ]] || {
  printf 'TLS sertifikası bulunamadı. Önce scripts/init-tls.sh çalıştırın.\n' >&2
  exit 1
}

COMPOSE=(docker compose --env-file "$ENV_FILE" --file "$COMPOSE_FILE")
"${COMPOSE[@]}" config --quiet
"${COMPOSE[@]}" up --build --detach --remove-orphans
"${COMPOSE[@]}" ps

curl --fail --silent --show-error \
  --retry 12 --retry-delay 5 --retry-all-errors \
  "https://$API_DOMAIN/health"
printf '\nDeploy tamamlandı: https://%s\n' "$FRONTEND_DOMAIN"
