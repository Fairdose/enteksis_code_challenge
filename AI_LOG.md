# AI_LOG

Bu üst repo, client ve backend teslimlerini Git submodule olarak bir araya getirir. Ayrıntılı araç,
karar ve doğrulama kayıtları ilgili repolarda tutulur:

- [Client AI_LOG](https://github.com/Fairdose/enteksis_client/blob/main/AI_LOG.md)
- [Backend AI_LOG](https://github.com/Fairdose/enteksis_backend/blob/main/AI_LOG.md)

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
- Yeni bir i18n paketi eklemek yerine mevcut typed Türkçe/İngilizce mesaj ve persisted locale yapısı
  admin route'larını kapsayacak şekilde tamamlandı. Playwright masaüstü matrisi Chromium, Firefox ve
  WebKit'e genişletildi; public ve admin girişine axe-core WCAG A/AA kontrolleri eklendi.
- Kullanıcı/session/RBAC/parola sıfırlama, özel SMTP veya Mailpit+mTLS ve sunucu taraflı gelişmiş
  arama/sayfalama seçenekleri değerlendirildi. Operasyon ve ürün kararlarını challenge kapsamının
  ötesine taşıdıkları için uygulanmadı; gerekçeleri README dosyalarında açıklandı.

## Doğrulama özeti

- Frontend lint, TypeScript, production build ve Vitest kontrolleri çalıştırıldı.
- Go testleri ve vet kontrolü çalıştırıldı.
- Docker Desktop üzerinde client, API ve PostgreSQL healthcheck'leri geçti.
- Playwright ile public formun gerçek PostgreSQL kaydı ve admin giriş/liste/detay/`mailto:` akışı
  uçtan uca doğrulandı.
- GitHub Actions doğrulaması gerçek Docker stack üzerinde Chromium, Firefox ve WebKit akışları ile
  otomatik WCAG A/AA kontrollerini çalıştırır ve başarısızlıkta da integration containerlarını
  kapatır.
- İlk axe taraması süreç ve footer ikincil metinlerinde yetersiz kontrast buldu. Renkler AA eşiğini
  geçecek şekilde düzeltildi ve iki sayfa taraması ihlalsiz tekrarlandı.
- Vultr production Compose modeli çözümlendi; Bash scriptleri sözdizimi kontrolünden, Go ve Vue
  image'ları gerçek Docker build'inden, host Nginx yapılandırması ise `nginx -t` kontrolünden geçti.
  Yalnızca `80/443` portlarının internete açık olduğu ayrıca doğrulandı.

Çalışma tek Codex oturumunda alt ajan kullanılmadan gerçekleştirildi.
