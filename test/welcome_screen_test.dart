import 'package:chess_puzzle_app/screens/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('the tour runs to the end and then owes nothing',
      (tester) async {
    var done = 0;
    await tester.pumpWidget(
        MaterialApp(home: WelcomeScreen(onDone: () => done++)));

    expect(await WelcomeScreen.isPending(), isTrue);
    // Three taps advance, the fourth finishes.
    for (var i = 0; i < 3; i++) {
      expect(done, 0, reason: 'finished early on card $i');
      await tester.tap(find.byKey(const ValueKey('welcome-next')));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.byKey(const ValueKey('welcome-next')));
    await tester.pumpAndSettle();

    expect(done, 1);
    expect(await WelcomeScreen.isPending(), isFalse);
  });

  testWidgets('skipping counts as having seen it', (tester) async {
    var done = 0;
    await tester.pumpWidget(
        MaterialApp(home: WelcomeScreen(onDone: () => done++)));

    await tester.tap(find.byKey(const ValueKey('welcome-skip')));
    await tester.pumpAndSettle();

    expect(done, 1);
    expect(await WelcomeScreen.isPending(), isFalse);
  });

  test('a device that has seen it is never asked again', () async {
    SharedPreferences.setMockInitialValues({WelcomeScreen.seenKey: true});
    expect(await WelcomeScreen.isPending(), isFalse);
  });
}
