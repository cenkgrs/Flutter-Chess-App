import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_language.dart';
import '../legal/open_source_compliance.dart';
import '../widgets/rok_style.dart';

class OpenSourceScreen extends StatelessWidget {
  const OpenSourceScreen({super.key, this.openLink});

  final Future<bool> Function(Uri uri)? openLink;

  Future<void> _openSource(BuildContext context) async {
    try {
      final opened = await (openLink?.call(correspondingSourceUri) ??
          launchUrl(correspondingSourceUri,
              mode: LaunchMode.externalApplication));
      if (!opened && context.mounted) _showError(context);
    } catch (_) {
      if (context.mounted) _showError(context);
    }
  }

  void _showError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: LText('Bağlantı açılamadı. Tekrar dene.')),
    );
  }

  @override
  Widget build(BuildContext context) => RokScaffold(
        appBar: AppBar(
          title: const LText('Açık kaynak lisansları'),
          backgroundColor: Colors.transparent,
          foregroundColor: rokBone,
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              const Icon(Icons.code_rounded, color: rokBone, size: 52),
              const SizedBox(height: 18),
              const LText(
                'ROK ve uygulamaya bağlı Stockfish motoru GPL-3.0-or-later altında dağıtılır.',
                style: TextStyle(
                    color: rokBone, fontSize: 19, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              const LText(
                'Kaynağı inceleme, değiştirme ve aynı lisansla yeniden dağıtma hakkına sahipsin. Yazılım herhangi bir garanti olmadan sunulur.',
                style: TextStyle(color: Color(0xffd3cbc3), height: 1.45),
              ),
              const SizedBox(height: 18),
              SelectableText(
                '${tr(context, 'Kaynak revizyonu')}: $effectiveSourceRevision',
                key: const ValueKey('source-revision'),
                style: const TextStyle(color: Color(0xffd3cbc3)),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                key: const ValueKey('corresponding-source-link'),
                onPressed: () => _openSource(context),
                icon: const Icon(Icons.open_in_new_rounded),
                label: const LText('Tam kaynak kodunu aç'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => showLicensePage(
                  context: context,
                  applicationName: 'ROK',
                  applicationLegalese: 'GPL-3.0-or-later',
                ),
                icon: const Icon(Icons.description_outlined),
                label: const LText('GPL-3.0 lisansını görüntüle'),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              FutureBuilder<String>(
                future: rootBundle.loadString('STOCKFISH_NOTICES.md'),
                builder: (context, snapshot) => SelectableText(
                  snapshot.data ?? tr(context, 'Bildirimler yükleniyor…'),
                  style: const TextStyle(
                    color: Color(0xffb9aea5),
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
