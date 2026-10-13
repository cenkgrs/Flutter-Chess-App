import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chess_puzzle_app/screens/puzzle_duel_screen.dart';

void main() {
  testWidgets('resume shows opponent turn without exposing board',
      (tester) async {
    await tester.pumpWidget(
        MaterialApp(home: PuzzleDuelScreen(request: (name, params) async {
      if (name == 'duel_profile') return {'rating': 1300, 'game_id': 'match'};
      return {
        'status': 'active',
        'turn': 2,
        'step': 0,
        'my_turn': false,
        'fen': null,
        'score': 125,
        'opponent_score': 0,
        'opponent': 'Bobby',
        'rating': 1300,
        'seconds_left': 100
      };
    })));
    await tester.pumpAndSettle();
    expect(find.text('125 : 0'), findsOneWidget);
    expect(find.text('Rakibin bulmacayı çözüyor…'), findsOneWidget);
    expect(find.byType(GridView), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('finished match exposes result rating and exit', (tester) async {
    await tester.pumpWidget(
        MaterialApp(home: PuzzleDuelScreen(request: (name, params) async {
      if (name == 'duel_profile') return {'rating': 1300, 'game_id': 'match'};
      return {
        'status': 'finished',
        'turn': 21,
        'step': 0,
        'my_turn': false,
        'fen': null,
        'score': 125,
        'opponent_score': 100,
        'opponent': 'Bobby',
        'rating': 1300,
        'delta': 16
      };
    })));
    await tester.pumpAndSettle();
    expect(find.text('Kazandın!'), findsOneWidget);
    expect(
        find.text('Rating değişimi: 16 · Yeni rating: 1316'), findsOneWidget);
    expect(find.text('MENÜYE DÖN'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('narrow screen shows own board and skip action', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
        MaterialApp(home: PuzzleDuelScreen(request: (name, params) async {
      if (name == 'duel_profile') return {'rating': 1200, 'game_id': 'match'};
      return {
        'status': 'active',
        'turn': 1,
        'step': 0,
        'my_turn': true,
        'mistakes': 0,
        'fen': '7k/8/5KQ1/8/8/8/8/8 w - - 0 1',
        'score': 0,
        'opponent_score': 0,
        'opponent': 'Bobby',
        'rating': 1200,
        'seconds_left': 120
      };
    })));
    await tester.pumpAndSettle();
    expect(find.byType(GridView), findsOneWidget);
    expect(find.text('Bu turu geç (0 puan)'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
