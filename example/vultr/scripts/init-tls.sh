#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)"
DEPLOY_DIR="$(cd -- "$SCRIPT_DIR/.." >/dev/null 2>&1 && pwd -P)"
ENV_FILE="$DEPLOY_DIR/.env"
COMPOSE_FILE="$DEPLOY_DIR/compose.yaml"

[[ -f "$ENV_FILE" ]] || {
  printf 'Eksik dosya: %s. Önce .env.example dosyasını .env olarak kopyalayın.\n' "$ENV_FILE" >&2
  exit 1
}

set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a

: "${FRONTEND_DOMAIN:?FRONTEND_DOMAIN tanımlanmalıdır}"
: "${API_DOMAIN:?API_DOMAIN tanımlanmalıdır}"
: "${LETSENCRYPT_EMAIL:?LETSENCRYPT_EMAIL tanımlanmalıdır}"
: "${POSTGRES_DB:?POSTGRES_DB tanımlanmalıdır}"
: "${POSTGRES_USER:?POSTGRES_USER tanımlanmalıdır}"
: "${POSTGRES_PASSWORD:?POSTGRES_PASSWORD tanımlanmalıdır}"

if [[ ! "$POSTGRES_PASSWORD" =~ ^[[:xdigit:]]{64}$ ]]; then
  printf 'POSTGRES_PASSWORD, openssl rand -hex 32 ile üretilmiş 64 karakterlik hex değer olmalıdır.\n' >&2
  exit 1
fi

mkdir -p "$DEPLOY_DIR/data/letsencrypt" "$DEPLOY_DIR/data/certbot"

COMPOSE=(docker compose --env-file "$ENV_FILE" --file "$COMPOSE_FILE")
"${COMPOSE[@]}" config --quiet
"${COMPOSE[@]}" up --build --detach db migrate api client
"${COMPOSE[@]}" stop gateway >/dev/null 2>&1 || true

docker run --rm \
  --publish 80:80 \
  --volume "$DEPLOY_DIR/data/letsencrypt:/etc/letsencrypt" \
  certbot/certbot:v5.8.0 \
  certonly \
  --standalone \
  --non-interactive \
  --agree-tos \
  --email "$LETSENCRYPT_EMAIL" \
  --cert-name "$FRONTEND_DOMAIN" \
  --domain "$FRONTEND_DOMAIN" \
  --domain "$API_DOMAIN"

"${COMPOSE[@]}" up --detach gateway
"${COMPOSE[@]}" ps

printf '\nTLS sertifikası alındı ve Nginx gateway başlatıldı.\n'
