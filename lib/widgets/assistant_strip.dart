import 'package:flutter/material.dart';

import '../l10n/app_language.dart';

/// The assistant's running commentary, as a speech balloon under the board.
///
/// It keeps talking on its own while the game goes on rather than waiting to
/// be asked, so the advice is already there when the player looks down. The
/// header is the only control: it collapses the balloon to a single line and
/// opens it again.
class AssistantStrip extends StatelessWidget {
  const AssistantStrip({
    super.key,
    required this.open,
    required this.onToggle,
    required this.headline,
    this.detail,
    this.variation = const [],
    this.move,
    this.thinking = false,
  });

  final bool open;
  final VoidCallback onToggle;

  /// The one line that always shows, collapsed or not.
  final String headline;

  /// The reasoning behind the suggestion.
  final String? detail;

  /// The line the engine expects to follow, in SAN.
  final List<String> variation;

  /// The suggested move, called out beside the text.
  final String? move;

  /// The engine is still working out what to say.
  final bool thinking;

  static const _ground = Color(0xf21e1c1a);
  static const _edge = Color(0xff6c6257);
  static const _bone = Color(0xfff3eee7);
  static const _muted = Color(0xffb9aea5);

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // The notch points back at the board the advice is about.
          const CustomPaint(
              size: Size(22, 9),
              painter: _NotchPainter(colour: _ground, edge: _edge)),
          Flexible(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: _ground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _edge, width: .9),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x66000000),
                      blurRadius: 14,
                      offset: Offset(0, 5))
                ],
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                _header(context),
                if (open && (detail != null || variation.isNotEmpty))
                  Flexible(child: _body()),
              ]),
            ),
          ),
        ],
      );

  Widget _header(BuildContext context) => Semantics(
        liveRegion: true,
        button: true,
        child: InkWell(
          key: const ValueKey('assistant-toggle'),
          onTap: onToggle,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 11, 10, 11),
            child: Row(children: [
              SizedBox(
                width: 18,
                height: 18,
                child: thinking
                    ? const CircularProgressIndicator(
                        strokeWidth: 2, color: _muted)
                    : const Icon(Icons.auto_awesome_rounded,
                        size: 18, color: _bone),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  child: LText(headline,
                      key: ValueKey(headline),
                      maxLines: open ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: _bone,
                          fontSize: 14,
                          height: 1.3,
                          fontWeight: FontWeight.w600)),
                ),
              ),
              if (move != null && !open) ...[
                const SizedBox(width: 8),
                _MoveChip(move!),
              ],
              const SizedBox(width: 4),
              Icon(open ? Icons.expand_more_rounded : Icons.expand_less_rounded,
                  color: _muted, size: 22),
            ]),
          ),
        ),
      );

  Widget _body() => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Divider(height: 12, thickness: .6, color: Color(0x33f3eee7)),
              if (move != null) ...[
                Row(children: [
                  _MoveChip(move!),
                  const SizedBox(width: 8),
                  const Flexible(
                      child: LText('önerilen hamle',
                          style: TextStyle(color: _muted, fontSize: 11.5))),
                ]),
                const SizedBox(height: 8),
              ],
              if (detail != null)
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  child: LText(detail!,
                      key: ValueKey(detail),
                      style: const TextStyle(
                          color: _muted, fontSize: 12.5, height: 1.45)),
                ),
              if (variation.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(spacing: 6, runSpacing: 4, children: [
                  const LText('Devamı:',
                      style: TextStyle(color: _muted, fontSize: 11.5)),
                  for (final san in variation)
                    Text(san,
                        style: const TextStyle(
                            color: _bone,
                            fontSize: 11.5,
                            fontFeatures: [FontFeature.tabularFigures()],
                            fontWeight: FontWeight.w600)),
                ]),
              ],
            ]),
      );
}

class _MoveChip extends StatelessWidget {
  const _MoveChip(this.move);

  final String move;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
            color: const Color(0xff3a332b),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: const Color(0xff8b7966))),
        child: Text(move,
            style: const TextStyle(
                color: Color(0xffffe2a9),
                fontSize: 13,
                fontWeight: FontWeight.w700)),
      );
}

class _NotchPainter extends CustomPainter {
  const _NotchPainter({required this.colour, required this.edge});

  final Color colour, edge;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = colour);
    canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = .9
          ..color = edge);
  }

  @override
  bool shouldRepaint(covariant _NotchPainter old) =>
      colour != old.colour || edge != old.edge;
}
