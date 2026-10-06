# Ent Challange

Ent Challange hizmet landing page'i, hizmet talep API'si ve Docker tabanlı PostgreSQL ortamı.

## Repolar

- Client: <https://github.com/Fairdose/enteksis_client>
- Backend: <https://github.com/Fairdose/enteksis_backend>

Bu umbrella repo iki projeyi Git submodule olarak takip eder. Klonlarken:

```sh
git clone --recurse-submodules https://github.com/Fairdose/enteksis_code_challenge.git
```

## Çalıştırma

Her iki alt projedeki `run.sh` aynı Compose ortamını yönetir:

```sh
./enteksis_client/run.sh
# veya
./enteksis_backend/run.sh
```

- Client: `http://localhost:5173`
- Admin: `http://localhost:5173/admin`
- API: `http://localhost:8080`
- PostgreSQL: `localhost:5432`

Windows üzerinde scripti Git Bash veya WSL ile çalıştırın.

Admin için statik kullanıcı adı `admin`, şifre `123456admin` değeridir. Bu bilgiler challenge
gereği sabittir ve üretim ortamı için uygun değildir.

## Test

```sh
./enteksis_client/run.sh start
cd enteksis_client
pnpm install
pnpm exec playwright install chromium
pnpm test:e2e
```

Backend testleri için `cd enteksis_backend && go test ./...` komutunu kullanın. Ayrıntılı kurulum,
mimari kararlar, bilinen eksikler ve AI doğrulama kayıtları alt repoların README ve AI_LOG
dosyalarında yer alır.

## Vultr canlı ortam örneği

Client, Go API, PostgreSQL, TLS ve host Nginx reverse proxy'yi tek bir Vultr instance üzerinde
çalıştıran örnek Compose yapısı ile otomasyon scriptleri
[`example/vultr`](example/vultr/README.md) dizinindedir. Canlı ortamda yalnızca `80/443`
portları yayınlanır; uygulama servisleri yalnızca loopback'e bağlanır ve PostgreSQL özel Docker
ağında kalır.
