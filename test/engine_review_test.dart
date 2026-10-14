import 'package:chess_puzzle_app/prototype/stockfish_engine.dart';
import 'package:chess_puzzle_app/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chess/chess.dart' as c;
import 'package:chess_puzzle_app/widgets/analysis_markers.dart';

void main() {
  test('Evaluation bar always uses white perspective', () {
    expect(whiteAdvantage(const EngineEvaluation(null, 0, null), true), .5);
    expect(whiteAdvantage(const EngineEvaluation(null, 300, null), true),
        greaterThan(.5));
    expect(whiteAdvantage(const EngineEvaluation(null, 300, null), false),
        lessThan(.5));
    expect(whiteAdvantage(const EngineEvaluation(null, null, -1), false), 1);
  });
  testWidgets('Black player only gets black move labels and destination badge',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final board = c.Chess();
    final moves = <Map<String, dynamic>>[];
    for (final san in ['e4', 'e5']) {
      board.move(san);
      moves.add({'san': san, 'fen_after': board.fen});
    }
    await tester.pumpWidget(MaterialApp(
        home: GameReviewScreen(
            game: const {},
            localMoves: moves,
            playerColor: c.Color.BLACK,
            evaluate: (_) async => const EngineEvaluation('a2a3', 0, null))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Motor analizi'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Senin hamlelerin (Siyah):'), findsOneWidget);
    expect(find.byType(QualityBadge), findsOneWidget); // list: black only
    await tester.tap(find.byIcon(Icons.last_page));
    await tester.pumpAndSettle();
    expect(find.byType(QualityBadge), findsNWidgets(2)); // list + board
    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();
    expect(
        find.byType(QualityBadge), findsOneWidget); // opponent: no board badge
    expect(tester.takeException(), isNull);
  });
  test('Centipawn loss boundaries are explicit', () {
    expect(moveQuality(0, best: true), 'En iyi');
    expect(moveQuality(30, best: false), 'İyi');
    expect(moveQuality(31, best: false), 'İsabetsizlik');
    expect(moveQuality(101, best: false), 'Hata');
    expect(moveQuality(251, best: false), 'Büyük hata');
    expect(const EngineEvaluation(null, null, -1).score, -100000);
  });
  testWidgets('Review fits phone and exposes continuation strength picker',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
        const MaterialApp(home: GameReviewScreen(game: {}, localMoves: [])));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Buradan bilgisayarla devam et'));
    await tester.pumpAndSettle();
    expect(find.text('Stockfish gücü'), findsOneWidget);
    expect(find.text('1320'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
