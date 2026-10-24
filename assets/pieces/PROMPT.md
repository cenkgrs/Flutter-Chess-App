# Taş görsellerini üretme

Beklenen dosyalar ve teknik koşullar [README.md](README.md) içinde. Bu dosya
bir setin görsellerini bir görsel üretim modeliyle nasıl çıkaracağını anlatır.
Aşağıdaki iki prompt cam seti içindir; başka bir set için yalnızca
**Material** paragrafını değiştir, geri kalan her şeyi aynı bırak — ölçek,
kamera ve taban çizgisi setler arasında tutarlı kalsın diye.

## Yöntem: tek tek değil, iki sayfa hâlinde üret

Taşları teker teker üretirsen ölçek, kamera açısı ve ışık taştan taşa kayar;
tahtada şah ile piyon farklı dünyalardan gelmiş gibi durur. Bunun yerine
**her renk için tek bir görsel** üret (6 taş yan yana), sonra kesip ayır.
Böylece altı taş aynı ışığı ve aynı taban çizgisini paylaşır.

Toplam iki üretim: bir beyaz sayfası, bir siyah sayfası. Siyah sayfasını
üretirken beyaz sayfasını referans görsel olarak ver ki siluetler birebir
aynı kalsın.

---

## Prompt 1 — beyaz taşlar (berrak cam)

```text
A single horizontal row of six Staunton chess pieces rendered in clear
optical glass, product photography, studio three-point lighting on a plain
flat mid-grey background, no other objects.

Left to right: pawn, knight, bishop, rook, queen, king.

Material: transparent colourless optical glass, like a high-end crystal
chess set. Visible internal refraction and caustics, crisp specular
highlights along the edges, a faint cool blue-white rim light, slightly
frosted satin finish on the bases. The glass reads as light and luminous,
clearly the lighter side of the set.

Shapes: classic Staunton. Pawn is a sphere on a tapered collar. Knight is a
horse head in profile facing left with a carved mane. Bishop is a tall mitre
with a single diagonal slit and a small ball finial. Rook is a cylindrical
tower with four square crenellations. Queen is a pointed coronet with a small
ball finial. King is the tallest, with a cross finial above a crown band.

Framing: all six pieces stand on one shared invisible baseline, photographed
straight on at eye level with no perspective distortion, no tilt. Relative
heights are true to a real set: the pawn is the shortest, the king the
tallest, roughly 1 to 1.7. Even spacing, generous margin around the row.

No shadow on the ground, no reflection on the ground, no table, no board, no
text, no watermark, no hands.
```

## Prompt 2 — siyah taşlar (füme cam)

Aynı prompt, şu iki paragraf değişir. Üretirken beyaz sayfasını referans
görsel olarak ver ve "same shapes, same camera, same lighting as the
reference" diye ekle.

```text
Material: smoked charcoal glass, deeply tinted near-black but still
translucent, like smoky quartz. Light passes through the thin edges and
glows faintly warm, while the bodies stay dark and heavy. Crisp specular
highlights and a bright rim light along the contours so the silhouette stays
readable against a dark board. Slightly frosted satin finish on the bases.
The glass reads as dark and dense, clearly the darker side of the set.
```

---

## Üretimden sonra

1. **Arka planı sil.** Çoğu model saydam PNG vermez; düz gri arka planla üret,
   sonra arka planı kaldır. Cam saydam olduğu için otomatik arka plan silici
   taşın *içini* de silebilir — sonucu koyu ve açık zeminde ayrı ayrı kontrol
   et. İçi boşaldıysa elle maskelemek gerekir.
2. **Kes ve ortala.** Her taşı kendi 512 × 512 karesine al, yatayda ortala,
   çevresinde ~%6 boşluk bırak. Dikeyde **ortalama**: altı taş aynı taban
   çizgisini paylaşmalı, yani her taşın tabanı karenin alt kenarından aynı
   uzaklıkta olmalı. Şah kareyi doldurur, piyon küçük kalır — doğrusu budur.
3. **Gölgeyi temizle.** Görsele gölge sızdıysa sil; uygulama gölgeyi kendi
   ekliyor, iki gölge üst üste binerse kirli görünür.
4. **Adlandır** ve `assets/pieces/<id>/` altına koy.
   `w_pawn.png w_knight.png w_bishop.png w_rook.png w_queen.png w_king.png`
   `b_pawn.png b_knight.png b_bishop.png b_rook.png b_queen.png b_king.png`
5. **Sıkıştır.** `pngquant --quality 70-90 --ext .png --force *.png`
   Her dosya 150 KB altında, toplam ~2 MB'ı geçmesin.
6. `pubspec.yaml`'a klasörü, `board_theme.dart`'a `PieceSet` tanımını ekle
   (README'deki "Yeni set eklemek"), `flutter pub get` çalıştır.

Kontrol listesi README'de.
