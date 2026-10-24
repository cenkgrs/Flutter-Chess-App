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
  _Limits({required this.allow});

  final bool allow;
  final claims = <String>[];

  @override
  Future<FeatureAllowance> claim(DailyFeature feature) async {
    claims.add(feature.key);
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
  testWidgets('the assistant spends one use for a whole game', (tester) async {
    _phone(tester);
    final limits = _Limits(allow: true);
    await tester.pumpWidget(MaterialApp(
        home: PlayScreen(
            assistantMode: true, evaluate: _fakeEngine, limits: limits)));
    await _settleAssistant(tester);

    await tester.tap(find.byKey(const ValueKey('assistant-info')));
    await _settleAssistant(tester);
    expect(limits.claims, ['assistant_game']);

    // Asking again in the same game must not spend a second use.
    await tester.tap(find.byKey(const ValueKey('assistant-info')));
    await _settleAssistant(tester);
    expect(limits.claims, ['assistant_game']);
  });

  testWidgets('a used-up assistant allowance explains itself and gives no advice',
      (tester) async {
    _phone(tester);
    final limits = _Limits(allow: false);
    await tester.pumpWidget(MaterialApp(
        home: PlayScreen(
            assistantMode: true, evaluate: _fakeEngine, limits: limits)));
    await _settleAssistant(tester);

    await tester.tap(find.byKey(const ValueKey('assistant-info')));
    await _settleAssistant(tester);

    expect(find.text('Bugünlük asistan hakkın doldu'), findsOneWidget);
    expect(find.text('Ücretsiz hesapta günde bir maç asistanla oynanır.'),
        findsOneWidget);
    expect(find.text('Hakkın 7 saat sonra yenilenir.'), findsOneWidget);
    // The advice panel never opened.
    expect(find.text('Ana varyant:'), findsNothing);
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

  test('a backend failure grants the use rather than blocking play', () async {
    final limits = DailyFeatureLimits(
        request: (name, params) async => throw StateError('offline'));
    final allowance = await limits.claim(DailyFeature.assistantGame);
    expect(allowance.allowed, isTrue);
  });
}
