# 1.1 — durum

Beş madde de yazıldı. Kalanlar elle yapılacak işler.

## Yapıldı

- **Puan isteme.** `lib/backend/rating_prompt.dart` ve AppDelegate'teki
  `rok/review` kanalı. Üçüncü iyi andan sonra soruyor, sonra dört ay
  susuyor; iyi an bilgisayara karşı kazanılan maç ve çözülen günlük bulmaca.
  Kaybedince sormuyor. Kurallar `test/rating_prompt_test.dart` ile sabit.
- **Açık rıza.** Kayıt ekranında ayrı onay kutusu, işaretlenmeden kayıt
  olmuyor; rıza `profiles.cross_border_consent_at` sütununa, profili yaratan
  tetikleyicinin içinde yazılıyor.
- **Analitik sürümü.** `loadAppVersion()` sürümü paketin kendisinden okuyor,
  dart-define yalnızca yedek. Artık derleme komutunda unutulamaz.
- **Plan başlığı.** Premium sayfasındaki plan adı uygulamanın dilinden
  geliyor, fiyat StoreKit'ten.
- **Export compliance.** `ITSAppUsesNonExemptEncryption` Info.plist'te.
- Ölü iki dosya silindi; çeviri testi artık hiçbir dosyayı atlamıyor.

## Elle yapılacak

1. **Migration'ı uygula.** `supabase/migrations/20261104150000_cross_border_consent.sql`
   Supabase SQL editöründe çalıştırılmalı. Bunu yapmadan 1.1 yayınlanırsa
   kayıt ekranı rızayı sorar ama veritabanı kaydedemez.
   Doğrulaması: `tools/cross_border_consent_test.sql` (tek kullanımlık yerel
   PostgreSQL'de; eski tetikleyiciye karşı düştüğü görüldü).
2. **Sürümü yükselt.** `pubspec.yaml` içinde `1.0.0+2` → `1.1.0+3`.
3. **Gizlilik metnine rızadan bahset.** Site artık verinin nerede tutulduğunu
   yazıyor ama rızanın alındığını ve nasıl geri çekileceğini yazmıyor. Geri
   çekmenin pratik karşılığı hesabın silinmesi; bunu dürüstçe söyle.

## Sonraki sürümde bakılacak

Rıza kutusu yalnızca yeni hesaplara soruluyor. 1.0'da kayıt olmuş
kullanıcılarda `cross_border_consent_at` null kalıyor. Sayıları anlamlı
büyürse mevcut kullanıcılara da bir kez soran bir ekran gerekir.
