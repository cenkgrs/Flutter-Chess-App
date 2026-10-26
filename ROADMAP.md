# Sonraki aşamalar

- Telefon bildirimleri: arkadaşlık isteği için uygulama kapalıyken push bildirimleri.
  Android FCM, iOS APNs bağlantısı, izin yönetimi, cihaz tokenlarının güvenli
  saklanması ve çıkışta temizlenmesi ayrı aşamada ele alınacak.
  Bu sürüm telefon bildirimi göndermez.

## Reklam SDK'sı kaldırıldı (24 Ekim)

`google_mobile_ads` bağımlılığı, `lib/ads/`, altı çağrı noktası, profildeki
reklam gizlilik satırı ve iOS/Android uygulama kimlikleri kaldırıldı. Sebep:
ROK Stockfish'e bağlı olduğu için GPL-3.0-or-later dağıtılıyor; kapalı kaynak
bir SDK'yı aynı binary içinde dağıtmak bu lisansla bağdaşmıyor. Reklamı
çalışma anında kapatmak yetmiyordu, ihlal dağıtımda oluşuyordu.

Reklam, Stockfish sunucuya taşındıktan sonra geri gelebilir: motor binary'de
olmayınca uygulamada GPL kod kalmaz.

## Ücretsiz günlük limitler (24 Ekim)

ROK projesine uygulanmalı:

1. `supabase/migrations/20261024130000_daily_feature_limits.sql`

- Ücretsiz hesap günde **bir asistanlı maç** ve **bir maç analizi** alır.
  Gün `Europe/Istanbul` gece yarısında döner (günlük bulmacayla aynı sınır).
- Sayaç sunucuda (`daily_feature_usage`). İstemcideki kontrol tavsiye
  niteliğinde: uygulama GPL-3 ve kaynağı açık, isteyen kontrolü çıkarıp
  derleyebilir. Yayınlanan build için hakkı gerçek kılan sunucudur.
- Limit `daily_feature_limit(text)` fonksiyonunda. 1.1'de aboneliğe göre
  yükseltmek **sunucu değişikliği**; yeni uygulama sürümü gerekmez.
- `claim_daily_feature` tek deyimde artırır; koşullu `on conflict do update`
  sayesinde iki cihaz son hakkı aynı anda alamaz.
- Misafir ve ücretsiz üyede cihaz başına günlük birer hak uygulanır. Üyede
  sunucu ayrıca hesap sayacı tutar. Çıkış yapmak cihaz hakkını sıfırlamaz.
- StoreKit 2 tarafından doğrulanan aylık/yıllık abone sınırsız kullanır.
  Satın alma, geri yükleme ve yönetim ekranı profildedir. Hak dolduğunda
  asistanlı oyuna giriş ve analiz isteği abonelik penceresi gösterir. Apple ürünleri ve
  fiyatları henüz App Store Connect'te oluşturulmadı; gerçek ödeme testi
  tamamlanmadı. Kurulum ve sınırlar: `SUBSCRIPTIONS.md`.
- Asistan hakkı ilk soruda harcanır (ekranı açmak bedava), analiz hakkı
  "Motor analizi"ne basınca; ikisi de o maç/ekran boyunca tek sefer sayılır.
- Sunucuya ulaşılamazsa cihazın günlük hakkı uygulanır; sınırsız erişim verilmez.
- Hak kontrolü sürerken tekrar dokunmak ikinci istek göndermez. Aynı ekrandan
  yeni oyun başlatmak yeni asistan hakkı gerektirir; önceki oyunun bekleyen
  asistan yanıtı yeni oyuna taşınmaz.

Yerel SQL testi (yalnızca geçici PostgreSQL; canlıda çalıştırmayın):
`tools/test_bootstrap.sql`, ardından migration, ardından
`tools/daily_feature_limits_test.sql`. Test rollback ile biter.

# Bu sürümün kurulumu

## Tahta teması ve düello izleme (24 Ekim)

Önceki migration'ların ardından ROK projesine:

