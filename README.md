# Satranç Atölyesi

Flutter ile geliştirilmiş, çevrimdışı bilgisayara karşı oynanabilen satranç
prototipi.

## Prototip kapsamı

- Tam satranç kuralları: rok, geçerken alma, terfi, şah/mat, pat ve beraberlik
- Başlangıç, Orta ve İleri olmak üzere üç yerel yapay zekâ seviyesi
- Beyaz veya siyah taşları seçerek oynama
- Legal hamle işaretleri, hamle geçmişi ve PGN kopyalama
- Geri alma, tahtayı çevirme, yeniden başlatma ve teslim olma
- Telefon ve geniş ekranlara uyumlu Türkçe arayüz

## Çalıştırma

```sh
flutter pub get
flutter run
```

## Doğrulama

```sh
flutter analyze
flutter test
flutter build web --release
flutter build apk --debug
```

Web release çıktısı `build/web`, Android debug APK çıktısı ise
`build/app/outputs/flutter-apk/app-debug.apk` altında oluşur.

## Lisans ve release kaynağı

ROK ve uygulamaya doğrudan bağlı Stockfish motoru GPL-3.0-or-later altında
dağıtılır. Tam koşullar [COPYING.md](COPYING.md), motor ve NNUE ayrıntıları
[STOCKFISH_NOTICES.md](STOCKFISH_NOTICES.md) içindedir.

App Store/Play release'i, herkese açık kaynak deposundaki birebir 40 karakterli
commit belirtilmeden çalışmaz:

```sh
flutter build ipa --release \
  --dart-define=ROK_SOURCE_REVISION=<40-character-public-commit>
```

Derlemeden önce çalışma ağacının temiz, belirtilen revizyonun `HEAD` ile aynı ve
GitHub'da erişilebilir olduğunu doğrulayın. Uygulama içindeki Profil → Açık
kaynak lisansları sayfası doğrudan bu revizyona bağlanır.
