import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

import 'package:chess/chess.dart' as c;
import 'package:chess_puzzle_app/backend/feature_limits.dart';
import 'package:chess_puzzle_app/prototype/play_screen.dart';
import 'package:chess_puzzle_app/prototype/stockfish_engine.dart';
import 'package:chess_puzzle_app/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<EngineEvaluation> _fakeEngine(String fen, int elo) async {
  final move = c.Chess.fromFEN(fen).generate_moves().first;
  return EngineEvaluation(
      '${move.fromAlgebraic}${move.toAlgebraic}${move.promotion?.name ?? ''}',
      0,
      null);
}

/// Records every claim so a test can show that one game costs exactly one.
class _Limits extends DailyFeatureLimits {
  _Limits({required this.allow, this.pending});

  final Future<void>? pending;

  final bool allow;
  final claims = <String>[];

  @override
  Future<Map<DailyFeature, FeatureAllowance>> status() async => {
        for (final f in DailyFeature.values)
          f: FeatureAllowance(
              allowed: allow,
              used: allow ? 0 : 1,
              limit: 1,
              remaining: allow ? 1 : 0,
              resetsAt: DateTime.now().add(const Duration(hours: 7))),
      };

  @override
  Future<FeatureAllowance> claim(DailyFeature feature) async {
    claims.add(feature.key);
    await pending;
    return FeatureAllowance(
        allowed: allow,
        used: allow ? 1 : 1,
        limit: 1,
        remaining: allow ? 0 : 0,
        resetsAt: DateTime.now().add(const Duration(hours: 7)));
  }
}