1. `supabase/migrations/20261024120000_duel_spectate.sql`

- `duel_state` artık sırası gelmeyen oyuncuya `opponent_fen`, `opponent_steps`
  ve `opponent_difficulty` döner. Bu güvenli: bir maçta 20 ayrı bulmaca vardır
  ve her tur tek bir oyuncuya aittir; izleyiciye gösterilen konum o maçta ona
  hiç verilmez. Kendi turları da rakibe aynı kuralla kapalı kalır.
- `steps` (çözümdeki toplam hamle) iki tarafa da döner; ilerleme noktaları
  bununla çizilir.
- Migration uygulanmadan da uygulama çalışır: `opponent_fen` gelmezse düello
  ekranı eski boş bekleme kutusunu gösterir.
- Düello ekranı: rakibin tahtası canlı akar, 30 saniyelik tur saati halka
  olarak döner, ilerleme noktaları dolar, hata sayacı titrer, tur bitince
  kazanılan puan tahtanın üstünde yükselerek kaybolur ve skor sayaçları
  yeni değerine doğru sayar. Rakibin hamlesinde hamle sesi çalar.

- Tahta görünümü: Profil → Tahta görünümü (misafirler dahil). Önizleme
  sabittir; Tahta / Taşlar seçimi yalnızca ilgili seçenek listesini açar. Tahta teması (Ahşap, Mermer, Arduvaz, Buz) ile taş seti
  ayrı ayrı seçilir, cihazda `shared_preferences` ile saklanır. Veritabanı
  değişikliği gerekmez; hesaba bağlı değildir.
- Tüm tahta ekranları artık kare ve taş görünümünü `lib/theme/board_theme.dart`
  üzerinden alır. Yeni bir tahta ekranı sabit kare rengi veya `lib/images/wood`
  yolu yazmamalı; `boardSkin` ve `BoardPiece` kullanılmalı.
- 24 Ekim'de sekiz hazır taş seti eklendi: Cam, Fildişi ve Abanoz, Mermer ve
  Bazalt, Porselen ve Obsidyen, Gümüş ve Bronz, Art Deco, Sade Mat, Buz ve
  Lav. Ahşapla birlikte dokuz set. Hepsi 512 px kare, alfalı PNG, set başına
  170–400 KB, toplam 2.1 MB.
- Hazır taşların saydam kenarları çizim sırasında dışarıda bırakılır;
  `piece_geometry.dart` dosya sınırlarını, `paintedPieceFrame` taş türüne göre
  ortak yükseklik/genişlikleri belirler. Küçük piyon/kale/at büyütüldü ve iki
  renk tüm malzemelerde aynı görsel boyuta getirildi. Standart piyon %10 küçüldü.
- Taş görsellerine gölge gömülmez ve kodda da eklenmez. Bir `BoxDecoration`
  gölgesi taşın siluetini değil widget'ın dikdörtgenini çizdiği için her
  karede görünür bir kutu bırakıyordu; denemeyin.
- Seti yeniden üretmek gerekirse `assets/pieces/PROMPT.md`.

## Arkadaş düellosu, rövanş ve ortak tasarım (14 Ekim)

Önceki migration'ların ardından ROK projesine sırayla:

1. `supabase/migrations/20261014120000_duel_invites_and_results.sql`
2. `supabase/migrations/20261014121000_duel_result_details.sql`

- Arkadaşlar → Oyuna davet et → Satranç veya Bulmaca Düellosu.
  Kabul edilen düello iki tarafta aynı maç kimliğiyle açılır.
- Sonuç ekranında iki tarafın skor/rating bilgisi ve 20 turun süresi,
  hata sayısı, puanı gösterilir. Eski tur kayıtlarındaki eksik ölçümler `—` olur.
- Rövanş yalnızca bitmiş maçın iki oyuncusunca istenebilir. İkinci oyuncu kabul
  etmeden maç başlamaz. Arkadaş olmayan rastgele rakipler de maç sonu rövanş yapabilir.
  Davet 5 dakika geçerlidir; bitiş ekranı açıkken durum 2 saniyede yenilenir.
