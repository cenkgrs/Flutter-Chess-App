# iOS abonelik ve ücretsiz kullanım

## Uygulanan davranış

- Misafir ve ücretsiz üyeler İstanbul takvimine göre günde bir asistanlı maç,
  bir analiz alır. Asistan hakkı ilk soruda harcanır; analiz hakkı motor
  analizini başlatırken harcanır. Aynı oyun/ekran içindeki tekrarlar sayılmaz.
- Cihaz sayacı çıkışta sıfırlanmaz. Aynı cihazda hesap değiştirmek veya
  misafire geçmek yeni hak vermez. Bu nedenle cihazı paylaşan ücretsiz
  hesaplar cihazın hakkını paylaşır.
- Üyelerde mevcut `claim_daily_feature` RPC'si ayrıca hesap başına kontrol
  sağlar. Sunucuya ulaşılamazsa cihazdaki günlük sınır uygulanır; sınırsız
  ücretsiz kullanım verilmez.
- Misafir sayacı yerel tercihlerde tutulur. Uygulamayı silmek, cihaz verisini
  veya saati değiştirmek bu korumayı aşabilir. Cihazlar arası kesin misafir
  sayımı yoktur. Üye sayımının cihazlar arasında uygulanması için günlük limit
  migration'ının canlıda yüklü olması gerekir.
- Apple'ın StoreKit 2 `Transaction.currentEntitlements` üzerinden doğruladığı
  etkin aylık/yıllık abonelik iki sayacı da atlar. Sınırsız erişim yalnızca
  iOS'ta, satın alımı içeren Apple hesabıyla kullanılabilir. Supabase hesabına
  veya Android'e aktarım bu sürümde yoktur.
- İptal/sona erme/iade sonrası sonraki kullanımda etkin hak yeniden okunur.
  Doğrulanamayan işlem ücretli erişim oluşturmaz. Kullanıcıdan satın alım
  ekranına her girişte Apple hesabı onayı istenmez; geri yükleme kullanıcı
  isteğiyle `AppStore.sync()` çağırır.

## App Store Connect'te tamamlanacaklar

ROK Chess uygulamasında tek bir otomatik yenilenen abonelik grubu açın.
Aynı erişim düzeyinde iki ürün oluşturun:

| Ürün kimliği | Dönem |
|---|---|
| `com.silveroaktech.rok.premium.monthly` | 1 ay |
| `com.silveroaktech.rok.premium.yearly` | 1 yıl |

İstenen fiyatlar (App Store Connect'te henüz uygulanmadı):

| Dönem | USD | Türkiye / TRY |
|---|---|---|
| Aylık | $2 | ₺50 |
| Yıllık | $20 | ₺500 |

USD temel fiyatı ile Türkiye fiyatı ayrı ayarlanmalıdır. Apple'ın izin verdiği
fiyat noktaları bu tutarları tam karşılamazsa en yakın tutar kullanıcıya
onaylatılmalıdır. Uygulama fiyatı sabit kodlamaz.
Uygulama fiyatları `Product.displayPrice` ile mağazadan getirir; örnek fiyat
veya sahte satın alma sunmaz. Ürünler gelmezse satışa açık olmadığı yazılır.

Ürünler için yerelleştirilmiş ad/açıklama, inceleme ekran görüntüsü, fiyat ve
satış bölgelerini; hesapta ücretli uygulama sözleşmesi, banka/vergi
bilgilerini tamamlayın. İlk abonelikleri uygulama sürümüyle birlikte incelemeye
verin. Uygulama içi gizlilik ve Apple standart kullanım koşulları bağlantıları
abonelik sayfasındadır. App Store açıklamasına da bu bağlantıları ekleyin.

## Test

Telefon sürümü profile modunda kurulabilir; bu App Store'a gönderilen paket
olmaz. Gerçek satın alma testi için App Store ürünleri yapılandırılmalı ve
Apple test ortamında satın alma denenmelidir. Sadece bir Dart testinin geçmesi,
Apple satın alma/yenileme/iade akışının doğrulandığı anlamına gelmez.

Test edilecekler: misafirde iki özelliğin ilk/ikinci kullanımı, yeni oyun,
uygulamayı kapatıp açma, giriş/çıkış, İstanbul gece yarısı, aylık/yıllık
satın alma, kullanıcı iptali, bekleyen satın alma, geri yükleme, uygulama
arka plandayken yenilenme, abonelik bitişi/iade, açık/koyu tahta görünümleri.

Native köprü `ios/Runner/AppDelegate.swift`, Dart mağaza durumu
`lib/backend/subscriptions.dart`, sayaç `lib/backend/feature_limits.dart`.

Apple kaynakları:
- https://developer.apple.com/documentation/storekit/transaction
- https://developer.apple.com/documentation/storekit/transaction/currententitlements
- https://developer.apple.com/documentation/storekit/product/purchase(options:)
