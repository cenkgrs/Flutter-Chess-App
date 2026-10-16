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

Ekran görüntüsü almak için telefonu bağladıktan sonra:

```sh
flutter devices
flutter run --release \
  --dart-define-from-file=supabase.env.json \
  --dart-define=ROK_SOURCE_REVISION="$(git rev-parse HEAD)"
```

Canlı reklam bayrağını bu çalıştırmaya eklemeyin.

Proje şu anda `TARGETED_DEVICE_FAMILY = "1,2"` ile iPhone ve iPad destekliyor.
Bu şekilde kalırsa iPad 13\" ekran görüntüleri de gerekecek. Yalnızca fiziksel
iPhone test edildiği için ilk sürümü iPhone-only yapmak daha düşük riskli;
bunun için hedef ailesini değiştirmeden önce karar verilmeli.

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

## Hâlâ açık yayın işleri

- **Dağıtım engeli:** Uygulama Stockfish nedeniyle GPL-3.0-or-later olarak
  dağıtılıyor; bağlı proprietary Google Mobile Ads SDK ile uyumluluk henüz
  çözülmedi. Reklamın kapalı olması SDK bağlantısını ortadan kaldırmaz. App
  Store'a build göndermeden önce ilk sürümden reklam SDK'sını çıkarmak veya
  hukuk/uyum açısından kabul edilen farklı bir mimariye geçmek gerekiyor.
- Canlı reklamları açmadan önce AdMob iOS unit/app ID, UMP mesajı, App Store
  privacy beyanı ve app-ads.txt son kontrolü. `ROK_LIVE_ADS=true` ancak bundan
  sonra verilmeli.
- App Store Connect EU trader status doğrulaması.
- İlk build öncesi iPhone-only (`TARGETED_DEVICE_FAMILY = "1"`) veya universal
  iPhone+iPad (`"1,2"`) yayın kararı. Universal kalırsa iPad 13\" ekran
  görüntülerini Simulator'dan alın ve iPad düzenini smoke test edin.
- Dört dil için kalan çevrilmemiş metin taraması ve Almanca/Rusça tüm ekran
  smoke turu.
- Asistan, tahta çizimi ve premove için bir kez gösterilen ilk kullanım ipuçları.
- App Store Connect metadata, ekran görüntüleri ve review notes.

Gizlilik: https://cenkgrs.github.io/rok-site/privacy.html

Destek: https://cenkgrs.github.io/rok-site/support.html
