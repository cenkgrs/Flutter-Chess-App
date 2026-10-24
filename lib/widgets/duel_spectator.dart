import 'dart:math' as math;

import 'package:chess/chess.dart' as c;
import 'package:flutter/material.dart';

import '../l10n/app_language.dart';
import '../theme/board_theme.dart';
import 'move_animation.dart';

/// The waiting half of a puzzle duel. While the opponent solves, the player
/// watches the same board the opponent is looking at, their clock running
/// down and their mistakes landing as they happen.
///
/// The position is safe to show: a match holds twenty distinct puzzles and
/// each turn belongs to one player, so nothing seen here is ever handed to
/// the spectator later in the match.

const _live = Color(0xff6fd38a);
const _warn = Color(0xffe6ad45);
const _danger = Color(0xffed5c59);

Color clockColor(int secondsLeft) =>
    secondsLeft <= 5 ? _danger : (secondsLeft <= 10 ? _warn : _live);

/// A 30-second turn clock drawn as a ring, with the seconds in the middle.
class DuelClockRing extends StatelessWidget {
  const DuelClockRing(
      {super.key, required this.secondsLeft, this.size = 56, this.total = 30});

  final int secondsLeft;
  final double size;
  final int total;

  @override
  Widget build(BuildContext context) {
    final color = clockColor(secondsLeft);
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 900),
        curve: Curves.linear,
        tween: Tween(end: (secondsLeft / total).clamp(0.0, 1.0)),
        builder: (context, value, _) => Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.expand(
              child: CircularProgressIndicator(
                value: value,
                strokeWidth: 4,
                backgroundColor: const Color(0x33ffffff),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            Text('$secondsLeft',
                style: TextStyle(
                    color: color,
                    fontSize: size * .34,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

/// One dot per move of the solution, filled as the solver gets them right.
class DuelProgressDots extends StatelessWidget {
  const DuelProgressDots(
      {super.key, required this.step, required this.steps, this.active = true});

  /// Moves already played, from the server's `step`.
  final int step;

  /// Length of the whole solution, including the opponent's replies.
  final int steps;
  final bool active;

  @override
  Widget build(BuildContext context) {
    // Only the solver's own moves are worth a dot; the replies are automatic.
    final total = math.max(1, (steps / 2).ceil());
    final done = (step / 2).floor().clamp(0, total);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < total; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            margin: const EdgeInsets.only(right: 6),
            width: i < done ? 11 : 9,
            height: i < done ? 11 : 9,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < done
                  ? (active ? _live : const Color(0xff9aa39b))
                  : const Color(0x33ffffff),
              border: i == done && active
                  ? Border.all(color: const Color(0x99ffffff), width: 1.4)
                  : null,
            ),
          ),
      ],
    );
  }
}

/// Mistake count that shakes and flashes red the moment it goes up.
class DuelMistakeCounter extends StatefulWidget {
  const DuelMistakeCounter({super.key, required this.mistakes});

  final int mistakes;

  @override
  State<DuelMistakeCounter> createState() => _DuelMistakeCounterState();
}

class _DuelMistakeCounterState extends State<DuelMistakeCounter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shake = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 420));

  @override
  void didUpdateWidget(DuelMistakeCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mistakes > oldWidget.mistakes) _shake.forward(from: 0);
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _shake,
        builder: (context, child) {
          final t = _shake.value;
          final offset = t == 0 ? 0.0 : math.sin(t * math.pi * 4) * 5 * (1 - t);
          return Transform.translate(
              offset: Offset(offset, 0),
              child: Opacity(opacity: 1, child: child));
        },
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.close_rounded,
              size: 16,
              color: widget.mistakes > 0 ? _danger : const Color(0x66ffffff)),
          const SizedBox(width: 4),
          LText('Hata: ${widget.mistakes}',
              style: TextStyle(
                  color: widget.mistakes > 0 ? _danger : Colors.white54,
                  fontWeight:
                      widget.mistakes > 0 ? FontWeight.w700 : FontWeight.w400)),
        ]),
      );
}

/// The opponent's board, live but untouchable, under a label that says so.
class SpectatorBoard extends StatelessWidget {
  const SpectatorBoard(
      {super.key, required this.board, required this.controller});

  final c.Chess board;
  final MoveAnimationController controller;

