import 'package:chess_puzzle_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('guest can open login and switch to registration',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());
    await tester.tap(find.byKey(const ValueKey('login')));
    await tester.pumpAndSettle();

    expect(find.text('GİRİŞ YAP'), findsWidgets);
    expect(find.byKey(const ValueKey('email-field')), findsOneWidget);
    expect(find.byKey(const ValueKey('password-field')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('auth-mode-toggle')));
    await tester.pump();

    expect(find.text('HESAP OLUŞTUR'), findsOneWidget);
    expect(find.byKey(const ValueKey('username-field')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('unconfigured backend is explained instead of crashing',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());
    await tester.tap(find.byKey(const ValueKey('login')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('email-field')), 'oyuncu@example.com');
    await tester.enterText(
        find.byKey(const ValueKey('password-field')), 'guclu-sifre');
    await tester.tap(find.byKey(const ValueKey('auth-submit')));
    await tester.pump();

    expect(find.byKey(const ValueKey('auth-error')), findsOneWidget);
    expect(find.textContaining('Supabase bağlantısı'), findsOneWidget);
  });
}
