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
    expect(find.text('Bilgisayara karşı'), findsOneWidget);
    expect(find.text('Asistan'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('online-play')));
    await tester.pumpAndSettle();
    expect(find.text('SÜRE SEÇ'), findsOneWidget);
    expect(find.byKey(const ValueKey('time-1+0')), findsOneWidget);
    expect(find.byKey(const ValueKey('time-3+2')), findsOneWidget);
    expect(find.byKey(const ValueKey('time-15+10')), findsOneWidget);
    expect(find.byKey(const ValueKey('time-45+45')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
