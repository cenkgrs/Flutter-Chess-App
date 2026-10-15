import 'package:chess_puzzle_app/l10n/app_language.dart';
import 'package:chess_puzzle_app/screens/auth_screen.dart';
import 'package:chess_puzzle_app/screens/delete_account_screen.dart';
import 'package:chess_puzzle_app/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void configureSmallPhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(320, 568);
  tester.view.devicePixelRatio = 1;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    AppLanguage.instance.locale = const Locale('tr');
  });

  testWidgets('German registration remains usable above the iOS keyboard',
      (tester) async {
    configureSmallPhone(tester);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    AppLanguage.instance.locale = const Locale('de');

    await tester.pumpWidget(const MaterialApp(home: AuthScreen()));
    final toggle = find.byKey(const ValueKey('auth-mode-toggle'));
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pump();
    await tester.showKeyboard(find.byKey(const ValueKey('email-field')));
    await tester.pump();

    final submit = find.byKey(const ValueKey('auth-submit'));
    await tester.ensureVisible(submit);
    expect(submit, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Russian account deletion fits the smallest supported phone',
      (tester) async {
    configureSmallPhone(tester);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    AppLanguage.instance.locale = const Locale('ru');

    await tester.pumpWidget(
        MaterialApp(home: DeleteAccountScreen(deleteAccount: () async {})));
    await tester.scrollUntilVisible(
      find.byType(CheckboxListTile),
      180,
      scrollable: find.byType(Scrollable),
    );
    await tester.drag(find.byType(ListView), const Offset(0, -160));
    await tester.pump();
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    final button = find.byType(FilledButton);
    await tester.ensureVisible(button);

    expect(button, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('German profile links do not overflow on a narrow phone',
      (tester) async {
    configureSmallPhone(tester);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    AppLanguage.instance.locale = const Locale('de');

    await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));
    await tester.drag(find.byType(ListView), const Offset(0, -900));
    await tester.pumpAndSettle();

    expect(find.text('Open-Source-Lizenzen'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
