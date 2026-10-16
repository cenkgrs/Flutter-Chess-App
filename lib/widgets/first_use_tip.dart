import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_language.dart';
import 'rok_style.dart';

/// A dismissible hint card that is shown until the player closes it once.
/// It never blocks the board: when the stored flag cannot be read it simply
/// stays hidden.
class FirstUseTip extends StatefulWidget {
  const FirstUseTip({
    super.key,
    required this.id,
    required this.icon,
    required this.message,
  });

  final String id;
  final IconData icon;
  final String message;

  @override
  State<FirstUseTip> createState() => _FirstUseTipState();
}

class _FirstUseTipState extends State<FirstUseTip> {
  bool _visible = false;

  String get _key => 'first_use_tip_${widget.id}';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      if (mounted && preferences.getBool(_key) != true) {
        setState(() => _visible = true);
      }
    } catch (_) {
      // Without storage the tip would reappear forever; keep it hidden.
    }
  }

  Future<void> _dismiss() async {
    setState(() => _visible = false);
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool(_key, true);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: !_visible
            ? const SizedBox.shrink()
            : Material(
                key: ValueKey('first-use-tip-${widget.id}'),
                color: const Color(0xf0302620),
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Color(0xff8b7966)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
                  child: Row(children: [
                    Icon(widget.icon, color: rokBone, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: LText(widget.message,
                          style: const TextStyle(
                              color: rokBone, fontSize: 13, height: 1.3)),
                    ),
                    TextButton(
                      onPressed: _dismiss,
                      child: const LText('Anladım'),
                    ),
                  ]),
                ),
              ),
      );
}
