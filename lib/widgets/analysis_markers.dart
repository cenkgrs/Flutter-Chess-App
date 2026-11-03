import '../l10n/app_language.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../prototype/stockfish_engine.dart';

/// The five verdicts form one ordered scale, so the colours are a ramp whose
/// lightness falls from best to worst rather than five unrelated hues. That
/// ordering survives a greyscale print and colour-blind vision, and it is the
/// only part a glance actually reads; the glyph and the row's own label carry
/// the identity.
Color qualityColor(String quality) => switch (quality) {
      'En iyi' => const Color(0xff7fd8b4),
      'İyi' => const Color(0xffa9cf7a),
      'İsabetsizlik' => const Color(0xffdcb152),
      'Hata' => const Color(0xffcc7c3f),
      _ => const Color(0xffb4503f),
    };

IconData qualityIcon(String quality) => switch (quality) {
      'En iyi' => Icons.star_rounded,
      'İyi' => Icons.check_rounded,
      'İsabetsizlik' => Icons.remove_rounded,
      'Hata' => Icons.priority_high_rounded,
      _ => Icons.close_rounded,
    };

class QualityBadge extends StatelessWidget {
  const QualityBadge(this.quality, {super.key, this.size = 20});
  final String quality;
  final double size;

  static const _ink = Color(0xff241a12);

  @override
  Widget build(BuildContext context) => Tooltip(
        message: quality,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: qualityColor(quality),
            shape: BoxShape.circle,
            // A ring in the board's own ink instead of a white outline and a
            // blurred halo: the badge sits over pieces and squares, and the
            // glow was what made it look pasted on.
            border: Border.all(color: _ink, width: size * .07),
          ),
          child: Icon(
            qualityIcon(quality),
            size: size * .66,
            color: _ink,
          ),
        ),
      );
}

double whiteAdvantage(EngineEvaluation evaluation, bool whiteToMove) {
  final score = evaluation.score * (whiteToMove ? 1 : -1);
  if (evaluation.mate != null) return score > 0 ? 1 : 0;
  return 1 / (1 + math.exp(-score.clamp(-2000, 2000) / 250));
}

class EvaluationBar extends StatelessWidget {
  const EvaluationBar(
      {super.key, required this.evaluation, required this.whiteToMove});
  final EngineEvaluation? evaluation;
  final bool whiteToMove;
  @override
  Widget build(BuildContext context) {
    final value = evaluation;
    final white = value == null ? .5 : whiteAdvantage(value, whiteToMove);
    final score = value == null ? 0 : value.score * (whiteToMove ? 1 : -1);
    final label = value == null
        ? '—'
        : value.mate != null
            ? '${score > 0 ? '+' : '−'}M${value.mate!.abs()}'
            : '${score > 0 ? '+' : ''}${(score / 100).toStringAsFixed(1)}';
    return Semantics(
        label: 'Beyaz açısından değerlendirme: $label',
        child: SizedBox(
            width: 30,
            child: Column(children: [
              Expanded(
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: LayoutBuilder(
                          builder: (_, constraints) => Stack(children: [
                                const Positioned.fill(
                                    child:
                                        ColoredBox(color: Color(0xff171717))),
                                AnimatedPositioned(
                                    duration: const Duration(milliseconds: 250),
                                    curve: Curves.easeOut,
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    height: constraints.maxHeight * white,
                                    child: const ColoredBox(
                                        color: Color(0xfffaf8f2))),
                                Positioned(
                                    top: constraints.maxHeight / 2,
                                    left: 0,
                                    right: 0,
                                    child: const Divider(
                                        height: 1, color: Colors.grey)),
                              ])))),
              const SizedBox(height: 5),
              FittedBox(
                  child: LText(label,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 11))),
            ])));
  }
}
