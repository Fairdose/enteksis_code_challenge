# Vultr production example

Bu dizin, Ent Challange uygulamasını tek bir Debian 13 veya Ubuntu 24.04 LTS Vultr Cloud Compute instance'ında
çalıştırmak için örnek otomasyon içerir. Host Nginx yalnızca `80/443` portlarını yayınlar. Vue ve
Go container'ları yalnızca loopback portlarına bağlanır; PostgreSQL host portu internete açılmaz.

## Mimari

```text
Internet
   │
   ▼
Host Nginx :80/:443
   ├── ent-challange.fairdose.net ──────► 127.0.0.1:8081 ─► Vue/nginx :8080
   └── ent-challange-api.fairdose.net ──► 127.0.0.1:8082 ─► Go API :8080 ─► PostgreSQL :5432
```

Certbot ilk sertifikayı webroot HTTP-01 ile alır. Host Nginx, `/.well-known/acme-challenge/`
yolunu ortak webroot'tan sunar; sonraki yenilemeler servisi durdurmadan yapılır.

## 1. Vultr instance ve firewall

- Debian 13 veya Ubuntu 24.04 LTS instance oluşturun.
- SSH key kullanın; parola ile root girişini kapatmanız önerilir.
- Vultr Firewall inbound kuralları:

| Protokol | Port | Kaynak |
| --- | --- | --- |
| TCP | 22 | Yalnızca yönetim IP'niz |
| TCP | 80 | Her yer |
| TCP | 443 | Her yer |

`5432`, `8081`, `8082` ve `5173` portlarını açmayın. Docker yalnızca `127.0.0.1:8081` ve
`127.0.0.1:8082` adreslerine publish eder; public trafiği host Nginx karşılar.

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

## 3. Sunucu kurulumu

Instance'a SSH ile bağlanın. Repodaki bootstrap scriptini çalıştırın:

```sh
chmod +x example/vultr/scripts/*.sh
./example/vultr/scripts/bootstrap-ubuntu.sh
```

Script dağıtıma uygun resmi Docker apt repository'sini kullanır; Docker Engine, Buildx, Compose,
Nginx ve Certbot'u kurar. Kullanıcı Docker grubuna eklendiyse SSH oturumunu kapatıp yeniden açın.

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

İki DNS kaydı instance'a çözülmelidir:

```sh
cd /opt/ent-challange
./example/vultr/scripts/init-tls.sh
```

Bu script sırasıyla HTTP Nginx site dosyasını kurar, UFW üzerinde `80/443` portlarını açar,
PostgreSQL, migration, Go API ve client'ı build eder; iki alan adı için tek Let's Encrypt
sertifikası alır ve host Nginx'i HTTPS konfigürasyonuna geçirir.

Sonraki deploylar:

```sh
./example/vultr/scripts/deploy.sh
```

## 7. GitHub Actions CI/CD

Root repository'deki `Validate and deploy` workflow'u her pull request ve `main` push'unda client,
backend, shell scriptleri ve production Compose dosyasını doğrular. Pull request dışındaki başarılı
çalışmalar GitHub `production` environment'ı üzerinden VPS'e exact commit SHA deploy eder.

Deploy job'u repository-scoped, `ent-challange-production` etiketli self-hosted runner üzerinde
çalışır. Böylece VPS SSH portunu GitHub-hosted runner IP aralıklarına açmak gerekmez. GitHub'da
`Settings > Actions > Runners > New self-hosted runner` üzerinden tek kullanımlık registration
token oluşturun ve VPS üzerinde çalıştırın:

```sh
read -r -s -p 'GitHub registration token: ' RUNNER_REGISTRATION_TOKEN
export RUNNER_REGISTRATION_TOKEN
./example/vultr/scripts/install-github-runner.sh
unset RUNNER_REGISTRATION_TOKEN
```

Token girdikten sonra Enter'a basın. Token'ı repoya veya shell history'ye yazmayın. Kurulum runner'ı `dev_fairdose` kullanıcısı adına
systemd servisi olarak başlatır. Self-hosted runner yalnızca production deploy job'u için kullanılır;
pull request doğrulamaları GitHub-hosted runner'da kalır.

Production variable'ı `VPS_DEPLOY_ENABLED=true` olmadan deploy job'u çalışmaz. Bu anahtarı ancak
ilk TLS kurulumu ve health check başarılı olduktan sonra etkinleştirin. İsterseniz GitHub
`production` environment'ına required reviewer ekleyebilirsiniz.

İlk CI deploy'undan önce `/opt/ent-challange` checkout'u ve `.env` dosyası elle hazırlanmış,
Docker grup üyeliği yeni SSH oturumunda etkinleşmiş ve TLS kurulumu tamamlanmış olmalıdır.
`deploy-revision.sh` yalnızca `origin/main` geçmişindeki SHA'ları kabul eder, aynı anda tek deploy
çalıştırır ve health check başarısızlığında önceki revision'a rollback dener.

## 8. Sertifika yenileme

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

## 9. PostgreSQL yedeği

```sh
./example/vultr/scripts/backup-database.sh
```

Yedekler `example/vultr/backups/` altında, yalnızca sahibi tarafından okunabilir PostgreSQL custom
format dosyaları olarak oluşturulur. Instance kaybına karşı bu dosyaları ayrıca instance dışında
saklayın veya Vultr automatic backup/snapshot özelliğini etkinleştirin.

## 10. Doğrulama

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
