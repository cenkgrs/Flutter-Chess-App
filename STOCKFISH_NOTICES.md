# Cihaz içi Stockfish

ROK, `stockfish` Flutter paketinin **1.8.1** sürümünü `third_party/stockfish`
altında kaynaklarıyla içerir. Android Gradle dosyası jcenter yerine
mavenCentral, AGP 9.1.0 ve açık namespace kullanacak şekilde uyarlanmıştır.
Motor algoritması değiştirilmemiştir.
Paket ve içindeki motor GPL-3.0 kapsamındadır; podspec içindeki MIT metadata
etiketi motorun GPL lisansının yerine geçmez.

- Tam paket kaynağı: https://pub.dev/api/archives/stockfish-1.8.1.tar.gz
- Paket lisansı: https://pub.dev/packages/stockfish/license
- Upstream: https://github.com/official-stockfish/Stockfish
- Derleme bağımlılıklarının kilidi: pubspec.lock
- Ağ dosyaları: nn-c288c895ea92.nnue ve nn-37f18f62d772.nnue;
  paket bunları derleme sırasında indirir, kullanıcı cihazında indirme yapılmaz.

Dağıtım öncesi: dağıtılan binary ile eşleşen paket/motor kaynaklarını, ağ
dosyalarını, lisansları ve ROK kaynak/derleme talimatlarını erişilebilir bir
yayınla arşivleyin. ROK kaynaklarının yayın adresi henüz belirlenmedi.
Bu dosya hukuki uygunluk onayı değildir; iOS/App Store dağıtım şartları ve
birleşik uygulamanın GPL uyumluluğu yayın öncesinde kontrol edilmelidir.

## Davranış

Tek native motor, sıralı UCI aramaları, 1 iş parçacığı, 32 MB hash.
Oyun aramaları UCI_LimitStrength + UCI_Elo kullanır (1320–3190).
Bu değerler FIDE/online rating garantisi değildir. Analiz tam güçte, konum
başına 650 ms çalışır; kısa analiz etiketleri yaklaşık değerlendirmedir.
En iyi: motor ilk tercihi; diğerlerinde kayıp <=30 cp iyi, <=100 cp
isabetsizlik, <=250 cp hata, daha fazla büyük hata. Parlak/feda hamlesi
algoritması henüz yoktur. Konumdan devam FEN'i korur; önceki üç tekrar
geçmişi FEN'de bulunmadığından yeni antrenman oyununa taşınmaz.

Android derlemesi Linux'ta kontrol edilebilir; iOS native build ve gerçek
cihaz bellek/pil testi macOS/Xcode üzerinde ayrıca yapılmalıdır.
