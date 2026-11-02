# App Store 1.0 — doldurulacak alanlar

Bu dosya App Store Connect'te elle girilecek metinleri tutar. Uygulamanın ne
topladığı değiştiğinde App Privacy bölümü de güncellenmeli.

## App Privacy

Apple'ın sorduğu her kalem, uygulamanın gerçekten yazdığı veriden çıkarıldı.
Hepsi hesaba bağlı (**Linked to You**), çünkü satırlar `auth.uid()` ile
ilişkilendiriliyor. Hiçbiri izleme (**Tracking**) için kullanılmıyor — üçüncü
tarafa veri verilmiyor, reklam ağı yok. "Used for Tracking" sorusuna her
kalemde **hayır**.

| Kategori | Kalem | Amaç | Bağlı mı |
|---|---|---|---|
| Contact Info | Email Address | App Functionality | Evet |
| Identifiers | User ID | App Functionality, Analytics | Evet |
| Usage Data | Product Interaction | Analytics | Evet |
| User Content | Gameplay Content | App Functionality | Evet |
| Purchases | Purchase History | Analytics | Evet |

Neyin nereden geldiği:

- **Email Address** — yalnızca hesap açarken; Supabase `auth.users`. Misafir
  oynayan hiçbir şey vermiyor.
- **User ID** — `profiles.id`, oyun ve analitik satırlarının sahibi.
- **Product Interaction** — `analytics_events`: uygulama açılışı, oyun başlama
  ve bitişi, asistan ve analiz kullanımı, tema değişimi. Olay adı ve zaman
  dışında içerik tutulmuyor.
- **Gameplay Content** — oyunlar, hamleler, bulmaca denemeleri, düello
  sonuçları, puanlar.
- **Purchases** — abonelik başladığında/geri yüklendiğinde bir olay satırı
  yazılıyor. Fiyat, kart veya makbuz bilgisi tutulmuyor; ödemeyi Apple işliyor.

Toplanmayanlar — bu kalemlerde **hayır** işaretle: konum, kişiler, fotoğraf,
sağlık, finans bilgisi, hassas veri, arama geçmişi, tanılama/çökme kaydı,
reklam verisi. Uygulamada reklam SDK'sı ve çökme raporlama aracı yok.

## App Review Information

Build yüklenip işlenmeden bu bölüm görünmez. Göründüğünde:

- İletişim: ad, soyad, telefon, e-posta.
- **Sign-in required: evet.** Demo hesabı ver — online oyun, arkadaş odası ve
  bulmaca düellosu giriş istiyor.
- Notes:

```
ROK is a chess app. Most of it works without an account: play against the
engine, puzzles, daily puzzle, board and piece themes.

An account is required for online play, friend rooms and puzzle duels. Please
use the demo account above.

ROK Premium removes the daily limit on the in-game assistant and on post-game
analysis. A signed-in free user gets one assisted game and one analysis per
day; guests are not limited. The subscription is reached from the profile icon
on the home screen, then "ROK Premium".

The chess engine is Stockfish, licensed under GPL-3.0-or-later. The licence
notice and a link to the exact source revision of this build are in the app
under Profile > Open source.
```

## Metadata

**Name:** ROK Chess
**Subtitle (30):** Satranç, bulmaca ve düello

**Promotional Text (170):**
```
Tahta ve taş temalarını seç, motora karşı oyna, günlük bulmacayı çöz ve
arkadaşlarınla bulmaca düellosuna gir.
```

**Description:**
```
ROK, satrancı sade ve güzel bir tahtada buluşturan bir oyun.

MOTORA KARŞI OYNA
Stockfish destekli motora karşı, seçtiğin zorlukta oyna. Oyun içi asistan
sıradaki hamleyi gerekçesiyle anlatır; maç bitince analiz, nerede
sapıldığını gösterir.

ONLINE OYNA
Gerçek rakiplerle eşleş, arkadaşlarını özel odaya çağır. Saatler sunucu
tarafında tutulur; bağlantın koparsa maç kaldığı yerden devam eder.

BULMACA VE DÜELLO
Her gün yeni bir bulmaca ve seri takibi. Bulmaca düellosunda rakibinle aynı
anda çöz, onun tahtasını canlı izle.

TEMALAR
Cam, mermer, porselen, art deco ve daha fazlası. Tahta ve taş setlerini
ayrı ayrı seç.

ROK PREMIUM
Ücretsiz kullanıcı günde bir asistanlı maç ve bir maç analizi yapabilir.
Premium ile ikisi de sınırsız. Aylık ve yıllık abonelik seçenekleri var;
abonelik dönem sonunda otomatik yenilenir, iptal ayarlardan yapılır.

Dört dil: Türkçe, İngilizce, Almanca, Rusça.
```

**Keywords (100):**
```
satranç,chess,bulmaca,puzzle,online,düello,stockfish,strateji,tahta oyunu,zeka
```

**Category:** Primary Games → Board. Secondary Games → Strategy.
**Age rating:** 4+ (şiddet, kumar ve kullanıcı içeriği yok; sohbet yok).
**Copyright:** 2026 Cenk Gürses

## Ekran görüntüleri

Zorunlu set: **iPhone with Dynamic Island (medium display)**, 1179 × 2556.
iPhone 14 Pro tam bu ölçüyü verir, yani görüntüler doğrudan telefondan
alınabilir. App Store Connect bu kareleri küçük cihazlara kendisi ölçekler, o
yüzden başka boyut yüklemek gerekmez. Alfa kanalı olmamalı — telefonun kendi
ekran görüntüsü zaten PNG/opak.

Beş kare:

1. Ana menü
2. Motora karşı maç, asistan balonu açık
3. Bulmaca düellosu, rakibin tahtası görünür
4. Tema seçimi
5. Profil

Kişisel e-posta, test kullanıcı adı veya hata mesajı görünmemeli.
