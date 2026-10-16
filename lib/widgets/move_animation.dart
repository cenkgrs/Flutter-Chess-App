import 'package:chess/chess.dart' as c;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Square → piece code (`wp`, `bq`, …) for every occupied square.
Map<String, String> boardPosition(c.Chess game) {
  final position = <String, String>{};
  for (final file in 'abcdefgh'.split('')) {
    for (var rank = 1; rank <= 8; rank++) {
      final square = '$file$rank';
      final piece = game.get(square);
      if (piece != null) {
        position[square] =
            '${piece.color == c.Color.WHITE ? 'w' : 'b'}${piece.type.name}';
      }
    }
  }
  return position;
}

/// Whether a piece left the board between two positions (captures,
/// including en passant).
bool capturedBetween(c.Chess before, c.Chess after) =>
    boardPosition(after).length < boardPosition(before).length;

/// Lets a board skip the slide for a move the player already dragged into
/// place, so the piece does not jump back to its origin and slide again, and
/// tells the board which squares the most recent move used.
class MoveAnimationController {
  String? _droppedOn;
  Set<String> _lastMove = const {};

  void skipNextTo(String square) => _droppedOn = square;
  void clearSkip() => _droppedOn = null;

  /// Origin and destination of the latest move seen on the board (the king's
  /// squares when castling); empty after a new game or a resync.
  Set<String> get lastMove => _lastMove;
}

class _Slide {
  const _Slide(this.from, this.to, this.code);

  final String from;
  final String to;
  final String code;
}

class _Diff {
  const _Diff(this.slides, this.captured);

  static const none = _Diff([], {});

  final List<_Slide> slides;

  /// Square → piece code of every piece that left the board.
  final Map<String, String> captured;
}

const _pieceTypes = {
  'p': c.PieceType.PAWN,
  'n': c.PieceType.KNIGHT,
  'b': c.PieceType.BISHOP,
  'r': c.PieceType.ROOK,
  'q': c.PieceType.QUEEN,
  'k': c.PieceType.KING,
};

c.Piece _pieceFromCode(String code) => c.Piece(
    _pieceTypes[code[1]]!, code[0] == 'w' ? c.Color.WHITE : c.Color.BLACK);

/// Slides pieces from their previous square to their new one whenever
/// [position] changes, by diffing the old and new boards. The grid is drawn
/// by [builder], which must hide the pieces on the `hidden` squares while
/// they are still travelling; [pieceBuilder] draws the travelling piece that
/// now stands on the given square. With [capturedPieceBuilder], a captured
/// piece stays on its square until the attacker arrives, then fades out.
class AnimatedBoardPieces extends StatefulWidget {
  const AnimatedBoardPieces({
    super.key,
    required this.position,
    required this.flipped,
    required this.pieceBuilder,
    required this.builder,
    this.capturedPieceBuilder,
    this.controller,
    this.duration = const Duration(milliseconds: 220),
  });

  final Map<String, String> position;
  final bool flipped;
  final Widget Function(String square) pieceBuilder;
  final Widget Function(BuildContext context, Set<String> hidden) builder;
  final Widget Function(c.Piece piece)? capturedPieceBuilder;
  final MoveAnimationController? controller;
  final Duration duration;

  @override
  State<AnimatedBoardPieces> createState() => _AnimatedBoardPiecesState();
}

