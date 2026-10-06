#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)"
DEPLOY_DIR="$(cd -- "$SCRIPT_DIR/.." >/dev/null 2>&1 && pwd -P)"
ENV_FILE="$DEPLOY_DIR/.env"
COMPOSE_FILE="$DEPLOY_DIR/compose.yaml"
BACKUP_DIR="$DEPLOY_DIR/backups"

[[ -f "$ENV_FILE" ]] || {
  printf 'Eksik dosya: %s\n' "$ENV_FILE" >&2
  exit 1
}

set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a

: "${POSTGRES_DB:?POSTGRES_DB tanımlanmalıdır}"
: "${POSTGRES_USER:?POSTGRES_USER tanımlanmalıdır}"
: "${POSTGRES_PASSWORD:?POSTGRES_PASSWORD tanımlanmalıdır}"

mkdir -p "$BACKUP_DIR"
chmod 700 "$BACKUP_DIR"
umask 077

BACKUP_PATH="$BACKUP_DIR/${POSTGRES_DB}-$(date -u +%Y%m%dT%H%M%SZ).dump"
docker compose --env-file "$ENV_FILE" --file "$COMPOSE_FILE" \
  exec --no-TTY \
  --env PGPASSWORD="$POSTGRES_PASSWORD" \
  db \
  pg_dump --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" --format custom \
  >"$BACKUP_PATH"

printf 'Yedek oluşturuldu: %s\n' "$BACKUP_PATH"
