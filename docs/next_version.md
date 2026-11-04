# 1.1 — biriken işler

1.0 incelemedeyken ortaya çıkan, o sürüme dokunmamak için ertelenen maddeler.
Sıra etkiye göre: en üsttekinin karşılığı en büyük.

## 1. Puan isteme penceresi

Mağaza sıralaması yıldız sayısına bakıyor ve şu an hiç yıldızımız yok.
`SKStoreReviewController`'ı iyi bir anda göster: oyuncu bir maç kazandıktan
ya da günlük bulmacayı çözdükten hemen sonra. Kaybettikten sonra **gösterme**.

iOS yılda üç kez göstermeye izin veriyor, gerisini kendi yutuyor; o yüzden anı
iyi seçmek gerekiyor. Bir de ilk açılışta sorma — oyuncunun uygulamayı
beğenecek kadar kullanmış olması lazım, en az üç maç gibi bir eşik koy.

## 2. Yurt dışına veri aktarımı için açık rıza

Supabase Frankfurt'ta; Türkiye'deki bir kullanıcı için bu KVKK 9. madde
anlamında yurt dışına aktarım. Gizlilik metni bunu artık açıkça yazıyor ama
aktarımın hukuki dayanağı yok.

Yapılacak:

- Kayıt ekranına ayrı bir onay kutusu: "Verilerimin yurt dışındaki sunucularda
  işlenmesini kabul ediyorum." İşaretlenmeden kayıt tamamlanmasın. Gizlilik
  politikasına bağlantı versin.
- Rızayı kaydet: `profiles` tablosuna `cross_border_consent_at timestamptz`
  gibi bir sütun. Rızanın ne zaman alındığını gösterebilmek gerekiyor.
- Gizlilik metninde bu rızaya atıf yap ve nasıl geri alınacağını yaz.

Rızayı geri alan kullanıcı için pratik karşılık hesabın silinmesi; metinde bunu
dürüstçe söyle.

## 3. Release build analitiğe build numarasını bildirsin

`lib/backend/analytics.dart` içindeki `appVersion`, `ROK_APP_VERSION`
tanımlanmamışsa `'1.0.0'`'a düşüyor. App Store IPA'sını bu define olmadan
derlediğim için yayındaki sürüm analitikte build numarasız görünüyor.

Şans eseri işimize yaradı — reviewer'ın oturumunu bu sayede ayırt ettik — ama
doğrusu bu değil. İki yoldan biri:

- `flutter build ipa` komutuna da `--dart-define=ROK_APP_VERSION=...` geçir ve
  bunu bir betiğe bağla ki unutulmasın, ya da
- `package_info_plus` ile sürümü uygulamanın kendisinden oku; define tamamen
  kalksın.

İkincisi daha sağlam.

## 4. Abonelik planının adı uygulamanın dilinden gelsin

Premium sayfasında plan başlığı StoreKit'in `displayName` değerinden geliyor.
StoreKit bunu uygulamanın diline göre değil, cihazın App Store mağazasına göre
seçiyor; mağazası ABD olan bir kullanıcı uygulamayı Türkçe kullansa bile
"Monthly Premium" görüyor.

Fiyat StoreKit'ten gelmeye devam etsin (zorunlu ve doğru), ama başlığı kendi
çevirimizden yaz: `lib/screens/subscription_screen.dart` içinde
`title ?? (yearly ? 'Yıllık' : 'Aylık')` ifadesini tersine çevir.

## 5. Export compliance anahtarı

`ios/Runner/Info.plist` içine `ITSAppUsesNonExemptEncryption = false`.
Uygulama kendi şifrelemesini içermiyor, yalnızca iOS'un TLS yığınını
kullanıyor. Bu anahtar olmadan her yüklemede App Store Connect aynı soruyu
soruyor.

## Ayrıca

Ölü dosyalar duruyor: `lib/screens/home_page_screen.dart` ve
`lib/widgets/fast_puzzles.dart`. Uygulamadan erişilmiyorlar, çeviri testi de
onları atlıyor. Silinsinler.