/// Assistant mode runs a looping pulse animation, so `pumpAndSettle` never
/// returns there; these pumps advance past the async claim instead.
Future<void> _settleAssistant(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

/// Taps a square, then its destination, the way a player moves.
Future<void> move(WidgetTester tester, String from, String to) async {
  await tester.tap(find.byKey(ValueKey('square-$from')));
  await tester.pump();
  await tester.tap(find.byKey(ValueKey('square-$to')));
  await tester.pump();
}

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

List<Map<String, dynamic>> _moves() {
  final board = c.Chess();
  final moves = <Map<String, dynamic>>[];
  for (final san in ['e4', 'e5', 'Nf3']) {
    board.move(san);
    moves.add({'san': san, 'fen_after': board.fen});
  }
  return moves;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets('exhausted assistant allowance blocks entry before a game opens',
      (tester) async {
    _phone(tester);
    final limits = _Limits(allow: false);
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => TextButton(
                onPressed: () =>
                    PlayScreen.launchAssistant(context, limits: limits),
                child: const Text('Open assistant')))));
    await tester.tap(find.text('Open assistant'));
    await tester.pumpAndSettle();
    expect(find.text('Bugünlük asistan hakkın doldu'), findsOneWidget);
    expect(find.text('Abonelik seçenekleri'), findsOneWidget);
    expect(find.byType(PlayScreen), findsNothing);
    expect(limits.claims, isEmpty);
  });

  testWidgets('the assistant comments on its own and spends one use',
      (tester) async {
    _phone(tester);
    final limits = _Limits(allow: true);
    await tester.pumpWidget(MaterialApp(
        home: PlayScreen(
            assistantMode: true, evaluate: _fakeEngine, limits: limits)));
    await _settleAssistant(tester);

    // Nobody asked: the balloon opens with the board and talks by itself.
    expect(find.byKey(const ValueKey('assistant-strip')), findsOneWidget);
    expect(limits.claims, ['assistant_game']);
    expect(find.textContaining('Şimdi '), findsOneWidget);

    // Playing on refreshes the commentary without spending another use.
    await move(tester, 'e2', 'e4');
    await _settleAssistant(tester);
    expect(limits.claims, ['assistant_game']);
  });

  testWidgets('the balloon folds away and takes the board arrow with it',
      (tester) async {
    _phone(tester);
    final limits = _Limits(allow: true);
    await tester.pumpWidget(MaterialApp(
        home: PlayScreen(
            assistantMode: true, evaluate: _fakeEngine, limits: limits)));
    await _settleAssistant(tester);
    expect(find.byKey(const ValueKey('assistant-arrow')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('assistant-toggle')));
    await _settleAssistant(tester);

    // Collapsed: the headline stays, the reasoning and the arrow go.
    expect(find.byKey(const ValueKey('assistant-strip')), findsOneWidget);
    expect(find.byKey(const ValueKey('assistant-arrow')), findsNothing);
    expect(find.text('Devamı:'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('assistant-toggle')));
    await _settleAssistant(tester);
    expect(find.byKey(const ValueKey('assistant-arrow')), findsOneWidget);
  });

  testWidgets('a new game requires its own assistant allowance',
      (tester) async {
    _phone(tester);
    final limits = _Limits(allow: true);
    await tester.pumpWidget(MaterialApp(
        home: PlayScreen(
            assistantMode: true, evaluate: _fakeEngine, limits: limits)));
    await _settleAssistant(tester);
    expect(limits.claims, ['assistant_game']);

    final dynamic state = tester.state(find.byType(PlayScreen));
    final restart = state.newGame() as Future<void>;
    await _settleAssistant(tester);
    await tester.tap(find.text('Oyuna başla'));
    await _settleAssistant(tester);
    await restart;
    await _settleAssistant(tester);
    expect(limits.claims, ['assistant_game', 'assistant_game']);
  });

  testWidgets('a used-up assistant allowance says so instead of advising',
      (tester) async {
    _phone(tester);
    final limits = _Limits(allow: false);
    await tester.pumpWidget(MaterialApp(
        home: PlayScreen(
            assistantMode: true, evaluate: _fakeEngine, limits: limits)));
    await _settleAssistant(tester);

    expect(find.text('Bugünlük asistan hakkın doldu'), findsOneWidget);
    expect(
        find.text(
            'Bugünlük ücretsiz asistanlı maç hakkını kullandın. Abonelikle sınırsız asistanlı maç oynayabilirsin.'),
        findsOneWidget);
    expect(find.text('Hakkın 7 saat sonra yenilenir.'), findsOneWidget);
  });

  testWidgets('analysis asks for an allowance before running the engine',
      (tester) async {
    _phone(tester);
    final limits = _Limits(allow: false);
    var evaluated = 0;
    await tester.pumpWidget(MaterialApp(
        home: GameReviewScreen(
            game: const {},
            localMoves: _moves(),
            limits: limits,
            evaluate: (fen) async {
              evaluated++;
              return const EngineEvaluation(null, 0, null);
            })));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Motor analizi'));
    await tester.pumpAndSettle();

    expect(limits.claims, ['game_analysis']);
    expect(evaluated, 0, reason: 'the engine ran without an allowance');
    expect(find.text('Bugünlük analiz hakkın doldu'), findsOneWidget);
  });

  testWidgets('an allowed analysis runs and is charged once', (tester) async {
    _phone(tester);
    final limits = _Limits(allow: true);
    var evaluated = 0;
    await tester.pumpWidget(MaterialApp(
        home: GameReviewScreen(
            game: const {},
            localMoves: _moves(),
            limits: limits,
            evaluate: (fen) async {
              evaluated++;
              return const EngineEvaluation(null, 0, null);
            })));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Motor analizi'));
    await tester.pumpAndSettle();
    expect(limits.claims, ['game_analysis']);
    expect(evaluated, greaterThan(0));

    await tester.tap(find.text('Motor analizi'));
    await tester.pumpAndSettle();
    expect(limits.claims, ['game_analysis'],
        reason: 're-running the same game charged again');
  });

  testWidgets('a move during a pending claim does not spend a second use',
      (tester) async {
    _phone(tester);
    final response = Completer<void>();
    final limits = _Limits(allow: true, pending: response.future);
    await tester.pumpWidget(MaterialApp(
        home: PlayScreen(
            assistantMode: true, evaluate: _fakeEngine, limits: limits)));
    await tester.pump();

    // The opening claim is still in flight; playing must not start another.
    expect(limits.claims, ['assistant_game']);
    await move(tester, 'e2', 'e4');
    expect(limits.claims, ['assistant_game']);

    response.complete();
    await _settleAssistant(tester);
    expect(limits.claims, ['assistant_game']);
  });

  testWidgets('repeated analysis taps share the pending allowance check',
      (tester) async {
    _phone(tester);
    final response = Completer<void>();
    final limits = _Limits(allow: false, pending: response.future);
    var evaluated = 0;
    await tester.pumpWidget(MaterialApp(
        home: GameReviewScreen(
            game: const {},
            localMoves: _moves(),
            limits: limits,
            evaluate: (fen) async {
              evaluated++;
              return const EngineEvaluation(null, 0, null);
            })));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Motor analizi'));
    await tester.tap(find.text('Motor analizi'));
    expect(limits.claims, ['game_analysis']);
    expect(evaluated, 0);
    response.complete();
    await tester.pumpAndSettle();
    expect(find.text('Bugünlük analiz hakkın doldu'), findsOneWidget);
    await tester.tap(find.text('Tamam'));
    await tester.pumpAndSettle();
    // Refusal must release the guard so the player can try again.
    await tester.tap(find.text('Motor analizi'));
    await tester.pumpAndSettle();
    expect(limits.claims, ['game_analysis', 'game_analysis']);
    expect(evaluated, 0);
  });

  test('a backend failure grants the use rather than blocking play', () async {
    final limits = DailyFeatureLimits(
        signedIn: () => true,
        request: (name, params) async => throw StateError('offline'));
    final allowance = await limits.claim(DailyFeature.assistantGame);
    expect(allowance.allowed, isTrue);
    expect((await limits.claim(DailyFeature.assistantGame)).allowed, isFalse);
  });

  test('a guest gets one use per feature without a server account', () async {
    final calls = <String>[];
    final limits = DailyFeatureLimits(
        signedIn: () => false,
        request: (name, params) async {
          calls.add(name);
          return {'allowed': false, 'used': 1, 'limit': 1, 'remaining': 0};
        });

    for (final feature in DailyFeature.values) {
      expect((await limits.claim(feature)).allowed, isTrue);
      expect((await limits.claim(feature)).allowed, isFalse);
    }
    expect(calls, isEmpty, reason: 'a guest reached the server counter');
    expect((await limits.status()).values.every((a) => !a.allowed), isTrue);
  });

  test('a signed-in player is counted and can be refused', () async {
    final calls = <String>[];
    final limits = DailyFeatureLimits(
        signedIn: () => true,
        request: (name, params) async {
          calls.add('$name:${params['p_feature']}');
          return {'allowed': false, 'used': 1, 'limit': 1, 'remaining': 0};
        });

    expect((await limits.claim(DailyFeature.gameAnalysis)).allowed, isFalse);
    expect(calls, ['claim_daily_feature:game_analysis']);
  });
  test('paid access bypasses both device and account counters', () async {
    var calls = 0;
    final limits = DailyFeatureLimits(
        signedIn: () => true,
        premium: () async => true,
        request: (_, __) async {
          calls++;
          return {};
        });
    for (var i = 0; i < 3; i++) {
      for (final feature in DailyFeature.values) {
        expect((await limits.claim(feature)).allowed, isTrue);
      }
    }
    expect(calls, 0);
    expect((await limits.status()).values.every((a) => a.allowed), isTrue);
  });

  test('signing out and restarting cannot grant a second device use', () async {
    var signedIn = true;
    final limits = DailyFeatureLimits(
        signedIn: () => signedIn,
        premium: () async => false,
        request: (_, __) async =>
            {'allowed': true, 'used': 1, 'limit': 1, 'remaining': 0});
    expect((await limits.claim(DailyFeature.assistantGame)).allowed, isTrue);
    signedIn = false;
    final reopened = DailyFeatureLimits(
        signedIn: () => signedIn, premium: () async => false);
    expect((await reopened.claim(DailyFeature.assistantGame)).allowed, isFalse);
    expect((await reopened.claim(DailyFeature.gameAnalysis)).allowed, isTrue);
  });

  test('guest allowance resets at Istanbul midnight', () async {
    var now = DateTime.utc(2026, 10, 24, 20, 59);
    final limits = DailyFeatureLimits(
        signedIn: () => false, premium: () async => false, now: () => now);
    final first = await limits.claim(DailyFeature.assistantGame);
    expect(first.allowed, isTrue);
    expect(first.resetsAt!.toUtc(), DateTime.utc(2026, 10, 24, 21));
    expect((await limits.claim(DailyFeature.assistantGame)).allowed, isFalse);
    now = DateTime.utc(2026, 10, 24, 21);
    expect((await limits.claim(DailyFeature.assistantGame)).allowed, isTrue);
  });

  test('concurrent guest requests cannot spend one use twice', () async {
    final limits =
        DailyFeatureLimits(signedIn: () => false, premium: () async => false);
    final results = await Future.wait([
      limits.claim(DailyFeature.gameAnalysis),
      limits.claim(DailyFeature.gameAnalysis)
    ]);
    expect(results.where((a) => a.allowed).length, 1);
  });
}
