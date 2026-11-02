# ROK Analitik Dashboard

ROK Chess olay verisini okuyan, **yerelde çalışan** yönetici paneli. Flutter
uygulamasından tamamen ayrıdır; tek bağlantısı Supabase'dir.

## Çalıştırma

```sh
cd admin_dashboard
cp .env.example .env     # supabase.env.json'daki URL ve publishable key
npm install
npm run dev              # http://127.0.0.1:5173 adresinde açılır
```

İlk girişte analitik yöneticisi olan bir hesapla giriş yapılır. Yetki vermek
için Supabase SQL Editor'da:

```sql
insert into public.analytics_admins (user_id)
values ('<admin-kullanıcının-auth-uuid-si>');
```

Yetkisi olmayan bir hesapla girilirse panel veri göstermez; veritabanı
`admin required` döndürür.

## Güvenlik

- **Service-role anahtarı bu klasörde hiçbir yerde yok ve olmamalı.** Tek
  kullanılan kimlik bilgisi Supabase'in publishable (eski adıyla `anon`)
  anahtarıdır — Flutter uygulamasının `supabase.env.json` içinde taşıdığı
  anahtarın aynısı. Supabase onu istemciler için yayınlar; tek başına hiçbir
  şeye erişim vermez.
- Tüm okuma işlemleri `security definer` fonksiyonlar üzerinden yapılır ve
  her biri ilk satırda `is_analytics_admin()` kontrol eder. Anahtarı ele
  geçiren biri tek bir olay bile okuyamaz.
- `analytics_events` ve `analytics_admins` tablolarında RLS açıktır ve
  `anon`/`authenticated` rollerinden tüm yetkiler geri alınmıştır. Tablolara
  doğrudan erişim yoktur.
- **E-posta adresleri hiçbir sorguda getirilmez.** Kullanıcılar
  `profiles.username` ile gösterilir; raporlama fonksiyonları `auth.users`
  tablosuna hiç bakmaz.
- Olay yazımı `log_analytics_event` RPC'si üzerinden yapılır ve `user_id`
  sunucuda `auth.uid()`'den alınır. İstemci başka bir kullanıcının kimliğini
  gönderemez; misafir kaydı `null` olur.

### Yayınlama hakkında

Bu panel **yerelde çalıştırılmak üzere** tasarlandı; `npm run dev` yeterlidir.

GitHub Pages veya benzeri bir statik barındırmaya **gizli anahtar
koyulmamalıdır** — ve buna gerek de yoktur: panelin tuttuğu tek anahtar zaten
gizli değildir, koruma anahtarda değil veritabanındaki admin kontrolündedir.
Yine de paneli herkese açık bir adreste yayınlamak, giriş ekranını ve Supabase
proje adresini internete açar. Gerçekten uzaktan erişim gerekiyorsa:

1. Paneli kurum içi bir ağda veya parola korumalı bir host arkasında yayınlayın, ya da
2. `src/api.js` dosyasındaki çağrıları kendi backend'inize/Supabase Edge
   Function'ınıza yönlendirin. Tüm veri erişimi tek dosyada toplandığı için
   bu değişiklik yalnızca o dosyayı etkiler.

## Ayrı repo olarak kullanma

Klasör kendi kendine yeter: kendi `package.json`, `.gitignore` ve `.env.example`
dosyaları vardır, ROK deposundaki hiçbir dosyaya referans vermez. Ayırmak için
klasörü kopyalayıp içinde `git init` yapmak yeterlidir.

Ayrıca tutmanın bir faydası daha var: ROK uygulaması Stockfish'e bağlı olduğu
için GPL-3.0-or-later dağıtılıyor. Bu panel ayrı bir programdır ve motorla
hiçbir bağı yoktur; ayrı repoda durması lisans sınırını net tutar.

## Ekranlar

- **Özet**: toplam kullanıcı, yeni kayıt, 24 saat / 7 gün aktif, başlayan ve
  biten oyun, asistan ve analiz kullanımı, abonelik bildiren hesap, misafir olayı
- **Günlük grafikler**: kayıt ve aktif kullanıcı; başlayan ve biten oyun;
  asistan, analiz ve abonelik
- **Kullanıcı listesi**: kullanıcı adı, kayıt tarihi, son aktivite, oyun,
  asistan, analiz sayısı ve abonelik durumu
- **Olay günlüğü**: tarih, olay, kullanıcı, sürüm/platform, metadata; olaya göre filtre
- **Tarih filtresi**: bugün, son 7 gün, son 30 gün, özel aralık

## Bilinen sınırlar

- **Abonelik sayısı kesin değildir.** Abonelikler StoreKit ile cihazda
  doğrulanıyor; sunucuda abonelik kaydı yok. Panel yalnızca
  `subscription_started` / `subscription_restored` olayı bildiren hesapları
  sayar. Bu bir fatura rakamı değildir.
- **Misafirler kullanıcı olarak sayılamaz.** Misafir olaylarının `user_id`'si
  yoktur; "aktif kullanıcı" yalnızca giriş yapmış hesapları kapsar. Misafir
  hacmi ayrı bir "misafir olayı" sayacında görünür.
- Hesap silindiğinde o hesabın olayları da silinir. Bu bilinçli bir tercihtir:
  silme sözü veriliyorsa geçmiş aktivite izi de kalmamalıdır. Geçmiş toplamlar
  bu durumda düşer.
