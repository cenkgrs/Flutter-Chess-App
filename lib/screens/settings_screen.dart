import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../audio/game_sounds.dart';
import '../backend/puzzle_reminder.dart';
import '../l10n/app_language.dart';
import '../theme/board_theme.dart';
import '../widgets/rok_style.dart';
import '../widgets/settings_rows.dart';
import 'board_theme_screen.dart';
import 'open_source_screen.dart';

/// Everything the player sets rather than is.
///
/// These choices used to sit in the profile page, below the player's own
/// record, which made one page answer two questions: who am I here, and
/// how do I want the app to behave. The profile keeps the first.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, this.openLink});

  /// Injected so a test can watch a link without opening a browser.
  final Future<bool> Function(Uri uri)? openLink;

  static final privacyUri =
      Uri.parse('https://cenkgrs.github.io/rok-site/privacy.html');
  static final supportUri =
      Uri.parse('https://cenkgrs.github.io/rok-site/support.html');

  Future<void> _openLink(BuildContext context, Uri uri) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final opened = await (openLink?.call(uri) ??
          launchUrl(uri, mode: LaunchMode.externalApplication));
      if (!opened) _failed(messenger);
    } catch (_) {
      _failed(messenger);
    }
  }

  void _failed(ScaffoldMessengerState messenger) => messenger.showSnackBar(
        const SnackBar(content: LText('Bağlantı açılamadı. Tekrar dene.')),
      );

  void _chooseLanguage(BuildContext context) => showDialog<void>(
      context: context,
      builder: (dialog) => RokWoodDialog(
          title: const LText('Dil'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            for (final option in <String?, String>{
              null: 'Cihaz dili',
              'tr': 'Türkçe',
              'en': 'English',
              'de': 'Deutsch',
              'ru': 'Русский'
            }.entries)
              ListTile(
                  title: LText(option.value),
                  trailing:
                      AppLanguage.instance.locale?.languageCode == option.key
                          ? const Icon(Icons.check)
                          : null,
                  onTap: () {
                    AppLanguage.instance.set(option.key);
                    Navigator.pop(dialog);
                  }),
          ])));

  @override
  Widget build(BuildContext context) => RokScaffold(
        appBar: AppBar(title: const LText('AYARLAR')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
            children: [
              const SettingsHeading('UYGULAMA'),
              const SizedBox(height: 10),
              ListenableBuilder(
                  listenable: AppLanguage.instance,
                  builder: (context, _) => SettingsLink(
                        key: const ValueKey('language-link'),
                        icon: Icons.language,
                        title: 'Dil',
                        subtitle:
                            AppLanguage.instance.locale?.languageCode
                                    .toUpperCase() ??
                                'Cihaz dili',
                        onTap: () => _chooseLanguage(context),
                      )),
              const SizedBox(height: 12),
              ListenableBuilder(
                  listenable: BoardTheme.instance,
                  builder: (context, _) => SettingsLink(
                        key: const ValueKey('board-theme-link'),
                        icon: Icons.grid_view_rounded,
                        title: 'Tahta görünümü',
                        subtitle:
                            '${tr(context, boardSkin.label)} · ${tr(context, boardPieces.label)}',
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const BoardThemeScreen())),
                      )),
              const SizedBox(height: 12),
              ListenableBuilder(
                  listenable: GameSounds.instance,
                  builder: (context, _) => SettingsSwitch(
                        key: const ValueKey('sound-effects-toggle'),
                        icon: GameSounds.instance.enabled
                            ? Icons.volume_up_rounded
                            : Icons.volume_off_rounded,
                        title: 'Ses efektleri',
                        subtitle: 'Hamle, oyun başlangıcı ve zafer sesleri',
                        value: GameSounds.instance.enabled,
                        onChanged: GameSounds.instance.setEnabled,
                      )),
              const SizedBox(height: 12),
              ListenableBuilder(
                  listenable: PuzzleReminder.instance,
                  builder: (context, _) => SettingsSwitch(
                        key: const ValueKey('puzzle-reminder-toggle'),
                        icon: PuzzleReminder.instance.enabled
                            ? Icons.notifications_active_rounded
                            : Icons.notifications_off_rounded,
                        title: 'Bulmaca hatırlatıcısı',
                        subtitle:
                            'Günün bulmacası çözülmediyse akşam haber ver',
                        value: PuzzleReminder.instance.enabled,
                        onChanged: (on) async {
                          await PuzzleReminder.instance.markAsked();
                          await PuzzleReminder.instance.setEnabled(on);
                        },
                      )),
              const SizedBox(height: 28),
              const SettingsHeading('HAKKINDA'),
              const SizedBox(height: 10),
              SettingsLink(
                icon: Icons.description_outlined,
                title: 'Açık kaynak lisansları',
                subtitle: 'Stockfish ve kullanılan kütüphaneler',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => OpenSourceScreen(openLink: openLink)),
                ),
              ),
              const SizedBox(height: 12),
              SettingsLink(
                key: const ValueKey('privacy-policy-link'),
                icon: Icons.policy_outlined,
                title: 'Gizlilik Politikası',
                subtitle: 'Verilerinin nasıl işlendiğini incele',
                onTap: () => _openLink(context, privacyUri),
              ),
              const SizedBox(height: 12),
              SettingsLink(
                key: const ValueKey('support-link'),
                icon: Icons.support_agent_outlined,
                title: 'Destek',
                subtitle: 'Yardım ve iletişim seçenekleri',
                onTap: () => _openLink(context, supportUri),
              ),
            ],
          ),
        ),
      );
}
