# Ent Challange

Ent Challange hizmet landing page'i, hizmet talep API'si ve Docker tabanlı PostgreSQL ortamı.

## Repolar

- Client: <https://github.com/Fairdose/enteksis_client>
- Backend: <https://github.com/Fairdose/enteksis_backend>

## Canlı ortam

- Uygulama: <https://ent-challange.fairdose.net>
- Admin: <https://ent-challange.fairdose.net/admin>
- API health: <https://ent-challange-api.fairdose.net/health>

Bu umbrella repo iki projeyi Git submodule olarak takip eder. Klonlarken:

```sh
git clone --recurse-submodules https://github.com/Fairdose/enteksis_code_challenge.git
```

## Çalıştırma

Her iki alt projedeki `run.sh` aynı Compose ortamını yönetir:

```sh
cp enteksis_backend/.env.example enteksis_backend/.env
# .env içindeki admin kimlik bilgilerini teslim kanalındaki değerlerle değiştirin.
./enteksis_client/run.sh
# veya
./enteksis_backend/run.sh
```

- Client: `http://localhost:5173`
- Admin: `http://localhost:5173/admin`
- API: `http://localhost:8080`
- PostgreSQL: `localhost:5432`

Windows üzerinde scripti Git Bash veya WSL ile çalıştırın.

Admin kimlik bilgileri kaynak kodda tutulmaz. `enteksis_backend/.env.example` dosyasını `.env`
olarak kopyalayıp `ADMIN_USERNAME` ve `ADMIN_PASSWORD` değerlerini teslim kanalıyla ayrıca sağlanan
bilgilerle doldurun.

## Test

```sh
./enteksis_client/run.sh start
cd enteksis_client
pnpm install
pnpm exec playwright install chromium firefox webkit
set -a; source ../enteksis_backend/.env; set +a
pnpm test:e2e
```

Backend testleri için `cd enteksis_backend && go test ./...` komutunu kullanın. Ayrıntılı kurulum,
mimari kararlar, bilinen eksikler ve AI doğrulama kayıtları alt repoların README ve AI_LOG
dosyalarında yer alır.

Playwright akışları Chromium, Firefox ve WebKit masaüstü motorlarında; mobil akışlar Chromium cihaz
emülasyonunda çalışır. Public sayfa ile admin girişinde axe-core tabanlı WCAG A/AA kontrolü CI
kapısının parçasıdır. Türkçe varsayılan dil olmakla birlikte public ve admin arayüzleri kalıcı
Türkçe/İngilizce tercihini destekler.

## Problem çözme kaydı

- Docker Desktop'ın harici disk migration bind mount'unu boş bağlaması gerçek form isteğinde `500`
  olarak yakalandı. Migration'lar özel PostgreSQL image'ına alındı ve mevcut/yeni volume üzerinde
  tekrar doğrulandı.
- Admin lifecycle E2E testi ilk çalışmada PostgreSQL parametre türü ve CORS method eksiklerini
  görünür kıldı. Sunucu loglarıyla teşhis edilen iki sorun açık SQL cast'i ve dar CORS allowlist ile
  düzeltildi; `Okundu`, `Cevaplandı`, restart sonrası kalıcılık ve silme yeniden test edildi.

## Katkı ve kaynak sınırı

Hazır landing page şablonu veya takım kodu kullanılmadı. `example_infra` yalnız dizin/router
yapısı için referans alındı. Vue, Pinia, Vue Router, pgx ve Playwright açık kaynak bağımlılıklardır;
AI ile alınan kararlar ve doğrulamalar ilgili `AI_LOG.md` dosyalarında ayrıştırılmıştır.

## Bilinen eksikler ve kapsam kararları

- Admin erişimi environment üzerinden sağlanan statik bilgiler ve HTTP Basic kullanır. Kullanıcı
  yönetimi, parola sıfırlama, RBAC ve sunucu taraflı session; challenge kapsamını ve bütçelenemeyen
  operasyon yükünü büyütmemek için eklenmedi. Üretim kapsamı genişletilseydi kullanıcı tablosu,
  hash'lenmiş parolalar, SMTP, reCAPTCHA ve 2FA birlikte tasarlanırdı.
- Yanıt akışı `mailto:` kullandığı için mesajın gönderildiği otomatik doğrulanamaz. Özel SMTP servisi
  bu projeye açılmadı; Mailpit, sunucu güvenliği ve mTLS çalışması kapsamı genişleteceğinden
  uygulanmadı. Yönetici cevap durumunu açıkça işaretler.
- Admin panelinde temel istemci araması ve durum filtresi vardır; sunucu taraflı sayfalama ve gelişmiş
  arama yoktur. Beklenen veri hacmi ve arama alanları netleşmeden indeks, arama algoritması ve cache
  tercihi yapmak spekülatif olacağı için küçük challenge veri setine eklenmedi.

## Vultr canlı ortam

Client, Go API, PostgreSQL, TLS ve host Nginx reverse proxy'yi tek bir Vultr instance üzerinde
çalıştıran production Compose yapısı ile otomasyon scriptleri
[`example/vultr`](example/vultr/README.md) dizinindedir. Canlı ortamda yalnızca `80/443`
portları yayınlanır; uygulama servisleri yalnızca loopback'e bağlanır ve PostgreSQL özel Docker
ağında kalır.
