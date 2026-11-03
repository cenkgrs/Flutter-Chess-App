import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../backend/subscriptions.dart';
import '../l10n/app_language.dart';
import '../widgets/rok_style.dart';

/// The store page for ROK Premium.
///
/// Presentation only: what is sold, how it is bought and how it is verified
/// all stay in [SubscriptionStore]. Prices are whatever the App Store returns
/// as `displayPrice`, never written down here, so a price change in App Store
/// Connect needs no release. No claim is made that the store cannot back up.
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key, this.store});
  final SubscriptionStore? store;
  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen>
    with WidgetsBindingObserver {
  static const _bone = rokBone;
  static const _muted = Color(0xffb9aea5);
  static const _gold = Color(0xffe2b75f);

  SubscriptionStore get store => widget.store ?? SubscriptionStore.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    store.load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) store.refresh();
  }

  Future<void> _link(String url) async {
    try {
      if (await launchUrl(Uri.parse(url),
          mode: LaunchMode.externalApplication)) {
        return;
      }
    } catch (_) {}
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: LText('Bağlantı açılamadı. Tekrar dene.')));
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: store,
      builder: (context, _) => RokScaffold(
            appBar: AppBar(title: const LText('ROK Premium')),
            body: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 36),
                children: [
                  _hero(),
                  // A store that will not answer is the first thing to say,
                  // not something to find below three screens of pitch.
                  if (store.error != null) ...[
                    const SizedBox(height: 20),
                    LText(store.error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: _gold, fontSize: 13.5)),
                    Center(
                      child: TextButton(
                          onPressed: store.busy ? null : store.load,
                          child: const LText('Tekrar dene')),
                    ),
                  ],
                  const SizedBox(height: 28),
                  _benefits(),
                  const SizedBox(height: 24),
                  _comparison(),
                  const SizedBox(height: 28),
                  if (store.active)
                    _activeCard()
                  else if (store.products.isEmpty && !store.busy)
                    // Without this the page ends in a hole: the plans are
                    // what fills it, and there are none to draw.
                    _unavailable()
                  else
                    ..._plans(),
                  if (store.busy)
                    const Padding(
                        padding: EdgeInsets.only(top: 18),
                        child: Center(child: CircularProgressIndicator())),
                  const SizedBox(height: 10),
                  _footer(),
                ]),
          ));

  Widget _hero() => Column(children: [
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xff6b5433), Color(0xff2e2419)]),
            border: Border.all(color: _gold, width: 1.4),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x55000000), blurRadius: 18, offset: Offset(0, 8))
            ],
          ),
          child: const Icon(Icons.workspace_premium_rounded,
              size: 44, color: _gold),
        ),
        const SizedBox(height: 18),
        const LText('Sınırsız asistan, sınırsız analiz',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: _bone,
                fontSize: 26,
                height: 1.2,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        const LText(
            'Günlük sınır olmadan oyna, her maçını motorla incele ve gelişimini hızlandır.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, fontSize: 14.5, height: 1.45)),
      ]);

  static final _panel = BoxDecoration(
      color: const Color(0x33000000),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xff6c6257)));

  Widget _benefits() => Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
      decoration: _panel,
      child: const Column(children: [
        _Benefit(
            icon: Icons.auto_awesome_rounded,
            title: 'Sınırsız asistanlı maç',
            detail: 'Her oyunda yanında, günde bir maçla sınırlı kalmadan.'),
        _Benefit(
            icon: Icons.insights_rounded,
            title: 'Sınırsız maç analizi',
            detail: 'Oynadığın her partiyi hamle hamle motora inceletebilirsin.'),
        _Benefit(
            icon: Icons.bolt_rounded,
            title: 'Beklemeden devam',
            detail: 'Hakkın dolduğunda gece yarısını beklemene gerek kalmaz.'),
        _Benefit(
            icon: Icons.favorite_rounded,
            title: 'Geliştirmeyi destekle',
            detail: 'ROK reklamsız. Abonelik, geliştirilmeye devam etmesini sağlar.'),
      ]));

  Widget _comparison() => Container(
        padding: const EdgeInsets.all(16),
        decoration: _panel,
        child: const Column(children: [
          Row(children: [
            Expanded(flex: 4, child: SizedBox()),
            Expanded(
                flex: 3,
                child: LText('Ücretsiz',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: _muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700))),
            Expanded(
                flex: 3,
                child: LText('Premium',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: _gold,
                        fontSize: 12,
                        fontWeight: FontWeight.w700))),
          ]),
          Divider(height: 18, color: Color(0x33f3eee7)),
          _CompareRow(label: 'Asistanlı maç', free: 'günde 1'),
          _CompareRow(label: 'Maç analizi', free: 'günde 1'),
          _CompareRow(
              label: 'Çevrimiçi oyun', free: 'sınırsız', both: true),
          _CompareRow(label: 'Bulmacalar', free: 'sınırsız', both: true),
          _CompareRow(
              label: 'Tüm tahta ve taş temaları', free: 'açık', both: true),
        ]),
      );

  List<Widget> _plans() => [
        for (final product in store.products) ...[
          _PlanCard(
            title: (product['title'] as String?)?.trim().isNotEmpty == true
                ? product['title'] as String
                : null,
            yearly: (product['id'] as String).endsWith('.yearly'),
            price: product['price'] as String? ?? '',
            onTap: store.busy
                ? null
                : () => store.purchase(product['id'] as String),
          ),
          const SizedBox(height: 12),
        ],
      ];

  Widget _unavailable() => Container(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
        decoration: _panel,
        child: Column(children: [
          const Icon(Icons.schedule_rounded, color: _gold, size: 30),
          const SizedBox(height: 12),
          const LText('Abonelik yakında',
              style: TextStyle(
                  color: _bone, fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const LText(
              'Premium henüz satışa açılmadı. O zamana kadar asistan ve analiz günde bir kez herkese açık.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _muted, fontSize: 13.5, height: 1.45)),
          const SizedBox(height: 6),
          TextButton(
              onPressed: store.busy ? null : store.load,
              child: const LText('Tekrar dene')),
        ]),
      );

  Widget _activeCard() => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: const Color(0x222e7d32),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xff6fd38a))),
        child: const Row(children: [
          Icon(Icons.verified_rounded, color: Color(0xff6fd38a), size: 28),
          SizedBox(width: 14),
          Expanded(
            child: LText('Aboneliğin etkin. Sınırsız kullanımın hazır.',
                style: TextStyle(
                    color: _bone, fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ]),
      );

  static final _footerButton = OutlinedButton.styleFrom(
      foregroundColor: _bone,
      backgroundColor: const Color(0x33000000),
      padding: const EdgeInsets.symmetric(vertical: 13),
      side: const BorderSide(color: Color(0xff6c6257)));

  Widget _footer() => Column(children: [
        Row(children: [
          Expanded(
            child: OutlinedButton(
                onPressed: store.busy ? null : store.restore,
                style: _footerButton,
                child: const LText('Satın alımları geri yükle',
                    textAlign: TextAlign.center)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton(
                onPressed: () =>
                    _link('https://apps.apple.com/account/subscriptions'),
                style: _footerButton,
                child: const LText('Aboneliği yönet',
                    textAlign: TextAlign.center)),
          ),
        ]),
        const SizedBox(height: 14),
        const LText(
            'Ödeme Apple hesabından alınır. Abonelik iptal edilmedikçe otomatik yenilenir. Aboneliğini Apple hesap ayarlarından yönetebilir veya iptal edebilirsin.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, fontSize: 11.5, height: 1.5)),
        const SizedBox(height: 6),
        Wrap(alignment: WrapAlignment.center, children: [
          TextButton(
              onPressed: () =>
                  _link('https://cenkgrs.github.io/rok-site/privacy.html'),
              child: const LText('Gizlilik Politikası',
                  style: TextStyle(fontSize: 12.5))),
          TextButton(
              onPressed: () => _link(
                  'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/'),
              child: const LText('Kullanım koşulları',
                  style: TextStyle(fontSize: 12.5))),
        ]),
      ]);
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.title, required this.detail});

  final IconData icon;
  final String title, detail;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
                color: const Color(0x33e2b75f),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: _SubscriptionScreenState._gold, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              LText(title,
                  style: const TextStyle(
                      color: rokBone,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 3),
              LText(detail,
                  style: const TextStyle(
                      color: _SubscriptionScreenState._muted,
                      fontSize: 13,
                      height: 1.4)),
            ]),
          ),
        ]),
      );
}

