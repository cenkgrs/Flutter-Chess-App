# ROK Supabase kurulumu

1. Supabase'te boş bir proje oluşturun.
2. SQL Editor içinde `supabase/migrations/20261009143000_initial_online_chess.sql`
   dosyasını çalıştırın.
3. Authentication > URL Configuration alanına
   `com.rok.chess://login-callback/` yönlendirme adresini ekleyin.
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

Üretim ortamında hamle yasallığının ve saatlerin istemciden bağımsız doğrulanması
için `submit_move` RPC'si bir Edge Function veya özel oyun sunucusuyla
değiştirilmelidir. Mevcut sürüm iki cihazlı kapalı MVP testi içindir.
