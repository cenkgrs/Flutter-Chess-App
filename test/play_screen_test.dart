import 'package:chess/chess.dart' as c;
import 'package:chess_puzzle_app/prototype/play_screen.dart';
import 'package:chess_puzzle_app/prototype/stockfish_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void usePhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<EngineEvaluation> fakeEngine(String fen, int elo) async {
  final move = c.Chess.fromFEN(fen).generate_moves().first;
  return EngineEvaluation(
      '${move.fromAlgebraic}${move.toAlgebraic}${move.promotion?.name ?? ''}',
      0,
      null);
}

Widget playApp() => const MaterialApp(home: PlayScreen(evaluate: fakeEngine));

Future<void> startNewGame(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('inspection')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('new-game')));
  await tester.pumpAndSettle();
}

Future<void> move(WidgetTester tester, String from, String to) async {
  await tester.tap(find.byKey(ValueKey('square-$from')));
  await tester.pump();
  await tester.tap(find.byKey(ValueKey('square-$to')));
  await tester.pump();
}

void main() {
  testWidgets('Checkmate shows a result and keeps an exit after dismissal',
      (tester) async {
    usePhoneViewport(tester);
    await tester.pumpWidget(playApp());
    final dynamic state = tester.state(find.byType(PlayScreen));
    state.game = c.Chess.fromFEN('8/8/8/8/8/5k2/6q1/7K w - - 0 1');
    state.setState(() {});
    state.announceResult();
    await tester.pumpAndSettle();
    expect(find.text('Kaybettin'), findsOneWidget);
    await tester.tap(find.text('Tahtayı incele'));
    await tester.pumpAndSettle();
    expect(find.text('Menüye dön'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Assistant mode exposes explanation action', (tester) async {
    usePhoneViewport(tester);
    await tester.pumpWidget(
      const MaterialApp(home: PlayScreen(assistantMode: true)),
    );

    expect(find.byKey(const ValueKey('assistant-info')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Board and new-game dialog fit a narrow screen', (tester) async {
    usePhoneViewport(tester);
    await tester.pumpWidget(playApp());

    expect(find.text('Sıra sende'), findsOneWidget);
    expect(find.text('İNCELEME'), findsOneWidget);
    expect(find.text('Hamle geçmişi'), findsNothing);
    expect(find.byType(Image), findsNWidgets(32));
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('inspection')));
    await tester.pumpAndSettle();
    expect(find.text('Hamle geçmişi'), findsOneWidget);
    expect(find.text('Henüz hamle yapılmadı'), findsOneWidget);
    await tester.tap(find.text('Kapat'));
    await tester.pumpAndSettle();

    await startNewGame(tester);
    expect(find.text('Rakibin seviyesi'), findsOneWidget);
    await tester.tap(find.text('Oyuna başla'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Human can select and play a legal move', (tester) async {
    usePhoneViewport(tester);
    await tester.pumpWidget(playApp());

    await tester.tap(find.byKey(const ValueKey('square-e2')));
    await tester.pump();
    expect(find.byKey(const ValueKey('square-e4')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('square-e4')));
    await tester.pump();

    expect(find.text('Sıra sende'), findsNothing);
    expect(find.text('e4'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('inspection')));
    await tester.pumpAndSettle();
    expect(find.text('e4'), findsOneWidget);
  });

  testWidgets('Human can drag a piece to play a legal move', (tester) async {
    usePhoneViewport(tester);
    await tester.pumpWidget(playApp());

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('square-e2'))),
    );
    await gesture.moveTo(
      tester.getCenter(find.byKey(const ValueKey('square-e4'))),
      timeStamp: const Duration(milliseconds: 300),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('dragged-piece')), findsOneWidget);
    await gesture.up();
    await tester.pump();

    expect(find.text('Sıra sende'), findsNothing);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('inspection')));
    await tester.pumpAndSettle();
    expect(find.text('e4'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Undo cancels an in-flight computer move', (tester) async {
    usePhoneViewport(tester);
    await tester.pumpWidget(playApp());

    await move(tester, 'e2', 'e4');
    await tester.tap(find.byKey(const ValueKey('inspection')));
    await tester.pumpAndSettle();
    final undo = find.text('Geri al');
    await tester.tap(undo);
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.byKey(const ValueKey('inspection')));
    await tester.pumpAndSettle();
    expect(find.text('Henüz hamle yapılmadı'), findsOneWidget);
    expect(find.byType(Image), findsNWidgets(32));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Restart cancels an in-flight computer move', (tester) async {
    usePhoneViewport(tester);
    await tester.pumpWidget(playApp());

    await move(tester, 'e2', 'e4');
    await startNewGame(tester);
    await tester.tap(find.text('Oyuna başla'));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.byKey(const ValueKey('inspection')));
    await tester.pumpAndSettle();
    expect(find.text('Henüz hamle yapılmadı'), findsOneWidget);
    expect(find.byType(Image), findsNWidgets(32));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Computer opens when human chooses black', (tester) async {
    usePhoneViewport(tester);
    await tester.pumpWidget(playApp());
    await startNewGame(tester);

    await tester.tap(find.byType(DropdownButton<c.Color>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Siyah · Bilgisayar başlar').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Oyuna başla'));
    await tester.pumpAndSettle();

    expect(find.text('Sıra sende'), findsOneWidget);
    expect(find.byType(Image), findsNWidgets(32));
    await tester.tap(find.byKey(const ValueKey('inspection')));
    await tester.pumpAndSettle();
    expect(find.text('Henüz hamle yapılmadı'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
