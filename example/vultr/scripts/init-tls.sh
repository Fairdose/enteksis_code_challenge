#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)"
DEPLOY_DIR="$(cd -- "$SCRIPT_DIR/.." >/dev/null 2>&1 && pwd -P)"
ENV_FILE="$DEPLOY_DIR/.env"
COMPOSE_FILE="$DEPLOY_DIR/compose.yaml"
HTTP_CONFIG="$DEPLOY_DIR/nginx/http.conf"
TLS_CONFIG="$DEPLOY_DIR/nginx/default.conf"
NGINX_AVAILABLE="/etc/nginx/sites-available/ent-challange"
NGINX_ENABLED="/etc/nginx/sites-enabled/ent-challange"
NGINX_BIN="$(command -v nginx 2>/dev/null || true)"
[[ -n "$NGINX_BIN" ]] || NGINX_BIN="/usr/sbin/nginx"

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

for command_name in certbot docker getent sudo; do
  command -v "$command_name" >/dev/null 2>&1 || {
    printf 'Gerekli komut bulunamadı: %s\n' "$command_name" >&2
    exit 1
  }
done
[[ -x "$NGINX_BIN" ]] || {
  printf 'Gerekli komut bulunamadı: nginx\n' >&2
  exit 1
}

for domain in "$FRONTEND_DOMAIN" "$API_DOMAIN"; do
  if ! getent ahostsv4 "$domain" >/dev/null 2>&1; then
    printf 'DNS kaydı henüz çözümlenmiyor: %s\n' "$domain" >&2
    exit 1
  fi
done

sudo -n install -d -m 0755 /var/www/certbot
sudo -n install -m 0644 "$HTTP_CONFIG" "$NGINX_AVAILABLE"
sudo -n ln -sfn "$NGINX_AVAILABLE" "$NGINX_ENABLED"
if [[ -L /etc/nginx/sites-enabled/default ]]; then
  sudo -n unlink /etc/nginx/sites-enabled/default
fi
sudo -n "$NGINX_BIN" -t
sudo -n systemctl reload nginx

if command -v ufw >/dev/null 2>&1 && sudo -n ufw status | grep -q '^Status: active'; then
  sudo -n ufw allow 80/tcp
  sudo -n ufw allow 443/tcp
fi

COMPOSE=(docker compose --env-file "$ENV_FILE" --file "$COMPOSE_FILE")
"${COMPOSE[@]}" config --quiet
"${COMPOSE[@]}" up --build --detach db migrate api client

sudo -n certbot certonly \
  --webroot \
  --webroot-path /var/www/certbot \
  --non-interactive \
  --agree-tos \
  --email "$LETSENCRYPT_EMAIL" \
  --cert-name "$FRONTEND_DOMAIN" \
  --domain "$FRONTEND_DOMAIN" \
  --domain "$API_DOMAIN"

sudo -n install -m 0644 "$TLS_CONFIG" "$NGINX_AVAILABLE"
sudo -n "$NGINX_BIN" -t
sudo -n systemctl reload nginx
"${COMPOSE[@]}" ps

curl --fail --silent --show-error "https://$API_DOMAIN/health"
printf '\nTLS sertifikası alındı ve host Nginx başlatıldı.\n'
