# Taş setleri

Profil → Tahta görünümü → Taşlar listesindeki setlerin görselleri. Her set
kendi klasöründe durur ve `lib/theme/board_theme.dart` içindeki `pieceSets`
listesine bir `PieceSet` olarak kaydedilir.

Bu klasördeki `README.md` ve `PROMPT.md` uygulamaya paketlenmez: `pubspec.yaml`
alt klasörleri tek tek listeler, bu kökü listelemez.

## Mevcut setler

| Klasör | Ad | Tür |
|---|---|---|
| — | Ahşap | siluet, kodda renklendirilir |
| `glass` | Cam | hazır görsel |
| `ivory_ebony` | Fildişi ve Abanoz | hazır görsel |
| `marble_basalt` | Mermer ve Bazalt | hazır görsel |
| `porcelain_obsidian` | Porselen ve Obsidyen | hazır görsel |
| `silver_bronze` | Gümüş ve Bronz | hazır görsel |
| `art_deco` | Art Deco | hazır görsel |
| `minimal_matte` | Sade Mat | hazır görsel |
| `ice_lava` | Buz ve Lav | hazır görsel |

Ahşap set `lib/images/wood/` altındadır ve tek kanallı siluetleri iki renge
`BlendMode.modulate` ile boyar (`PieceArt.silhouette`). Diğerlerinin görselleri
olduğu gibi çizilir (`PieceArt.painted`).

## Yeni set eklemek

`assets/pieces/<id>/` klasörü aç, 12 dosyayı koy, `pubspec.yaml`'a klasörü
ekle, `board_theme.dart`'ta bir `PieceSet` tanımla ve `pieceSets` listesine
al. Adı Türkçe yaz ve `lib/l10n/translations.dart`'a üç dilde çevirisini
ekle. Test (`test/board_theme_test.dart`) listeyi gezdiği için yeni set
otomatik olarak kapsama girer.

Klasör eksik ya da yarım olursa set listede görünmez: `BoardTheme.load()` her
setin beyaz şahını `rootBundle`'dan yüklemeyi dener, bulamazsa o seti gizler.
Seçili set kaybolursa ahşaba düşülür.

## Beklenen dosyalar

Her set klasöründe tam 12 dosya, bu adlarla:

```
w_pawn.png  w_rook.png  w_knight.png  w_bishop.png  w_queen.png  w_king.png
b_pawn.png  b_rook.png  b_knight.png  b_bishop.png  b_queen.png  b_king.png
```

`w_` beyaz, `b_` siyah taraftır. Adlar `PieceSet.assetFor` ile birebir
eşleşmeli; biri eksikse o kare boş çizilir.

## Teknik koşullar

- **Boyut:** 512 × 512 piksel, kare. iPhone'da bir kare en çok ~147 pt × 3 =
  ~441 piksel olduğu için 512 yeterli; 1024 uygulamayı boşuna büyütür.
- **Format:** alfa kanallı PNG. Arka plan tamamen saydam olmalı (köşelerde
  alfa 0).
- **Yerleşim:** taş yatayda ortalanmış (merkez ≈ 255) ve **paylaşılan bir
  taban çizgisine** oturmuş olmalı — tabanın alt kenarı ≈ 479, yani altta
  ~%6 boşluk. Dikeyde ortalama; şah en uzun, piyon en kısa olmalı.
- **Ölçek:** PNG çerçevesindeki boşluk ekrandaki boyutu belirlemez.
  `lib/theme/piece_geometry.dart` her görselin saydam kenarlar dışındaki
  sınırlarını tutar. `BoardPieceArt`, taş türüne göre ortak bir çizim alanına
  yerleştirir: piyon %68, at %82, fil %84, kale %77, vezir %90, şah %94 yükseklik.
  Taban hepsinde %97 hizasındadır. Genişlikler de küçük ekranlarda okunacak
  biçimde taş türüne göre dengelenir. Yeni görselde bu sınırları güncelleyin.
  Standart ahşap piyon, kendi özgün boyutundan %10 küçük çizilir.
- **Gölge:** görsele gölge **gömmeyin** ve kodda da eklemeyin. Bir
  `BoxDecoration` gölgesi taşın siluetini değil widget'ın dikdörtgenini
  çizer; bu, her karede görünür bir kutu bırakır. Denendi, geri alındı.
- **Dosya boyutu:** set başına ~400 KB'ı geçmesin. Gerekirse
  `pngquant --quality 70-90`.

## Kontrol listesi

Yeni set eklendikten sonra dört tahta temasının hepsinde bak:

- **Ahşap** ve **Mermer**: siyah taş açık karede kayboluyor mu?
- **Arduvaz** ve **Buz**: beyaz taş açık karede kayboluyor mu?
- Şah ile vezir ilk bakışta ayırt ediliyor mu?
- At iki renkte de aynı yöne bakıyor mu?

Görselleri üretmek için [PROMPT.md](PROMPT.md).