- `lib/widgets/rok_style.dart`: yeni sayfalarda `RokScaffold`, onay ve sonuç
  pencerelerinde `RokDialog` kullanılmalı. Global tema koyu kart/kemik rengi
  düğmeler sağlar. Mevcut özel ahşap oyun tahtası ekranları korunur.
- Yerel SQL/widget testleri canlı iki cihaz testinin yerine geçmez.

## Doğrudan davet ve Bulmaca Düellosu (13 Ekim)

ROK projesinde önceki migration'ların ardından sırayla:

1. `supabase/migrations/20261013140000_direct_invites.sql`
2. `supabase/migrations/20261013150000_puzzle_duels.sql`
3. `supabase/seeds/puzzles_20261013.sql` (44 yeni motor doğrulamalı bulmaca).

- Arkadaşlar listesinden süre seçip maç daveti gönderilir. Karşı taraf kabul
  edince maç açılır; gönderen aynı ekrandaki Maça katıl ile girer. Menü davet
  sayısını gösterir. Davetler 5 dakika geçerlidir.
- Düello: kişi başı 10 farklı bulmaca, toplam 20 dönüşümlü tur. Rakip beklerken
  bulmacanın konumu ve çözümü gönderilmez. Mat uzunluğuna göre çiftler seçilir,
  oyuncuların ortalama rating'ine yakın çiftler önceliklidir.
- Ardından `supabase/migrations/20261013160000_duel_30_second_turns.sql` uygulanmalı.
- Tur süresi 30 saniye, geçme/süre aşımı 0 puan. Çözüm puanı:
  `round(100 × (1 + 0.5 × max(0, 1 - saniye/30)) / (1 + hata))`.
  Saat, hamle doğrulama, skor ve sonuç sunucuda tutulur.
- Rekabetçi rating başlangıcı 1200, Elo K=32; normal bulmaca rating'inden ayrıdır.
  Eşit skorda beraberlik. İki istemci sonuç istediğinde rating tekrar yazılmaz.
- Uygulamadan çıkmak maçı iptal etmez; süre devam eder. Düello ekranına dönünce
  aktif maç devam eder. İki taraf da koparsa süre aşımı bir sonraki sunucu
  isteğinde işlenir; ayrıca çalışan bir zamanlayıcı kurulmadı.
- Bu ilk oynanabilir sürümdür. Canlı iki cihaz testi, anti-cheat, rating ve
  zorluk kalibrasyonu henüz tamamlanmış sayılmaz. Aynı maçta konum tekrarlanmaz;
  farklı maçlarda ve normal bulmaca modunda havuz ortak olduğundan tekrar olabilir.
- Üretim manuel işçi komutuyla yapılır; otomatik sürekli havuz doldurma servisi
  henüz yoktur. Yeni seed mevcut denemeleri sıfırlamadan havuzu genişletir.

- Arkadaşlar için `supabase/migrations/20261013120000_friends.sql` uygulanmalı.
  Ana menüdeki Arkadaşlar bağlantısında gelen istek sayısı, uygulama açıkken
  15 saniyede bir yenilenir. Kullanıcı adı araması en az 3 karakterle başlayan
  ilk 20 sonucu getirir. Telefon push bildirimi gönderilmez.

- Önceki migration'ların ardından
  `supabase/migrations/20261012160000_population_and_leaderboard.sql` uygulanmalı.
- Eşleşme ekranı iki saniyede bir varlık sinyali gönderir; son 15 saniyede
  sinyal alınmayan oyuncular sayılmaz ve yeni eşleşmeye alınmaz.
  Sayaç kullanıcıyı hariç tutar; tüm çevrimiçi kullanıcıları değil, eşleşme arayanları gösterir.
- Bulmaca sıralaması tüm zamanların toplam puanına göredir. Eşit puanlar aynı
  sırayı paylaşır. İlk 100 oyuncu ve kullanıcının kendi sırası gösterilir.
