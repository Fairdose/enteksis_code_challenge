# AI_LOG

## Marka ve dil seçici düzeltmesi (14 Ekim 2026)

- Kullanıcı yönlendirmesiyle web arayüzünün görünür markası ve sayfa metaverisi yeniden `ent-challange` yapıldı; kanonik ürün PDF'sinin içeriği değiştirilmedi.
- Açılış ve yönetim başlığındaki dil düğmeleri, geçerli dili bayrakla gösteren ortak erişilebilir açılır seçiciye dönüştürüldü. Dil tercihi mevcut Pinia kalıcılığını kullanır.
- Vue typecheck/lint, dört Vitest testi ve üretim derlemesi geçti; Chromium/Firefox ile dil kalıcılığı, erişilebilirlik ve responsive kontrollerinden oluşan 10 hedefli Playwright çalıştırması geçti. Mobil menüde açılır seçici ayrıca gözle incelendi.

## İkinci faz — açılış sayfası görsel revizyonu (14 Ekim 2026)

- Kullanıcının isteğiyle üç uzman görev ayrıldı: güncel `2nd_phase` belgelerinden ürün/görsel brif çıkarma, Vue açılış sayfasına CSS derinlik ve hareket uygulama, responsive/erişilebilirlik testlerini güncelleme. Ana görev tasarım doğrulamasını, entegrasyonu ve yayını üstlendi.
- Kanonik tanıtım PDF'sindeki “Kim ne yapıyor, kimden ne bekleniyor, hangi iş gecikiyor?” sorusu ve Premium v5'in koyu lacivert, turkuaz, mavi, mor katmanlı görsel dili referans alındı. Yalnız V0.1'de çalışan iç ekip görevi, sorumluluk, kanıtlı teslim ve inceleme akışı anlatıldı; gelecek sürüm ajan/freelancer özellikleri canlı ürün gibi sunulmadı.
- Hareketli ürün maketi CSS perspektif/dönüşümlerle oluşturuldu. Animasyon yalnız dekoratif alanda tutuldu. 320–1440 px genişliklerde yatay taşma/CTA sınırları ve `prefers-reduced-motion` Chromium/Firefox üzerinde doğrulandı; yerel WebKit sistem paketleri eksik olduğundan üç motorlu sonuç CI'de alınacak.
- Vue typecheck, ESLint, Oxlint, dört Vitest testi, üretim derlemesi ve gerçek PostgreSQL'e bağlı 28 Chromium/Firefox/mobil Playwright çalıştırması geçti. Eski talep formu ile Benim Masam akışı regresyon testlerinde korundu.

## İkinci faz — Benim Masam V0.1 (14 Ekim 2026)

- Codex, `2nd_phase/00_CANONICAL_CURRENT` ve `2nd_phase/10_TECHNICAL_CURRENT` paketlerini karşılaştırıp görevden teslim kararına uzanan dikey akışı aynı iki alt repoda uyguladı. Ayrı bir ajan sürüsü çalıştırılmadı; araç ve doğrulama kayıtları aşağıdaki alt repo günlüklerindedir.
- Kanonik v2.1.1–v2.1.5 SQL dosyaları baytları değiştirilmeden backend'e kopyalandı; beş SHA-256 değeri manifestle eşleşti. Uygulamanın oturum gereksinimi için bunların sonuna `008_create_auth_sessions.sql` eklendi.
- Eski hizmet talebi akışı korundu. Yeni `/admin/masa`, sunucu kaynaklı yetki/sekiz dashboard grubu, kontrol listesi, kanıtlı teslim, inceleme, çoklu engel ve idempotent mutasyonlarla bağlandı. Kanonik Türkçe ürün PDF'si istemciye kopyalandı.
- Gerçek PostgreSQL üzerinde kanonik DDL ve bütünlük doğrulamaları; API durum, kanıtlı teslim, revizyon, idempotency, eski atama ve ekip oturumu kontrolleri geçti. Vue typecheck/lint/build, dört Vitest testi ve Chromium/Firefox masa akışları geçti. Yerel WebKit sistem bağımlılıkları eksik olduğundan bu motorun doğrulaması CI ortamına bırakıldı.


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
- İlk fazda değerlendirilen kullanıcı oturumu ve yetki modeli ikinci fazda görev akışı için
  uygulandı. Parola sıfırlama, özel SMTP ve sunucu taraflı gelişmiş arama/sayfalama kapsam dışında
  kaldı; sınırlar README dosyalarında açıklandı.

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

İlk faz çalışması tek Codex oturumunda alt ajan kullanılmadan gerçekleştirildi; bu kaydın üstündeki açılış sayfası revizyonu üç uzman görevle yürütüldü.
