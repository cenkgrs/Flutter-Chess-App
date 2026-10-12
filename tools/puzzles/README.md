# ROK bulmaca üretimi

İşçi hazır bulmaca verisi kullanmaz. Stockfish'in farklı aday hamleleriyle yasal
maçlar oynatır. Kısa mat adaylarını iki derinlikte doğrular; oyuncunun her
hamlesinde alternatif zorunlu mat varsa adayı eler. Analiz derinlikle sınırlıdır,
matematiksel tekillik garantisi değildir. İlk sürüm mat odaklıdır.

## Üretim

Python 3.10+ ve Stockfish UCI motoru gerekir. Motor APK'ya paketlenmez.
Resmi motor: https://stockfishchess.org/download/
Motor API'si: https://python-chess.readthedocs.io/en/stable/engine.html

```sh
python3 -m venv /tmp/rok-puzzle-venv
/tmp/rok-puzzle-venv/bin/pip install -r tools/puzzles/requirements.txt
/tmp/rok-puzzle-venv/bin/python tools/puzzles/generate.py \
  --engine /usr/games/stockfish --count 30 --games 1000 --seed 42 \
  --output supabase/seeds/puzzles.sql
```

Farklı seed yeni maçlar üretir. Kalite filtresi nedeniyle istenen sayı garanti
edilmez. Komut bir sunucuda çalıştırılabilir; sürekli/zamanlanmış servis henüz
kurulmamıştır. Kullanıcı maçlarından çıkarım ve taş kazanma temaları sonraki
genişletmelerdir.

Supabase SQL Editor'da önce `supabase/migrations/20261012120000_puzzles.sql`,
sonra `supabase/seeds/puzzles.sql` çalıştırılır. Seed yeniden çalıştırılabilir;
aynı konum tekrar eklenmez. JSON çözümleri yalnızca işçide kalır.

## Puanlama

Başlangıç rating'i 1200; çözülmemiş en yakın zorluk seçilir. Aktif deneme
tekrar açılınca devam eder, süre sıfırlanmaz. Temiz başarı 1, yanlış/yardım/
geçme/çözümü açma 0 ile Elo güncellenir. Oyuncu K: ilk 20 deneme 40, sonra 20;
bulmaca K: 8. Başlangıç zorluğu 600 + 300 × oyuncu hamle sayısı; beklenen süre
20 + 25 × oyuncu hamle sayısı saniyedir. Bunlar kalibre edilmemiş tahminlerdir.

Puan = (25 + zorluk/20) × (1 + en fazla %50 hız bonusu) / (1 + yanlış sayısı).
Beklenen süreye yaklaştıkça hız bonusu doğrusal azalır. İpucu/çözümü göster/geç
sıfır puan getirir. Rating hızdan etkilenmez. Süre ve ödül sunucuda hesaplanır;
bağlantı ve bekleme süresi dahildir. Leaderboard için sonuç kayıtları saklanır.

Çözümler tablo izinleri/RLS ile gizlidir. RPC kabul edilen hamle ve otomatik
rakip yanıtının son konumunu döndürür. Tekrarlanan bitiş isteği tekrar puan
vermez. Aynı kullanıcı aynı bulmacadan ikinci kez puan alamaz. Sunucu süresi
harici motor yardımını tespit etmez; leaderboard öncesi anomali kontrolü gerekir.

## Test

`test.sql` yalnızca izole PostgreSQL'de çalıştırılır. Migration `/migration.sql`
yoluna kopyalanır. Sahte auth şeması ve roller oluşturulur; testler rollback ile
biter. Canlı Supabase'de test dosyasını çalıştırmayın.
