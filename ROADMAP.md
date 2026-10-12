# Sonraki aşamalar

- Telefon bildirimleri: arkadaşlık isteği için uygulama kapalıyken push bildirimleri.
  Android FCM, iOS APNs bağlantısı, izin yönetimi, cihaz tokenlarının güvenli
  saklanması ve çıkışta temizlenmesi ayrı aşamada ele alınacak.
  Bu sürüm telefon bildirimi göndermez.

# Bu sürümün kurulumu

- Önceki migration'ların ardından
  `supabase/migrations/20261012160000_population_and_leaderboard.sql` uygulanmalı.
- Eşleşme ekranı iki saniyede bir varlık sinyali gönderir; son 15 saniyede
  sinyal alınmayan oyuncular sayılmaz ve yeni eşleşmeye alınmaz.
  Sayaç kullanıcıyı hariç tutar; tüm çevrimiçi kullanıcıları değil, eşleşme arayanları gösterir.
- Bulmaca sıralaması tüm zamanların toplam puanına göredir. Eşit puanlar aynı
  sırayı paylaşır. İlk 100 oyuncu ve kullanıcının kendi sırası gösterilir.
