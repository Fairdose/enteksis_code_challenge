#!/usr/bin/env bash
set -Eeuo pipefail

if [[ "$(uname -s)" != "Linux" ]] || [[ ! -f /etc/os-release ]]; then
  printf 'Bu script Ubuntu Linux üzerinde çalıştırılmalıdır.\n' >&2
  exit 1
fi

# shellcheck disable=SC1091
source /etc/os-release
if [[ "${ID:-}" != "ubuntu" ]]; then
  printf 'Desteklenmeyen dağıtım: %s. Ubuntu 24.04 LTS kullanın.\n' "${PRETTY_NAME:-bilinmiyor}" >&2
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
"${SUDO[@]}" curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  -o /etc/apt/keyrings/docker.asc
"${SUDO[@]}" chmod a+r /etc/apt/keyrings/docker.asc

ARCHITECTURE="$(dpkg --print-architecture)"
CODENAME="${UBUNTU_CODENAME:-$VERSION_CODENAME}"
"${SUDO[@]}" tee /etc/apt/sources.list.d/docker.sources >/dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
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
  "${SUDO[@]}" usermod -aG docker "$(id -un)"
fi

docker --version || "${SUDO[@]}" docker --version
docker compose version || "${SUDO[@]}" docker compose version

printf '\nDocker kurulumu tamamlandı.\n'
printf 'Vultr Firewall üzerinde yalnızca gerekli inbound portlarını açın: 22, 80 ve 443.\n'
if [[ "$EUID" -ne 0 ]]; then
  printf 'Docker grup üyeliğinin etkinleşmesi için SSH oturumunu kapatıp yeniden bağlanın.\n'
fi
