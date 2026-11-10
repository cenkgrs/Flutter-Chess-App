import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_language.dart';
import '../widgets/rok_style.dart';

/// What ROK is, said once, before the player is left alone with it.
///
/// The app opened straight onto a menu of buttons: whoever arrived from
/// the App Store had to guess that the assistant exists, that the puzzle
/// changes daily, and that almost nothing needs an account. Four cards
/// say it, and the whole thing is skippable from the first one.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, this.onDone});

  /// Called when the tour is finished or skipped. The screen never pops
  /// itself: whoever showed it decides what comes next.
  final VoidCallback? onDone;

  static const seenKey = 'welcome_seen';

  /// Whether the tour still owes this device a showing. A failure to read
  /// the preferences counts as seen; a tour that reappears is worse than
  /// one that is missed.
  static Future<bool> isPending() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      return !(preferences.getBool(seenKey) ?? false);
    } catch (_) {
      return false;
    }
  }

  static Future<void> markSeen() async {
    try {
      await (await SharedPreferences.getInstance()).setBool(seenKey, true);
    } catch (_) {
      // A tour shown twice is a small cost; blocking the app is not.
    }
  }

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _pages = PageController();
  int _page = 0;

  static const _cards = <_Card>[
    _Card(
      icon: Icons.castle_rounded,
      title: 'Hoş geldin',
      body: 'Satranç oyna, çalış ve gelişimini takip et. Reklam yok, oyunu bölen hiçbir şey yok.',
    ),
    _Card(
      icon: Icons.auto_awesome_rounded,
      title: 'Yanında bir asistan',
      body: 'Oynarken hamleni sorabilir, maç bitince partiyi hamle hamle motora inceletebilirsin. Motor Stockfish.',
    ),
    _Card(
      icon: Icons.extension_rounded,
      title: 'Her gün yeni bulmaca',
      body: 'Günlük bulmacayı çöz, serini büyüt. Arkadaşınla bulmaca düellosu da yapabilirsin.',
    ),
    _Card(
      icon: Icons.public_rounded,
      title: 'Hazır olduğunda çevrimiçi',
      body: 'Bilgisayara karşı oynamak ve bulmacalar için hesap gerekmez. Hesap, çevrimiçi maç ve arkadaşlar için.',
    ),
  ];

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await WelcomeScreen.markSeen();
    widget.onDone?.call();
  }

  void _next() {
    if (_page == _cards.length - 1) {
      _finish();
    } else {
      _pages.nextPage(
          duration: const Duration(milliseconds: 260), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final last = _page == _cards.length - 1;
    return RokScaffold(
      body: SafeArea(
        child: Column(children: [
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              key: const ValueKey('welcome-skip'),
              onPressed: _finish,
              child: const LText('Atla',
                  style: TextStyle(color: Color(0xffb9aea5))),
            ),
          ),
          Expanded(
            child: PageView.builder(
              key: const ValueKey('welcome-pages'),
              controller: _pages,
              itemCount: _cards.length,
              onPageChanged: (page) => setState(() => _page = page),
              itemBuilder: (context, i) => _cards[i].build(context),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < _cards.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == _page ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _page
                        ? const Color(0xffe2b75f)
                        : const Color(0x55f3eee7),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const ValueKey('welcome-next'),
                onPressed: _next,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xffe2b75f),
                  foregroundColor: const Color(0xff241a12),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: LText(last ? 'Başla' : 'Devam',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _Card {
  const _Card({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title, body;

  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0x44000000),
                border: Border.all(color: const Color(0xff6d6356)),
              ),
              child: Icon(icon, size: 48, color: const Color(0xffe2b75f)),
            ),
            const SizedBox(height: 32),
            LText(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Color(0xfff3eee7),
                    fontSize: 25,
                    height: 1.2,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            LText(body,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Color(0xffb9aea5), fontSize: 15.5, height: 1.5)),
          ],
        ),
      );
}
