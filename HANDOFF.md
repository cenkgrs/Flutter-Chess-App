# Evde devam notu — 15 Ekim 2026

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

- Canlı reklamları açmadan önce AdMob iOS unit/app ID, UMP mesajı, App Store
  privacy beyanı ve app-ads.txt son kontrolü. `ROK_LIVE_ADS=true` ancak bundan
  sonra verilmeli.
- Dört dil için kalan çevrilmemiş metin taraması ve Almanca/Rusça tüm ekran
  smoke turu.
- Asistan, tahta çizimi ve premove için bir kez gösterilen ilk kullanım ipuçları.
- App Store Connect metadata, ekran görüntüleri ve review notes.

Gizlilik: https://cenkgrs.github.io/rok-site/privacy.html

Destek: https://cenkgrs.github.io/rok-site/support.html
