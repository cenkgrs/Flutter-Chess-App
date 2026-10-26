# Evde/Mac'te devam notu — 16 Ekim 2026

## App Store Connect durumu

- Apple Developer hesabı onaylandı.
- App Store Connect uygulama kaydı oluşturuldu:
  - Ad: `ROK Chess`
  - Primary language: `English (U.S.)`
  - Bundle ID: `com.silveroaktech.rok`
  - SKU: `rok-ios-001`
  - Sürüm: `1.0` — Prepare for Submission
- Promotional Text girildi:
  `Play online, sharpen your skills with puzzles, and learn with a built-in chess assistant.`
- Product page header görseli hazır:
  `assets/store/rok-chess-header-3840x1646.png` (3840 × 1646 PNG).
- Projeye özel, dış lisans gerektirmeyen ses efektleri eklendi:
  `game_start.wav`, `victory.wav` ve taş hareketi için
  `assets/audio/piece_move_1…5.wav` (Kenney Impact Sounds `impactWood_light`,
  CC0; her hamlede bir öncekinden farklı bir varyasyon çalınır). Taş yemede
  iki hafif vuruşun karışımı `piece_capture.wav` çalınır.
- Taşlar eski karesinden yeni karesine kayarak gider
  (`lib/widgets/move_animation.dart`); sürüklenip bırakılan hamle kaymaz.
  Bulmaca ve düelloda oyuncunun hamlesi sunucu yanıtı beklenmeden gösterilir,
  rakip cevabı kısa bir aradan sonra ayrıca kayar.
  Offline/online maç, bulmaca ve bulmaca düellosu olaylarına bağlandı. Profilde
  dört dilde kalıcı bir `Ses efektleri` anahtarı bulunuyor. iOS sessiz anahtarı
  dikkate alınıyor; ses hataları oynanışı durdurmuyor.
- Search Results görseli zorunlu değil; boş bırakılabilir. Apple bu durumda
  gerçek uygulama ekran görüntülerini kullanır.
- Üstte görünen EU Digital Services Act `trader status` uyarısı yayından önce
  tamamlanmalı. Ticari durum ve Apple'da yayımlanacak iletişim bilgileri hesap
  sahibince doğrulanmalı; kişisel doğrulama bilgilerini repoya yazmayın.

## App Store metinleri

Subtitle:

```text
Play, Solve, Improve
```

Keywords:

```text
online,puzzles,board game,strategy,premove,training,duel,multiplayer,tactics
```

Description:

```text
Play chess your way with ROK Chess.

Challenge players online, continue interrupted matches without losing your position, and improve your game through puzzles and competitive puzzle duels.

FEATURES

• Play online chess with reliable match recovery
• Continue active games after reconnecting
• Solve chess puzzles and compete in puzzle duels
• Practice against the computer
• Get guidance from the built-in chess assistant
• Use premoves for faster online play
• Draw arrows and mark squares on the board
• Choose from English, Turkish, German, and Russian
• Review your games and track your progress

Whether you want a quick match, focused puzzle practice, or a deeper look at your position, ROK Chess keeps everything in one clean chess experience.
```

- Support URL: `https://cenkgrs.github.io/rok-site/support.html`
- Privacy Policy URL: `https://cenkgrs.github.io/rok-site/privacy.html`
- Marketing URL: şimdilik boş bırakılabilir.
- Copyright: `2026 Cenk Gürses`

## Mac ve ekran görüntüsü akışı

1. Mac'te bu repoyu güncelleyin, bağımlılıkları alın ve kontrolleri çalıştırın.
2. Gerçek iPhone 14 Pro'da release build çalıştırın. 14 Pro ekran görüntüleri
   App Store'un kabul ettiği `1179 × 2556` ölçüsündedir.
3. Ana menü, online maç, bulmaca/bulmaca düellosu, asistan ve profil/dil olmak
   üzere beş temiz dikey ekran alın. Kişisel e-posta, test verisi veya debug
   etiketi görünmesin.
4. Görselleri boyutlandırmadan App Store Connect → App Previews and Screenshots
   → iPhone with Dynamic Island bölümüne yükleyin.
5. Fiziksel iPhone'da başlangıç, hamle ve galibiyet seslerini; Profil → Ses
   efektleri kapalıyken sessizliği; ayrıca iPhone'un sessiz anahtarını test edin.
   Online maçta yeniden bağlanma/arka plandan dönüş sırasında eski hamle veya
   sonuç sesinin tekrar çalmadığını doğrulayın.

Ekran görüntüsü almak için telefonu bağladıktan sonra:

