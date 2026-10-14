import 'dart:ui';
import 'package:chess/chess.dart' as c;
import 'package:chess_puzzle_app/ads/match_ads.dart';
import 'package:chess_puzzle_app/l10n/app_language.dart';
import 'package:chess_puzzle_app/prototype/premove.dart';
import 'package:chess_puzzle_app/widgets/board_annotations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('Premove is validated against the resulting position', () {
    final game = c.Chess();
    game.move({'from': 'e2', 'to': 'e4'});
    const queued = Premove('g1', 'f3');
    expect(queued.resolve(game), isNull);
    game.move({'from': 'e7', 'to': 'e5'});
    expect(queued.resolve(game)?.toAlgebraic, 'f3');
    expect(const Premove('g1', 'g5').resolve(game), isNull);
  });
  test('Captured piece premove cancels; promotions choose queen', () {
    final captured = c.Chess.fromFEN('4k3/8/8/8/8/8/8/4K3 w - - 0 1');
    expect(const Premove('a2', 'a3').resolve(captured), isNull);
    final promotion = c.Chess.fromFEN('4k3/P7/8/8/8/8/8/4K3 w - - 0 1');
    expect(const Premove('a7', 'a8').resolve(promotion)?.promotion?.name, 'q');
  });
  test('Ads have a strict five minute cap including clock rollback', () {
    final last = DateTime(2026, 10, 14, 12);
    expect(
        adCooldownElapsed(last.add(const Duration(seconds: 299)), last), false);
    expect(adCooldownElapsed(last.add(const Duration(minutes: 5)), last), true);
    expect(adCooldownElapsed(last.subtract(const Duration(minutes: 1)), last),
        false);
  });
  testWidgets('Touch drawing and right mouse drawing preserve move input',
      (tester) async {
    final controller = BoardDrawingController();
    addTearDown(controller.dispose);
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Column(children: [
      BoardDrawingTools(controller: controller),
      SizedBox(
          width: 320,
          height: 320,
          child: BoardAnnotations(
              controller: controller,
              flipped: false,
              child: GestureDetector(
                  onTap: () => taps++,
                  child: const ColoredBox(color: Colors.brown)))),
    ]))));
    final board = find.byType(BoardAnnotations);
    await tester.tapAt(tester.getCenter(board));
    expect(taps, 1);
    await tester.tap(find.byIcon(Icons.draw_outlined));
    await tester.pump();
    await tester.dragFrom(tester.getTopLeft(board) + const Offset(30, 30),
        const Offset(120, 120));
    await tester.pump();
    expect(controller.marks.length, 1);
    expect(taps, 1);
    await tester.tap(find.byIcon(Icons.layers_clear));
    await tester.pump();
    expect(controller.marks, isEmpty);
    await tester.tap(find.byIcon(Icons.touch_app));
    await tester.pump();
    final mouse = await tester.startGesture(tester.getCenter(board),
        kind: PointerDeviceKind.mouse, buttons: 2);
    await mouse.moveBy(const Offset(40, 0));
    await mouse.up();
    await tester.pump();
    expect(controller.marks.length, 1);
    expect(taps, 1);
  });
  testWidgets(
      'Language persists, translates dynamic messages and supports device mode',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    addTearDown(() => AppLanguage.instance.locale = const Locale('tr'));
    for (final code in ['en', 'de', 'ru']) {
      await AppLanguage.instance.set(code);
      await tester.pumpWidget(MaterialApp(
          key: ValueKey(code),
          home: Builder(
              builder: (context) => Column(children: [
                    const LText('GİRİŞ YAP'),
                    const LText('Sıra sende · Hata: 2'),
                    Text(tr(context,
                        'e2 karesindeki taşı e4 karesine götürmeni öneriyorum.')),
                  ]))));
      expect(find.text('GİRİŞ YAP'), findsNothing);
      expect(find.textContaining('Hata:'), findsNothing);
      expect(find.textContaining('öneriyorum'), findsNothing);
      expect(
          (await SharedPreferences.getInstance()).getString('language'), code);
    }
    await AppLanguage.instance.set(null);
    expect(AppLanguage.instance.locale, isNull);
    expect(
        (await SharedPreferences.getInstance()).getString('language'), isNull);
  });
}
