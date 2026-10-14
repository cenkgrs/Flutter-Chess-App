import 'package:chess_puzzle_app/prototype/stockfish_engine.dart';
import 'package:chess_puzzle_app/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
