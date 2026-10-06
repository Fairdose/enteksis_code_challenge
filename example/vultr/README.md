# Vultr production example

Bu dizin, Ent Challange uygulamasını tek bir Ubuntu 24.04 LTS Vultr Cloud Compute instance'ında
çalıştırmak için örnek otomasyon içerir. Nginx yalnızca `80/443` portlarını yayınlar; Vue/nginx,
Go API ve PostgreSQL aynı özel Docker ağında çalışır. PostgreSQL host portu internete açılmaz.

## Mimari

```text
Internet
   │
   ▼
Nginx gateway :80/:443
   ├── ent-challange.fairdose.net ──────► Vue/nginx :8080
   └── ent-challange-api.fairdose.net ──► Go API :8080 ──► PostgreSQL :5432
```

Certbot ilk sertifikayı standalone HTTP-01 ile alır. Çalışan Nginx,
`/.well-known/acme-challenge/` yolunu ortak webroot'tan sunar; sonraki yenilemeler servisi
durdurmadan yapılır.

## 1. Vultr instance ve firewall

- Ubuntu 24.04 LTS instance oluşturun.
- SSH key kullanın; parola ile root girişini kapatmanız önerilir.
- Vultr Firewall inbound kuralları:

| Protokol | Port | Kaynak |
| --- | --- | --- |
| TCP | 22 | Yalnızca yönetim IP'niz |
| TCP | 80 | Her yer |
| TCP | 443 | Her yer |

`5432`, `8080` ve `5173` portlarını açmayın. Docker tarafından yalnızca `80/443` publish edilir.

## 2. Vultr DNS

`fairdose.net` zone'unda iki kayıt oluşturun:

| Type | Name | Data | TTL |
| --- | --- | --- | --- |
| A | `ent-challange` | `<VULTR_IPV4>` | `300` |
| A | `ent-challange-api` | `<VULTR_IPV4>` | `300` |

DNS yayılımını instance üzerinde sertifika almadan önce kontrol edin:

```sh
dig +short ent-challange.fairdose.net
dig +short ent-challange-api.fairdose.net
```

İki komut da instance IPv4 adresini göstermelidir.

## 3. Docker kurulumu

Instance'a SSH ile bağlanın. Repodaki bootstrap scriptini çalıştırın:

```sh
chmod +x example/vultr/scripts/*.sh
./example/vultr/scripts/bootstrap-ubuntu.sh
```

Script Docker'ın resmi Ubuntu apt repository'sini kullanır ve Docker Engine, Buildx ile Compose
pluginini kurar. Kullanıcı Docker grubuna eklendiyse SSH oturumunu kapatıp yeniden açın.

## 4. Kaynak kodu yerleştirme

```sh
sudo mkdir -p /opt/ent-challange
sudo chown "$USER":"$USER" /opt/ent-challange
git clone --recurse-submodules \
  https://github.com/Fairdose/enteksis_code_challenge.git \
  /opt/ent-challange
cd /opt/ent-challange
```

Güncellemelerde umbrella repo ve pinlenmiş submodule commitlerini birlikte alın:

```sh
git pull --ff-only
git submodule update --init --recursive
```

## 5. Secret yapılandırması

```sh
cd /opt/ent-challange/example/vultr
cp .env.example .env
openssl rand -hex 32
chmod 600 .env
```

Üretilen hex değeri `.env` içindeki `POSTGRES_PASSWORD` alanına yazın. Gerçek `.env`, TLS
dosyaları ve database yedekleri Git tarafından ignore edilir. `.env` dosyasını repoya eklemeyin.

## 6. İlk TLS ve deploy

Port 80 başka bir süreç tarafından kullanılmamalı ve iki DNS kaydı instance'a çözülmelidir:

```sh
cd /opt/ent-challange
./example/vultr/scripts/init-tls.sh
```

Bu script sırasıyla PostgreSQL, migration, Go API ve client'ı build eder; iki alan adı için tek
Let's Encrypt sertifikası alır ve TLS Nginx gateway'i başlatır.

Sonraki deploylar:

```sh
./example/vultr/scripts/deploy.sh
```

## 7. Sertifika yenileme

Önce dry-run çalıştırın:

```sh
./example/vultr/scripts/renew-certificates.sh --dry-run
```

Systemd timer örneğini kurmak için repo `/opt/ent-challange` altında olmalıdır:

```sh
sudo install -m 0644 \
  example/vultr/systemd/ent-challange-certbot-renew.service \
  /etc/systemd/system/
sudo install -m 0644 \
  example/vultr/systemd/ent-challange-certbot-renew.timer \
  /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now ent-challange-certbot-renew.timer
systemctl list-timers ent-challange-certbot-renew.timer
```

## 8. PostgreSQL yedeği

```sh
./example/vultr/scripts/backup-database.sh
```

Yedekler `example/vultr/backups/` altında, yalnızca sahibi tarafından okunabilir PostgreSQL custom
format dosyaları olarak oluşturulur. Instance kaybına karşı bu dosyaları ayrıca instance dışında
saklayın veya Vultr automatic backup/snapshot özelliğini etkinleştirin.

## 9. Doğrulama

```sh
curl --fail https://ent-challange-api.fairdose.net/health
curl --head https://ent-challange.fairdose.net
docker compose --env-file example/vultr/.env \
  --file example/vultr/compose.yaml ps
```

- Form gönderimi yalnızca API `201 Created` döndüğünde başarılı görünmelidir.
- `https://ent-challange.fairdose.net/admin` doğrudan ve sayfa yenilemesinden sonra açılmalıdır.
- Admin girişi `admin` / `123456admin` ile çalışmalıdır.
- Form kaydı admin listesinde görünmeli ve container yeniden başlatıldıktan sonra korunmalıdır.

## Operasyon komutları

```sh
# Loglar
docker compose --env-file example/vultr/.env \
  --file example/vultr/compose.yaml logs --follow

# Durum
docker compose --env-file example/vultr/.env \
  --file example/vultr/compose.yaml ps

# Containerları durdur; PostgreSQL volume'ünü koru
docker compose --env-file example/vultr/.env \
  --file example/vultr/compose.yaml down
```

`down --volumes` kullanmayın; bu seçenek PostgreSQL verisini siler.
