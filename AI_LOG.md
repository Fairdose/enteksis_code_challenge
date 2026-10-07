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
- Yönetim ekranı `/admin` altında nested route'larla kuruldu. E-posta yanıtı SMTP yerine `mailto:`
  olarak uygulandı; admin kimlik bilgileri son güvenlik kontrolünde environment secret'a taşındı.
- Ürün ve runtime kimliği `Ent Challange` olarak değiştirildi. Kaynak repo ve submodule yolları
  mevcut GitHub adresleriyle uyumluluk için korundu; canlı ortam için `*.fairdose.net` planlandı.
- Ücretsiz çoklu servis hosting planı kullanıcı kararıyla kaldırıldı. Canlı ortam; host Nginx ve
  Certbot'un TLS/reverse proxy sağladığı, Vue, Go API ve PostgreSQL'in aynı Vultr instance üzerinde
  izole containerlarda çalıştığı tek sunucu mimarisine dönüştürüldü.
- Son değerlendirme kontrolünde admin kimlik bilgileri repodan çıkarıldı, API health kontrolü
  PostgreSQL bağlantısını kapsayacak şekilde güçlendirildi ve Playwright akışları CI kapısı yapıldı.

## Doğrulama özeti

- Frontend lint, TypeScript, production build ve Vitest kontrolleri çalıştırıldı.
- Go testleri ve vet kontrolü çalıştırıldı.
- Docker Desktop üzerinde client, API ve PostgreSQL healthcheck'leri geçti.
- Playwright ile public formun gerçek PostgreSQL kaydı ve admin giriş/liste/detay/`mailto:` akışı
  uçtan uca doğrulandı.
- GitHub Actions doğrulaması gerçek Docker stack üzerinde dokuz Playwright senaryosunu çalıştırır
  ve başarısızlıkta da integration containerlarını kapatır.
- Vultr production Compose modeli çözümlendi; Bash scriptleri sözdizimi kontrolünden, Go ve Vue
  image'ları gerçek Docker build'inden, host Nginx yapılandırması ise `nginx -t` kontrolünden geçti.
  Yalnızca `80/443` portlarının internete açık olduğu ayrıca doğrulandı.

Çalışma tek Codex oturumunda alt ajan kullanılmadan gerçekleştirildi.
