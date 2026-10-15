import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chess_puzzle_app/screens/puzzle_duel_screen.dart';

void main() {
  testWidgets('result has round details and rematch request waits for consent',
      (tester) async {
    String? requested;
    await tester.pumpWidget(MaterialApp(
        home: PuzzleDuelScreen(
            gameId: 'match',
            request: (name, params) async {
              if (name == 'duel_rematch') {
                requested = name;
                return {
                  'status': 'pending',
                  'incoming': false,
                  'game_id': null
                };
              }
              if (name == 'duel_rematch_status') return {'status': 'none'};
              return {
                'status': 'finished',
                'turn': 21,
                'step': 0,
                'score': 140,
                'opponent_score': 0,
                'opponent': 'Bobby',
                'rating': 1200,
                'delta': 16,
                'opponent_rating': 1200,
                'opponent_delta': -16,
                'is_a': true,
                'history': [
                  {
                    'turn': 1,
                    'seconds': 8.5,
                    'mistakes': 1,
                    'points': 70,
                    'reason': 'move'
                  }
                ]
              };
            })));
    await tester.pumpAndSettle();
    expect(find.text('8.5 sn · 1 hata · Çözüldü'), findsOneWidget);
    await tester.ensureVisible(find.text('RÖVANŞ'));
    await tester.tap(find.text('RÖVANŞ'));
    await tester.pumpAndSettle();
    expect(requested, 'duel_rematch');
    expect(find.text('RAKİBİN YANITI BEKLENİYOR'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('lobby uses wood matchmaking layout and cancel button',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: PuzzleDuelScreen(
            request: (name, params) async => {'rating': 1200})));
    await tester.pumpAndSettle();
    expect(find.text('BULMACA DÜELLOSU'), findsOneWidget);
    await tester.tap(find.text('RAKİP ARA'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('RAKİP ARANIYOR'), findsOneWidget);
    expect(find.text('ARAMAYI İPTAL ET'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
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
        'seconds_left': 30
      };
    })));
    await tester.pumpAndSettle();
    expect(find.byType(GridView), findsOneWidget);
    expect(find.text('Bu turu geç (0 puan)'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('leaving an active duel confirms and forfeits exactly once',
      (tester) async {
    var forfeits = 0;
    await tester.pumpWidget(MaterialApp(
        home: PuzzleDuelScreen(
            gameId: 'match',
            request: (name, params) async {
              if (name == 'duel_forfeit') {
                forfeits++;
                return <String, dynamic>{};
              }
              return {
                'status': 'active',
                'turn': 2,
                'step': 0,
                'my_turn': false,
                'fen': null,
                'score': 0,
                'opponent_score': 0,
                'opponent': 'Bobby',
                'rating': 1200,
                'seconds_left': 30,
              };
            })));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('Düellodan çıkmak istiyor musun?'), findsOneWidget);
    await tester.tap(find.text('Düellodan çık'));
    await tester.pumpAndSettle();
    expect(forfeits, 1);
  });
}