class _AnimatedBoardPiecesState extends State<AnimatedBoardPieces>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress =
      AnimationController(vsync: this, duration: widget.duration)
        ..addStatusListener((status) {
          if (status == AnimationStatus.completed && mounted) {
            setState(() {
              _slides = const [];
              _captured = const {};
            });
          }
        });
  late final Animation<double> _curve =
      CurvedAnimation(parent: _progress, curve: Curves.easeInOutCubic);
  // The captured piece disappears during the last part of the slide.
  late final Animation<double> _captureFade = ReverseAnimation(
      CurvedAnimation(parent: _progress, curve: const Interval(.7, 1)));
  List<_Slide> _slides = const [];
  Map<String, String> _captured = const {};

  @override
  void didUpdateWidget(AnimatedBoardPieces oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (mapEquals(oldWidget.position, widget.position)) return;
    final controller = widget.controller;
    final droppedOn = controller?._droppedOn;
    controller?.clearSkip();
    final diff = _diff(oldWidget.position, widget.position);
    if (controller != null) {
      final move = diff.slides.length == 1
          ? diff.slides.single
          : diff.slides.where((s) => s.code[1] == 'k').firstOrNull;
      controller._lastMove = move == null ? const {} : {move.from, move.to};
    }
    final slides = diff.slides.where((slide) => slide.to != droppedOn).toList();
    _slides = slides;
    _captured = slides.isEmpty || widget.capturedPieceBuilder == null
        ? const {}
        : diff.captured;
    if (slides.isEmpty) {
      _progress.stop();
    } else {
      _progress.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  static int _file(String square) => square.codeUnitAt(0) - 97;
  static int _rank(String square) => square.codeUnitAt(1) - 49;

  static _Diff _diff(Map<String, String> before, Map<String, String> after) {
    final vacated = [
      for (final entry in before.entries)
        if (after[entry.key] != entry.value) entry.key
    ];
    final arrived = [
      for (final entry in after.entries)
        if (before[entry.key] != entry.value) entry.key
    ];
    // A single move touches at most two arrival squares (castling). Anything
    // larger is a new game, a takeback series or a resync: show it at once.
    if (arrived.isEmpty || arrived.length > 2) return _Diff.none;
    final slides = <_Slide>[];
    for (final to in arrived) {
      final code = after[to]!;
      bool samePiece(String from) => before[from] == code;
      bool promotedPawn(String from) =>
          code[1] != 'p' && before[from] == '${code[0]}p';
      final candidates = vacated.where(samePiece).toList();
      if (candidates.isEmpty) candidates.addAll(vacated.where(promotedPawn));
      if (candidates.isEmpty) continue;
      int distance(String from) =>
          (_file(from) - _file(to)).abs() + (_rank(from) - _rank(to)).abs();
      candidates.sort((a, b) => distance(a).compareTo(distance(b)));
      vacated.remove(candidates.first);
      slides.add(_Slide(candidates.first, to, code));
    }
    // Whatever was vacated without moving elsewhere was captured: the
    // destination square of a normal capture, or the en passant square.
    return _Diff(
        slides, {for (final square in vacated) square: before[square]!});
  }

  Offset _offset(String square, Size cell) {
    var column = _file(square);
    var row = 7 - _rank(square);
    if (widget.flipped) {
      column = 7 - column;
      row = 7 - row;
    }
    return Offset(column * cell.width, row * cell.height);
  }

  @override
  Widget build(BuildContext context) {
    final slides = _slides;
    // Keep the same tree shape with or without slides so the grid below is
    // never remounted when an animation starts or ends.
    return LayoutBuilder(builder: (context, box) {
      final cell = Size(box.maxWidth / 8, box.maxHeight / 8);
      return Stack(children: [
        widget.builder(context, {for (final s in slides) s.to}),
        for (final entry in _captured.entries)
          Positioned(
            left: _offset(entry.key, cell).dx,
            top: _offset(entry.key, cell).dy,
            width: cell.width,
            height: cell.height,
            child: IgnorePointer(
              child: FadeTransition(
                opacity: _captureFade,
                child: Center(
                  child:
                      widget.capturedPieceBuilder!(_pieceFromCode(entry.value)),
                ),
              ),
            ),
          ),
        for (final slide in slides)
          AnimatedBuilder(
            animation: _curve,
            builder: (context, child) {
              final offset = Offset.lerp(_offset(slide.from, cell),
                  _offset(slide.to, cell), _curve.value)!;
              return Positioned(
                left: offset.dx,
                top: offset.dy,
                width: cell.width,
                height: cell.height,
                child: child!,
              );
            },
            child: IgnorePointer(
              child: Center(child: widget.pieceBuilder(slide.to)),
            ),
          ),
      ]);
    });
  }
}
