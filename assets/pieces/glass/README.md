# Cam taş seti

Bu klasör, Profil → Tahta görünümü → Taşlar listesindeki **Cam** setinin
görsellerini tutar. Klasör eksik ya da yarım olduğu sürece set listede
görünmez: `BoardTheme.load()` beyaz şahın dosyasını `rootBundle`'dan
yüklemeyi dener, bulamazsa seti gizler ve ahşaba düşer
(`lib/theme/board_theme.dart`).

## Beklenen dosyalar

Tam 12 dosya, bu adlarla:

```
w_pawn.png  w_rook.png  w_knight.png  w_bishop.png  w_queen.png  w_king.png
b_pawn.png  b_rook.png  b_knight.png  b_bishop.png  b_queen.png  b_king.png
```

`w_` beyaz, `b_` siyah taraftır. Dosya adları `PieceSet.assetFor` ile birebir
eşleşmeli; biri eksikse o kare boş çizilir.

## Teknik koşullar

- **Boyut:** 512 × 512 piksel, kare. iPhone'da bir satranç karesi en çok
  ~147 pt × 3 = ~441 piksel olduğu için 512 yeterli, 1024 gereksiz yere
  uygulama boyutunu büyütür.
- **Format:** alfa kanallı PNG (PNG-32). Arka plan tamamen saydam olmalı.
- **Yerleşim:** taş karede ortalanmış, çevresinde yaklaşık %6 boşluk
  (yani taş ~480 piksellik alana sığsın). Tüm taşlar aynı taban çizgisini
  paylaşsın; şah ve piyon aynı ölçekte görünsün.
- **Renk:** görseller olduğu gibi çizilir, kodda renklendirme yapılmaz
  (`PieceArt.painted`). Beyaz taraf berrak/buzlu cam, siyah taraf füme cam
  olarak ayırt edilebilmeli — koyu tahtada beyaz, açık tahtada siyah taş
  kaybolmamalı. Dört tahta temasının (Ahşap, Mermer, Arduvaz, Buz) hepsinde
  kontrol edilmeli.
- **Gölge:** görsele gölge **gömmeyin**. Kodda `contactShadow` ile yumuşak bir
  temas gölgesi ekleniyor; gömülü gölge çift görünür.
- **Dosya boyutu:** her dosya ideal olarak 150 KB altında. Gerekirse
  `pngquant --quality 70-90` ile sıkıştırın. 12 dosya toplamı ~2 MB'ı
  geçmemeli.

Dosyalar klasöre konup `flutter pub get` çalıştırıldığında set kendiliğinden
listede belirir; kodda değişiklik gerekmez.