  @override
  Widget build(BuildContext context) {
    // The solver sees the board from their own side, so the spectator does
    // too; it is the opponent's turn that is on screen.
    final flipped = board.turn == c.Color.BLACK;
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(children: [
        IgnorePointer(
          child: AnimatedBoardPieces(
            position: boardPosition(board),
            flipped: flipped,
            controller: controller,
            pieceBuilder: (square) => BoardPiece(board.get(square)!),
            capturedPieceBuilder: (piece) => BoardPiece(piece),
            builder: (context, hidden) => GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 64,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8),
              itemBuilder: (_, display) {
                final i = flipped ? 63 - display : display;
                final square = '${'abcdefgh'[i % 8]}${8 - i ~/ 8}';
                final piece = board.get(square);
                final base = boardSkin.base((i ~/ 8 + i % 8).isEven);
                return ColoredBox(
                  color: controller.lastMove.contains(square)
                      ? Color.alphaBlend(boardSkin.lastMove, base)
                      : base,
                  child: piece == null || hidden.contains(square)
                      ? null
                      : BoardPiece(piece),
                );
              },
            ),
          ),
        ),
        const Positioned(
            left: 0, right: 0, bottom: 0, child: _WatchingBanner()),
      ]),
    );
  }
}

class _WatchingBanner extends StatefulWidget {
  const _WatchingBanner();

  @override
  State<_WatchingBanner> createState() => _WatchingBannerState();
}

class _WatchingBannerState extends State<_WatchingBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        color: const Color(0xaa161514),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          FadeTransition(
            opacity: Tween<double>(begin: .25, end: 1).animate(_pulse),
            child: const Icon(Icons.circle, size: 9, color: _live),
          ),
          const SizedBox(width: 8),
          const LText('CANLI · Rakibin tahtası',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w700)),
        ]),
      );
}

/// What a finished turn scored, thrown up over the board for a moment.
class TurnScoreBurst extends StatefulWidget {
  const TurnScoreBurst({super.key, required this.round, required this.mine});

  /// One entry of the server's `history`: `points`, `reason`, `seconds`.
  final Map<String, dynamic> round;

  /// Whether the round that just ended was the player's own.
  final bool mine;

  @override
  State<TurnScoreBurst> createState() => _TurnScoreBurstState();
}

class _TurnScoreBurstState extends State<TurnScoreBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _run = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1500))
    ..forward();

  @override
  void dispose() {
    _run.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final points = (widget.round['points'] as num?)?.toInt() ?? 0;
    final reason = widget.round['reason'] as String?;
    final solved = points > 0;
    final color = solved ? (widget.mine ? _live : _warn) : Colors.white54;
    final label = solved
        ? '+$points'
        : reason == 'timeout'
            ? 'Süre doldu'
            : 'Geçildi';
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _run,
        builder: (context, child) {
          final t = Curves.easeOut.transform(_run.value);
          return Opacity(
            opacity: (1 - math.pow(t, 3)).toDouble().clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, -38 * t),
              child: Transform.scale(scale: .7 + .5 * Curves.easeOutBack.transform(math.min(1, t * 2.2)), child: child),
            ),
          );
        },
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: solved ? 46 : 26,
                  fontWeight: FontWeight.w800,
                  shadows: const [
                    Shadow(color: Colors.black87, blurRadius: 14)
                  ])),
          LText(widget.mine ? 'Senin turun' : 'Rakibin turu',
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  letterSpacing: 1.3,
                  fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}

/// Live score, each side's number rolling up to its new value.
class DuelScoreboard extends StatelessWidget {
  const DuelScoreboard(
      {super.key, required this.mine, required this.theirs, this.leading});

  final int mine, theirs;

  /// Highlights whoever is ahead; null while the scores are level.
  final bool? leading;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _RollingScore(value: mine, highlight: leading == true),
          const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Text(':', style: TextStyle(color: Colors.white38, fontSize: 20))),
          _RollingScore(value: theirs, highlight: leading == false),
        ],
      );
}

class _RollingScore extends StatelessWidget {
  const _RollingScore({required this.value, required this.highlight});

  final int value;
  final bool highlight;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeOutCubic,
        tween: Tween(end: value.toDouble()),
        builder: (context, shown, _) => Text(
          '${shown.round()}',
          style: TextStyle(
              color: highlight ? _live : Colors.white,
              fontSize: 20,
              fontWeight: highlight ? FontWeight.w800 : FontWeight.w500),
        ),
      );
}
