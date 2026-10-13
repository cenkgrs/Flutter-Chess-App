# Sonraki aşamalar

- Telefon bildirimleri: arkadaşlık isteği için uygulama kapalıyken push bildirimleri.
  Android FCM, iOS APNs bağlantısı, izin yönetimi, cihaz tokenlarının güvenli
  saklanması ve çıkışta temizlenmesi ayrı aşamada ele alınacak.
  Bu sürüm telefon bildirimi göndermez.

# Bu sürümün kurulumu

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
