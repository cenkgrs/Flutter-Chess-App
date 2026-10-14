import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../prototype/stockfish_engine.dart';

Color qualityColor(String quality) => switch (quality) {
      'En iyi' => const Color(0xff28c9bd),
      'İyi' => const Color(0xff62c978),
      'İsabetsizlik' => const Color(0xffe6ad45),
      _ => const Color(0xffed5c59),
    };

class QualityBadge extends StatelessWidget {
  const QualityBadge(this.quality, {super.key});
  final String quality;
  @override
  Widget build(BuildContext context) => Tooltip(
      message: quality,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
            color: qualityColor(quality),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1),
            boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 3)]),
        child: Icon(
            switch (quality) {
              'En iyi' => Icons.star_rounded,
              'İyi' => Icons.check_rounded,
              'İsabetsizlik' => Icons.remove_rounded,
              _ => Icons.close_rounded,
            },
            size: 15,
            color: const Color(0xff13201a)),
      ));
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
                  child: Text(label,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 11))),
            ])));
  }
}