```sh
flutter devices
flutter run --release \
  --dart-define-from-file=supabase.env.json \
  --dart-define=ROK_SOURCE_REVISION="$(git rev-parse HEAD)"
```

Canlı reklam bayrağını bu çalıştırmaya eklemeyin.

İlk sürüm iPhone-only: `TARGETED_DEVICE_FAMILY = "1"`. iPad ekran görüntüsü
gerekmez. Android sonraki aşamada yayınlanacak.

## Bu push'ta tamamlananlar

- Online maçta bağlantı kopması, arka plandan dönüş, yeniden senkronizasyon ve
  sunucu-otoriteli saatler.
- Ana menüden yarım kalan maça dönüş.
- Bulmaca düellosunda timeout/ayrılma sonucu ve çift rating yazım koruması.
- Canlı Supabase geçici hesap silme testi: silme onaylandı, tekrar giriş HTTP
  400 ile reddedildi. Geçici hesap artık mevcut değil.
- Profilde Gizlilik Politikası ve Destek bağlantıları; iki URL de HTTP 200.
- iPhone SE boyutunda Almanca/Rusça ve klavye taşma testleri.
- ROK + bağlı Stockfish için GPL-3.0-or-later bildirimi, doğru podspec lisansı,
  NNUE SHA-256 doğrulaması ve uygulama içi tam kaynak bağlantısı.
- Hamle, yeni oyun ve galibiyet sesleri; kalıcı ses aç/kapat tercihi ve dört dil
  metinleri. `audioplayers 6.8.1` kullanılıyor.

## Evde release almadan önce

```sh
git pull origin master
flutter pub get
flutter test
flutter analyze
```

Bu push'un 40 karakterli commit kimliğini alın:

```sh
git rev-parse HEAD
bash tools/verify_release_source.sh "$(git rev-parse HEAD)"
```

Kontrol geçerse iOS release'i kaynak revizyonunu gömerek alın:

```sh
flutter build ipa --release \
  --dart-define-from-file=supabase.env.json \
  --dart-define=ROK_SOURCE_REVISION="$(git rev-parse HEAD)"
```

`ROK_SOURCE_REVISION` verilmezse release uygulaması başlangıçta durur. Profil →
Açık kaynak lisansları → Tam kaynak kodunu aç bağlantısının bu commit'i açtığını
TestFlight build'inde bir kez kontrol edin.

Yeni Supabase migration'ları canlıya uygulandı; tekrar uygulamak gerekmiyor.
Fiziksel iPhone Stockfish testi kullanıcı tarafından tamamlandı.

## Günlük bulmaca kurulumu

Bu branch `supabase/migrations/20261017120000_daily_puzzle.sql` migration'ını
ekler. Migration 17 Ekim 2026'da canlı Supabase'e uygulandı; tekrar
çalıştırmayın (tablolar zaten var, ikinci çalıştırma hata verir). Yeni bir
ortam kurarken:

1. Supabase → SQL Editor'da `20261017120000_daily_puzzle.sql` dosyasının
   tamamını tek seferde çalıştırın.
