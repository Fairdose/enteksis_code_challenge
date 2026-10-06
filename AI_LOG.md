# AI_LOG

Bu üst repo, client ve backend teslimlerini Git submodule olarak bir araya getirir. Ayrıntılı araç,
karar ve doğrulama kayıtları ilgili repolarda tutulur:

- [Client AI_LOG](enteksis_client/AI_LOG.md)
- [Backend AI_LOG](enteksis_backend/AI_LOG.md)

## Önemli kararlar

- Supabase yerine değerlendiricinin bilgisayarında çalışan Docker PostgreSQL kullanıldı.
- GitHub Pages yerine client, API ve PostgreSQL'i birlikte başlatan aynı `run.sh` iki repoya eklendi.
- Frontend, `example_infra` referansındaki nested router, layout, view, component ve store ayrımına
  uyarlandı.
- Yönetim ekranı `/admin` altında nested route'larla kuruldu. `admin` / `123456admin` bilgileri
  kullanıcı kararıyla backend'de statik tutuldu; e-posta yanıtı SMTP yerine `mailto:` olarak
  uygulandı.

## Doğrulama özeti

- Frontend lint, TypeScript, production build ve Vitest kontrolleri çalıştırıldı.
- Go testleri ve vet kontrolü çalıştırıldı.
- Docker Desktop üzerinde client, API ve PostgreSQL healthcheck'leri geçti.
- Playwright ile public formun gerçek PostgreSQL kaydı ve admin giriş/liste/detay/`mailto:` akışı
  uçtan uca doğrulandı.

Çalışma tek Codex oturumunda alt ajan kullanılmadan gerçekleştirildi.
