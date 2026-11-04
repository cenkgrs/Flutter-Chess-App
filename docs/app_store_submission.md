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

Birincil dil **İngilizce (U.S.)**, hedef kitle yurt dışı. Türkçe yerelleştirme
aynı alanların altında. Almanca ve Rusça uygulama içinde çevrili ama mağaza
metni girilmedi; girilmezse Apple İngilizce'yi gösterir.

### English (U.S.) — primary

**Name (30):** ROK Chess
**Subtitle (30):** Play, learn, solve, duel

**Promotional Text (170):**
```
An in-game assistant that names the move and says why. Daily puzzles, puzzle
duels against real opponents, and nine board and piece sets to play on.
```

**Description:**
```
ROK is chess on a board worth looking at, with a coach that talks back.

AN ASSISTANT THAT EXPLAINS
Ask mid-game and ROK names the move, draws the arrow and tells you what it
wins — then shows the line it expects to follow. After the game, the review
walks every move with an engine verdict: best, good, inaccuracy, mistake,
blunder.

PLAY THE COMPUTER
A Stockfish engine at the strength you pick, from a gentle 800 to a level
that will punish you. Pick your opponent's rating before the game starts.

PLAY ONLINE
Rated matches against real players in bullet, blitz, rapid and classical.
Clocks run on the server, so a dropped connection does not lose your game —
reopen the app and the match is still there. Invite a friend with a six-digit
room code.

PUZZLES AND DUELS
A new puzzle every day with a streak to keep. In a puzzle duel you race an
opponent through the same ten puzzles and watch their board live.

NINE BOARDS, NINE PIECE SETS
Wood, marble, slate, ice, glass, porcelain, art deco and more. Board and
pieces are chosen separately.

ROK PREMIUM
Free accounts get one assisted game and one game review per day. Premium
makes both unlimited. Monthly and yearly; renews automatically unless
cancelled in your Apple account settings.

Plays in English, German, Russian and Turkish.

Terms of Use (EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
Privacy Policy: https://cenkgrs.github.io/rok-site/privacy.html
```

**Keywords (100):**
```
chess,puzzle,tactics,board game,strategy,online,duel,stockfish,endgame,coach,blitz,elo
```

### Neden açıklamanın içinde

4 Kasım 2026'da 1.0 bu yüzden reddedildi: abonelik satan bir uygulamanın
EULA bağlantısı **App Store ürün sayfasında** görünmek zorunda; uygulamanın
içinde olması yetmiyor. Apple'ın standart EULA'sını kullandığımız için
bağlantıyı her yerelleştirmenin açıklamasına koymak yeterli — App Store
Connect'e ayrı bir custom EULA yüklemeye gerek yok.

Yeni dil eklenirse bu iki satır da eklenmeli.

### Türkçe

**Subtitle (30):** Satranç, bulmaca ve düello

**Promotional Text (170):**
```
Hamleyi adıyla söyleyen bir oyun içi asistan. Günlük bulmacalar, gerçek
rakiplere karşı bulmaca düellosu ve dokuz tahta ile taş seti.
```

**Description:**
```
ROK, bakmaya değer bir tahtada oynanan satranç — üstüne konuşan bir antrenörle.

AÇIKLAYAN ASİSTAN
Oyunun ortasında sor; ROK hamleyi adıyla söyler, oku çizer, ne kazandırdığını
anlatır ve beklediği devamı gösterir. Maç bitince inceleme her hamleyi motor
değerlendirmesiyle gezer: en iyi, iyi, isabetsizlik, hata, vahim hata.

BİLGİSAYARA KARŞI OYNA
Stockfish motoru, senin seçtiğin güçte. Rakibin rating'ini maç başlamadan
belirle.

ONLINE OYNA
Bullet, blitz, rapid ve klasik dereceli maçlar. Saatler sunucuda işler;
bağlantın koparsa maçı kaybetmezsin, uygulamayı açtığında kaldığı yerde
durur. Arkadaşını altı haneli oda koduyla çağır.

BULMACA VE DÜELLO
Her gün yeni bir bulmaca ve koruman gereken bir seri. Bulmaca düellosunda
rakibinle aynı on bulmacayı yarışır, onun tahtasını canlı izlersin.

DOKUZ TAHTA, DOKUZ TAŞ SETİ
Ahşap, mermer, arduvaz, buz, cam, porselen, art deco ve dahası. Tahta ile
taşlar ayrı ayrı seçilir.

ROK PREMIUM
Ücretsiz hesaplar günde bir asistanlı maç ve bir maç incelemesi yapabilir.
Premium ikisini de sınırsız yapar. Aylık ve yıllık; Apple hesap ayarlarından
iptal edilmedikçe otomatik yenilenir.

Türkçe, İngilizce, Almanca ve Rusça oynanır.

Kullanım Koşulları (EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
Gizlilik Politikası: https://cenkgrs.github.io/rok-site/privacy.html
```

**Keywords (100):**
```
satranç,chess,bulmaca,puzzle,online,düello,strateji,tahta oyunu,taktik,zeka,açılış,elo
```

### Her iki dilde ortak

**Category:** Primary Games → Board. Secondary Games → Strategy.
**Age rating:** 4+ (şiddet, kumar ve kullanıcı içeriği yok; sohbet yok).
**Copyright:** 2026 Cenk Gürses
**Support URL:** https://cenkgrs.github.io/rok-site/support.html
**Privacy Policy URL:** https://cenkgrs.github.io/rok-site/privacy.html

## Ekran görüntüleri

Zorunlu set: **iPhone with Dynamic Island (medium display)**, 1179 × 2556.
iPhone 14 Pro tam bu ölçüyü verir, yani görüntüler doğrudan telefondan
alınabilir. App Store Connect bu kareleri küçük cihazlara kendisi ölçekler, o
yüzden başka boyut yüklemek gerekmez. Alfa kanalı olmamalı — telefonun kendi
ekran görüntüsü zaten PNG/opak.

Çekilmiş hâlleri `store/screenshots/` altında, yükleme sırasına göre
adlandırılmış (klasör `.gitignore`'da; repo public ve kareler birkaç MB):

1. `01-assistant.png` — asistanlı maç, balon açık, ok tahtada
2. `02-game-review.png` — motor analizi, değerlendirme çubuğu, rozetler
3. `03-daily-puzzle.png` — seri, süre ve seviye rozetleri
4. `04-home-menu.png` — menü, dört mod birden
5. `05-board-appearance.png` — tahta ve taş seçimi

`06-play-modes.png` de var ama arkası karartılmış bir popup olduğu için
galeride sönük duruyor; yüklenmedi.

Premium ekranı Paid Apps sözleşmesi aktifleşip fiyatlar görünmeden
çekilemiyor. Apple review için zorunlu değil, abonelik ürünlerinin kendi
ekran görüntüsü alanı için gerekiyor.

Kişisel e-posta, test kullanıcı adı veya hata mesajı görünmemeli.