2. Kontrol: `select public.daily_puzzle_today();` İstanbul tarihini vermeli.
   (Fonksiyon `authenticated` rolüne kapalıdır; SQL Editor'da çalışır.)
3. Uygulamanın bu branch'ten alınmış build'inde ana menüde **Günlük bulmaca**
   satırı görünür. Giriş yapmış kullanıcıda "Bugün çözülmedi · Seri: 0 gün"
   yazmalı; bulmacayı çözünce "Bugün çözüldü · Seri: 1 gün" olmalı.

Sıfırdan kurulumda sıra: `supabase/migrations` altındaki tüm dosyalar dosya
adı sırasıyla (`20261012120000_puzzles.sql` sonrası iki seed dosyası), en son
`20261017120000_daily_puzzle.sql`. Seed'ler daily migration'dan sonra da
yüklenebilir; günün bulmacası ilk istekte seçilir.

Kurallar:

- Gün `Europe/Istanbul` takvimine göre değişir (gece 00:00). Kullanıcı kitlesi
  Türkiye öncelikli olduğu için UTC (03:00'te değişim) yerine bu seçildi.
- Günün bulmacası ilk istekte `puzzles` havuzundan deterministik seçilir ve
  `daily_puzzles` tablosuna sabitlenir: önce hiç günlük olmamış bulmacalar,
  sonra en uzun süredir kullanılmayan; eşitlikte `md5(gün || fingerprint)`.
  Sonradan eklenen seed geçmiş/bugünkü seçimi değiştirmez. Havuz şu an 56
  bulmaca; 56 gün sonra en eski seçimler sırayla tekrar eder. Günün zorluğu da
  seçimde dondurulur, herkes aynı puan eğrisini görür.
- Kullanıcı başına gün başına tek deneme (`daily_puzzle_attempts`), süre
  `started_at` ile sunucuda tutulur. Çözüm istemciye gönderilmez; yalnızca
  kabul edilen hamle, rakip cevabı ve konum döner. Çözümü gösterince deneme
  biter ve çözüm o kullanıcıya açılır.
- Puan normal bulmacadaki formülle `puzzle_ratings.points` hanesine eklenir
  (sıralamaya yansır). Bulmaca Elo'su ve `played` değişmez. İpucu seriyi korur
  ama puanı sıfırlar; yanlış deneme puanı azaltır.
- Seri (`daily_puzzle_streaks`): art arda çözülen gün sayısı ve en uzun seri.
  Bir gün kaçarsa görünen seri 0 olur; çözümü göstermek o günün serisini
  sıfırlar. Gece yarısını geçen aktif deneme `expired` olur, puan/seri vermez.
- Hesap silmede yeni tablolar `auth.users` üzerinden cascade ile silinir.

Yerel SQL testi (yalnızca geçici PostgreSQL; canlıda çalıştırmayın):
`tools/test_bootstrap.sql`, ardından tüm migration'lar sırasıyla, ardından
`tools/daily_puzzle_test.sql`. Test rollback ile biter.

## 1.0 yayın akışı (26 Ekim)

### Çözülenler

- **Dağıtım engeli kalktı.** Google Mobile Ads SDK ilk sürümden çıkarıldı.
  Bağımlılıkların geri kalanı (chess, audioplayers, shared_preferences,
  supabase_flutter, url_launcher, http, provider) MIT/BSD; GPL olan tek
  bileşen Stockfish ve o uygulamanın kendi lisansını zaten belirliyor.
  Reklam, motor sunucuya taşındıktan sonra 1.1'de değerlendirilecek.
- Dört dil için çevrilmemiş metin taraması yapıldı; her UI metni `tr()`
  içinden geçirilerek doğrulandı.
- İlk kullanım ipuçları asistan ve tahta araçları için duruyor. Ön hamle
  artık ipucu değil, başlıktaki kalıcı gösterge.

### Yayından önce yapılacaklar

1. **Kaynağı herkese açık hale getir.** Sürüm GPL-3 olduğu için release
   build, dağıtılan binary ile birebir eşleşen herkese açık commit'i
   gömmek zorunda. Dal master'a alınıp GitHub'a push edilmeden
   `tools/verify_release_source.sh` geçmez ve uygulama release modunda
   açılışta durur.
2. **Supabase migration'ları canlıya uygula** (sırayla):
   - `supabase/migrations/20261024120000_duel_spectate.sql`
   - `supabase/migrations/20261024130000_daily_feature_limits.sql`
   İkisi de uygulanmadan uygulama çalışır ama düello izleme boş bekleme
   kutusuna düşer ve hesap başına günlük limit işlemez.
3. **App Store Connect abonelik kurulumu.** Uygulamada ROK Premium ekranı
   var; ürünler mağazada yoksa ekran "satışa açık değil" yazar. Apple'ın
   eksik çalışan bir satın alma akışını reddetme riski olduğundan ürünler
   bu sürümle birlikte incelemeye verilmeli. Ayrıntılar ve ürün
   kimlikleri `SUBSCRIPTIONS.md` içinde. Ücretli uygulama sözleşmesi ile
   banka/vergi bilgileri de tamamlanmalı.
4. **EU trader status** doğrulaması.
5. **Ekran görüntüleri**: gerçek iPhone'da release build, beş dikey ekran
   (1179 × 2556).
6. App Store Connect metadata ve review notes.

### Doğrulanmamış kalanlar

- Düello izleme canlı iki cihazda denenmedi.
- StoreKit satın alma, yenileme, geri yükleme, iptal ve iade akışları
  Apple test ortamında denenmedi. Dart testinin geçmesi bunu karşılamaz.
- Dokuz taş seti × dört tahta temasının tamamı kontrast için taranmadı.
- Almanca/Rusça tüm ekran smoke turu.

### Release komutları

```sh
git rev-parse HEAD
bash tools/verify_release_source.sh "$(git rev-parse HEAD)"
flutter build ipa --release \
  --dart-define-from-file=supabase.env.json \
  --dart-define=ROK_SOURCE_REVISION="$(git rev-parse HEAD)"
```

Gizlilik: https://cenkgrs.github.io/rok-site/privacy.html

Destek: https://cenkgrs.github.io/rok-site/support.html
