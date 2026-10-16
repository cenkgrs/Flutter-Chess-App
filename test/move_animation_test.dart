import 'package:chess/chess.dart' as c;
import 'package:chess_puzzle_app/widgets/move_animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Draws each piece as a keyed box so the test can find where it is.
class _Board extends StatelessWidget {
  const _Board({required this.game, this.controller});

  final c.Chess game;
  final MoveAnimationController? controller;

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 400,
            height: 400,
            child: AnimatedBoardPieces(
              position: boardPosition(game),
              flipped: false,
              controller: controller,
              pieceBuilder: (square) =>
                  SizedBox.expand(key: ValueKey('moving-$square')),
              builder: (context, hidden) => Stack(children: [
                for (final square in boardPosition(game).keys)
                  if (!hidden.contains(square))
                    SizedBox(key: ValueKey('static-$square')),
              ]),
            ),
          ),
        ),
      );
}

c.Chess _after(String fen, String uci) => c.Chess.fromFEN(fen)
  ..move({
    'from': uci.substring(0, 2),
    'to': uci.substring(2, 4),
    if (uci.length > 4) 'promotion': uci.substring(4),
  });

void main() {
  testWidgets('slides the moved piece and then shows it on its square',
      (tester) async {
    final start = c.Chess();
    await tester.pumpWidget(_Board(game: start));
    await tester.pumpWidget(_Board(game: _after(start.fen, 'e2e4')));

    expect(find.byKey(const ValueKey('moving-e4')), findsOneWidget);
    expect(find.byKey(const ValueKey('static-e4')), findsNothing);
    final startLeft =
        tester.getTopLeft(find.byKey(const ValueKey('moving-e4')));

    await tester.pump(const Duration(milliseconds: 110));
    final midway = tester.getTopLeft(find.byKey(const ValueKey('moving-e4')));
    expect(midway.dy, lessThan(startLeft.dy));

    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('moving-e4')), findsNothing);
    expect(find.byKey(const ValueKey('static-e4')), findsOneWidget);
  });

  testWidgets('slides king and rook when castling', (tester) async {
    const fen = 'r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1';
    await tester.pumpWidget(_Board(game: c.Chess.fromFEN(fen)));
    await tester.pumpWidget(_Board(game: _after(fen, 'e1g1')));

    expect(find.byKey(const ValueKey('moving-g1')), findsOneWidget);
    expect(find.byKey(const ValueKey('moving-f1')), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('slides a promoting pawn into its new piece', (tester) async {
    const fen = '7k/P7/8/8/8/8/8/K7 w - - 0 1';
    await tester.pumpWidget(_Board(game: c.Chess.fromFEN(fen)));
    await tester.pumpWidget(_Board(game: _after(fen, 'a7a8q')));

    expect(find.byKey(const ValueKey('moving-a8')), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('does not slide a piece the player dropped in place',
      (tester) async {
    final start = c.Chess();
    final controller = MoveAnimationController();
    await tester.pumpWidget(_Board(game: start, controller: controller));
    controller.skipNextTo('e4');
    await tester.pumpWidget(
        _Board(game: _after(start.fen, 'e2e4'), controller: controller));

    expect(find.byKey(const ValueKey('moving-e4')), findsNothing);
    expect(find.byKey(const ValueKey('static-e4')), findsOneWidget);
  });

  testWidgets('shows a new game at once', (tester) async {
    const fen = '7k/8/8/8/8/8/8/K7 w - - 0 1';
    await tester.pumpWidget(_Board(game: c.Chess.fromFEN(fen)));
    await tester.pumpWidget(_Board(game: c.Chess()));

    expect(find.byWidgetPredicate((w) {
      final key = w.key;
      return key is ValueKey<String> && key.value.startsWith('moving-');
    }), findsNothing);
  });

  test('detects captures including en passant', () {
    const enPassant = '4k3/8/8/3pP3/8/8/8/4K3 w - d6 0 1';
    expect(
        capturedBetween(c.Chess.fromFEN(enPassant), _after(enPassant, 'e5d6')),
        isTrue);
    final start = c.Chess();
    expect(capturedBetween(start, _after(start.fen, 'e2e4')), isFalse);
  });
}
