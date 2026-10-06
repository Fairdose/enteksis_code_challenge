#!/usr/bin/env bash
set -Eeuo pipefail

readonly DEPLOY_ROOT="/opt/ent-challange"
readonly REPOSITORY_URL="https://github.com/Fairdose/enteksis_code_challenge.git"
readonly LOCK_FILE="/tmp/ent-challange-production-deploy.lock"

log() {
  printf '[deploy] %s\n' "$*"
}

fail() {
  printf '[deploy] Hata: %s\n' "$*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || fail "Gerekli komut bulunamadı: $1"
}

checkout_revision() {
  local revision="$1"

  git -C "$DEPLOY_ROOT" checkout --detach "$revision"
  git -C "$DEPLOY_ROOT" submodule sync --recursive
  git -C "$DEPLOY_ROOT" submodule update --init --recursive
}

main() {
  local revision="${1:-}"
  local previous_revision=""

  [[ $# -eq 1 ]] || fail "Kullanım: $0 <40-karakter-commit-sha>"
  [[ "$revision" =~ ^[0-9a-f]{40}$ ]] || fail "Geçersiz commit SHA: $revision"

  require_command curl
  require_command docker
  require_command flock
  require_command git

  exec 9>"$LOCK_FILE"
  flock -n 9 || fail "Başka bir production deploy işlemi çalışıyor"

  [[ -d "$DEPLOY_ROOT/.git" ]] || \
    fail "$DEPLOY_ROOT hazır değil; önce README'deki ilk VPS kurulumunu tamamlayın"
  [[ "$(git -C "$DEPLOY_ROOT" remote get-url origin)" == "$REPOSITORY_URL" ]] || \
    fail "Beklenmeyen origin remote"
  [[ -z "$(git -C "$DEPLOY_ROOT" status --porcelain --untracked-files=no)" ]] || \
    fail "Deploy checkout'unda commitlenmemiş takip edilen değişiklikler var"
  [[ -f "$DEPLOY_ROOT/example/vultr/.env" ]] || \
    fail "Production .env dosyası eksik"

  previous_revision="$(git -C "$DEPLOY_ROOT" rev-parse HEAD)"
  log "origin/main güncelleniyor"
  git -C "$DEPLOY_ROOT" fetch --prune origin main
  git -C "$DEPLOY_ROOT" cat-file -e "${revision}^{commit}" 2>/dev/null || \
    fail "Commit origin üzerinde bulunamadı: $revision"
  git -C "$DEPLOY_ROOT" merge-base --is-ancestor "$revision" origin/main || \
    fail "Commit origin/main geçmişinde değil: $revision"

  log "Sürüm hazırlanıyor: $revision"
  checkout_revision "$revision"

  if "$DEPLOY_ROOT/example/vultr/scripts/deploy.sh"; then
    log "Deploy başarılı: $revision"
    return 0
  fi

  printf '[deploy] Deploy başarısız; önceki sürüme dönülüyor: %s\n' \
    "$previous_revision" >&2
  checkout_revision "$previous_revision"
  if "$DEPLOY_ROOT/example/vultr/scripts/deploy.sh"; then
    fail "Yeni sürüm başarısız oldu; önceki sürüm yeniden çalışıyor"
  fi

  fail "Yeni sürüm ve otomatik rollback başarısız oldu; sunucuyu manuel inceleyin"
}

main "$@"
