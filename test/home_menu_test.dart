import 'package:chess_puzzle_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('menu exposes game modes and researched time controls',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());
    expect(find.text('OYUNA BAŞLA'), findsOneWidget);
    expect(find.text('Asistan'), findsOneWidget);
    expect(find.byKey(const ValueKey('menu-premium')), findsNothing);
    expect(find.byKey(const ValueKey('menu-board-theme')), findsNothing);

    // The card asks which kind of game first; the clocks come after.
    await tester.tap(find.byKey(const ValueKey('online-play')));
    await tester.pumpAndSettle();
    expect(find.text('NASIL OYNAYALIM?'), findsOneWidget);
    expect(find.byKey(const ValueKey('mode-friend')), findsOneWidget);
    expect(find.byKey(const ValueKey('mode-computer')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('mode-online')));
    await tester.pumpAndSettle();
    expect(find.text('SÜRE SEÇ'), findsOneWidget);
    expect(find.byKey(const ValueKey('time-1+0')), findsOneWidget);
    expect(find.byKey(const ValueKey('time-3+2')), findsOneWidget);
    expect(find.byKey(const ValueKey('time-15+10')), findsOneWidget);
    expect(find.byKey(const ValueKey('time-45+45')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('header stays fixed and social link leaves the home screen',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());
    final header = find.text('ROK');
    final initialTop = tester.getTopLeft(header).dy;

    expect(find.text('Arkadaşlar'), findsNothing);
    // Playing a friend moved into the card's sheet, so the list no longer
    // carries it; the assistant took the space it used to argue over.
    expect(find.text('Arkadaşla oyna'), findsNothing);
    expect(find.byKey(const ValueKey('assistant-play')), findsOneWidget);

    await tester.drag(
        find.byType(SingleChildScrollView), const Offset(0, -360));
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(header).dy, initialTop);
    expect(find.text('ROK'), findsOneWidget);
  });

  testWidgets('the account and the rankings live behind the menu button',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    // The header no longer carries them; the main list is for playing.
    expect(find.byKey(const ValueKey('login')), findsNothing);
    expect(find.byKey(const ValueKey('chess-leaderboard')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('menu-drawer')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('login')), findsOneWidget);
    expect(find.byKey(const ValueKey('chess-leaderboard')), findsOneWidget);
    expect(find.byKey(const ValueKey('drawer-name')), findsOneWidget);
    // Premium, the match history and the friend list each need an account;
    // signed out they would only lead back to the login row below them.
    for (final link in ['drawer-premium', 'drawer-recent-games',
        'drawer-friends']) {
      expect(find.byKey(ValueKey(link)), findsNothing, reason: link);
    }
    expect(tester.takeException(), isNull);
  });
}