class _CompareRow extends StatelessWidget {
  const _CompareRow({required this.label, required this.free, this.both = false});

  final String label, free;

  /// Both tiers already get this, so Premium shows the same words, not a tick
  /// that would imply the free tier misses out.
  final bool both;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Expanded(
              flex: 4,
              child: LText(label,
                  style: const TextStyle(
                      color: rokBone, fontSize: 13.5, height: 1.3))),
          Expanded(
            flex: 3,
            child: LText(free,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: _SubscriptionScreenState._muted, fontSize: 12.5)),
          ),
          Expanded(
            flex: 3,
            child: both
                ? LText(free,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: _SubscriptionScreenState._muted, fontSize: 12.5))
                : const LText('sınırsız',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: _SubscriptionScreenState._gold,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700)),
          ),
        ]),
      );
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.yearly,
    required this.price,
    required this.onTap,
    this.title,
  });

  /// The store's own display name, when it has one.
  final String? title;
  final bool yearly;
  final String price;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor:
              yearly ? _SubscriptionScreenState._gold : const Color(0xff2b2722),
          foregroundColor: yearly ? const Color(0xff241c0f) : rokBone,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                  color: yearly
                      ? _SubscriptionScreenState._gold
                      : const Color(0xff6c6257))),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(children: [
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LText(title ?? (yearly ? 'Yıllık' : 'Aylık'),
                        style: const TextStyle(
                            fontSize: 16.5, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    LText(yearly ? '12 ay, tek ödeme' : '1 ay, her ay yenilenir',
                        style: TextStyle(
                            fontSize: 12,
                            color: yearly
                                ? const Color(0xcc241c0f)
                                : _SubscriptionScreenState._muted)),
                  ]),
            ),
            const SizedBox(width: 12),
            Text(price,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800)),
          ]),
        ),
      );
}
