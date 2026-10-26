import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../backend/subscriptions.dart';
import '../l10n/app_language.dart';
import '../widgets/rok_style.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key, this.store});
  final SubscriptionStore? store;
  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen>
    with WidgetsBindingObserver {
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
          body: ListView(padding: const EdgeInsets.all(24), children: [
            const Icon(Icons.workspace_premium_rounded,
                size: 64, color: rokBone),
            const SizedBox(height: 20),
            const LText('Sınırsız asistanlı maç ve analiz',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const LText(
                'Misafirler ve ücretsiz üyeler günde bir asistanlı maç ve bir analiz yapabilir.',
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            if (store.active)
              const LText('Aboneliğin etkin. Sınırsız kullanımın hazır.',
                  textAlign: TextAlign.center)
            else
              for (final product in store.products) ...[
                FilledButton(
                    onPressed: store.busy
                        ? null
                        : () => store.purchase(product['id'] as String),
                    child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(children: [
                          LText((product['id'] as String).endsWith('.yearly')
                              ? 'Yıllık'
                              : 'Aylık'),
                          Text(product['price'] as String),
                        ]))),
                const SizedBox(height: 12),
              ],
            if (store.busy) const Center(child: CircularProgressIndicator()),
            if (store.error != null) ...[
              LText(store.error!, textAlign: TextAlign.center),
              TextButton(
                  onPressed: store.busy ? null : store.load,
                  child: const LText('Tekrar dene')),
            ],
            TextButton(
                onPressed: store.busy ? null : store.restore,
                child: const LText('Satın alımları geri yükle')),
            TextButton(
                onPressed: () =>
                    _link('https://apps.apple.com/account/subscriptions'),
                child: const LText('Aboneliği yönet')),
            const SizedBox(height: 20),
            const LText(
                'Ödeme Apple hesabından alınır. Abonelik iptal edilmedikçe otomatik yenilenir. Aboneliğini Apple hesap ayarlarından yönetebilir veya iptal edebilirsin.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12)),
            TextButton(
                onPressed: () =>
                    _link('https://cenkgrs.github.io/rok-site/privacy.html'),
                child: const LText('Gizlilik Politikası')),
            TextButton(
                onPressed: () => _link(
                    'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/'),
                child: const LText('Kullanım koşulları')),
          ])));
}
