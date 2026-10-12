# ROK Supabase kurulumu

1. Supabase'te boş bir proje oluşturun.
2. SQL Editor içinde `supabase/migrations` klasöründeki SQL dosyalarını dosya
   adı sırasıyla çalıştırın. Mevcut kurulumlarda yalnızca uygulanmamış
   migration dosyalarını çalıştırın. Bulmacalar için
   `20261012120000_puzzles.sql`, ardından `supabase/seeds/puzzles.sql`
   çalıştırılmalıdır. Üretim ve puanlama bilgisi: `tools/puzzles/README.md`.
3. Authentication > URL Configuration alanına
   `com.silveroaktech.rok://login-callback/` yönlendirme adresini ekleyin.
4. `supabase.env.example.json` dosyasını `supabase.env.json` adıyla kopyalayın
   ve Connect ekranındaki Project URL ile publishable key'i girin.
5. Uygulamayı şu komutla çalıştırın:

   `flutter run --dart-define-from-file=supabase.env.json`

APK üretmek için:

`flutter build apk --release --dart-define-from-file=supabase.env.json`

`supabase.env.json` Git'e eklenmez. Mobil istemciye yalnızca publishable key
konur; `service_role` anahtarı hiçbir zaman uygulamaya eklenmemelidir.

## Mevcut çevrimiçi kapsam

- E-posta/şifre ile kayıt ve giriş
- Her kullanıcı için Bullet, Blitz, Rapid ve Klasik rating havuzları
- Aynı süre kontrolündeki oyuncuları atomik biçimde eşleştiren kuyruk
- Katılımcılarla sınırlı oyun ve hamle verileri
- Hamle sırası/ply çakışma kontrolü
- Oyun sonucunda atomik Elo güncellemesi
- Altı karakterli özel oda/davet kodu
- Kullanıcı başına son 10 maçın hamle geçmişi ve inceleme konumları

Üretim ortamında hamle yasallığının ve saatlerin istemciden bağımsız doğrulanması
için `submit_move` RPC'si bir Edge Function veya özel oyun sunucusuyla
değiştirilmelidir. Mevcut sürüm iki cihazlı kapalı MVP testi içindir.
