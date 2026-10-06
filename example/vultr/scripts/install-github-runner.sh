#!/usr/bin/env bash
set -Eeuo pipefail

readonly REPOSITORY_URL="https://github.com/Fairdose/enteksis_code_challenge"
readonly RUNNER_DIR="/opt/ent-challange-runner"
readonly RUNNER_NAME="ent-challange-vps"
readonly RUNNER_LABEL="ent-challange-production"
readonly RUNNER_VERSION="2.338.0"
readonly RUNNER_SHA256="af4b794c1bc41d73d40535e3fe092a39f9679cd8d965954c2aca25a05ca41d32"

fail() {
  printf 'GitHub runner kurulamadı: %s\n' "$*" >&2
  exit 1
}

[[ $# -eq 0 ]] || fail "Bu script argüman kabul etmez"
[[ "$EUID" -ne 0 ]] || fail "Scripti deploy kullanıcısıyla çalıştırın; root kullanmayın"

for command_name in curl sha256sum sudo tar; do
  command -v "$command_name" >/dev/null 2>&1 || fail "Gerekli komut bulunamadı: $command_name"
done

registration_token="${RUNNER_REGISTRATION_TOKEN:-}"
if [[ -z "$registration_token" && -t 0 ]]; then
  read -r -s -p 'GitHub registration token: ' registration_token
  printf '\n'
fi
[[ -n "$registration_token" ]] || fail "RUNNER_REGISTRATION_TOKEN tanımlanmalıdır"
archive_path="$(mktemp -p /tmp ent-challange-runner.XXXXXX.tar.gz)"
cleanup() {
  [[ -f "$archive_path" ]] && unlink "$archive_path"
}
trap cleanup EXIT

sudo -n install -d -m 0755 -o "$(id -un)" -g "$(id -gn)" "$RUNNER_DIR"
[[ ! -e "$RUNNER_DIR/.runner" ]] || fail "Runner zaten yapılandırılmış: $RUNNER_DIR"

curl --fail --location --silent --show-error \
  "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz" \
  --output "$archive_path"
printf '%s  %s\n' "$RUNNER_SHA256" "$archive_path" | sha256sum --check --status || \
  fail "Runner arşiv checksum doğrulaması başarısız"
tar --extract --gzip --file "$archive_path" --directory "$RUNNER_DIR"

(
  cd "$RUNNER_DIR"
  ./config.sh \
    --unattended \
    --url "$REPOSITORY_URL" \
    --token "$registration_token" \
    --name "$RUNNER_NAME" \
    --labels "$RUNNER_LABEL" \
    --work _work
  sudo -n ./svc.sh install "$(id -un)"
  sudo -n ./svc.sh start
)

printf 'GitHub runner kuruldu: %s (%s)\n' "$RUNNER_NAME" "$RUNNER_LABEL"
