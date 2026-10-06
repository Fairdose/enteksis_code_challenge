#!/usr/bin/env bash
set -Eeuo pipefail

if [[ "$(uname -s)" != "Linux" ]] || [[ ! -f /etc/os-release ]]; then
  printf 'Bu script Debian veya Ubuntu Linux üzerinde çalıştırılmalıdır.\n' >&2
  exit 1
fi

# shellcheck disable=SC1091
source /etc/os-release
if [[ "${ID:-}" != "ubuntu" && "${ID:-}" != "debian" ]]; then
  printf 'Desteklenmeyen dağıtım: %s. Debian veya Ubuntu kullanın.\n' "${PRETTY_NAME:-bilinmiyor}" >&2
  exit 1
fi

if [[ "$EUID" -eq 0 ]]; then
  SUDO=()
else
  command -v sudo >/dev/null 2>&1 || {
    printf 'sudo bulunamadı. Scripti root olarak çalıştırın.\n' >&2
    exit 1
  }
  SUDO=(sudo)
fi

"${SUDO[@]}" apt-get update
"${SUDO[@]}" apt-get install -y ca-certificates curl git openssl
"${SUDO[@]}" install -m 0755 -d /etc/apt/keyrings
"${SUDO[@]}" curl -fsSL "https://download.docker.com/linux/${ID}/gpg" \
  -o /etc/apt/keyrings/docker.asc
"${SUDO[@]}" chmod a+r /etc/apt/keyrings/docker.asc

ARCHITECTURE="$(dpkg --print-architecture)"
CODENAME="${UBUNTU_CODENAME:-$VERSION_CODENAME}"
"${SUDO[@]}" tee /etc/apt/sources.list.d/docker.sources >/dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/${ID}
Suites: ${CODENAME}
Components: stable
Architectures: ${ARCHITECTURE}
Signed-By: /etc/apt/keyrings/docker.asc
EOF

"${SUDO[@]}" apt-get update
"${SUDO[@]}" apt-get install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin
"${SUDO[@]}" systemctl enable --now docker

if [[ "$EUID" -ne 0 ]]; then
  DEPLOY_USER="$(id -un)"
else
  DEPLOY_USER="${SUDO_USER:-root}"
fi

id "$DEPLOY_USER" >/dev/null 2>&1 || {
  printf 'Deploy kullanıcısı bulunamadı: %s\n' "$DEPLOY_USER" >&2
  exit 1
}

"${SUDO[@]}" usermod -aG docker "$DEPLOY_USER"
"${SUDO[@]}" install -d -m 0755 -o "$DEPLOY_USER" -g "$(id -gn "$DEPLOY_USER")" \
  /opt/ent-challange

docker --version || "${SUDO[@]}" docker --version
docker compose version || "${SUDO[@]}" docker compose version

printf '\nDocker kurulumu tamamlandı.\n'
printf 'Vultr Firewall üzerinde yalnızca gerekli inbound portlarını açın: 22, 80 ve 443.\n'
if [[ "$DEPLOY_USER" != "root" ]]; then
  printf 'Docker grup üyeliğinin etkinleşmesi için SSH oturumunu kapatıp yeniden bağlanın.\n'
fi
