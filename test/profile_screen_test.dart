import 'package:chess_puzzle_app/audio/game_sounds.dart';
import 'package:chess_puzzle_app/screens/profile_screen.dart';
import 'package:chess_puzzle_app/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('profile exposes recent games and friends links', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));

    expect(find.text('PROFİLİM'), findsOneWidget);
    expect(find.text('ROK Oyuncusu'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Son Maçlar'), 160,
        scrollable: find.byType(Scrollable));
    expect(find.text('Son Maçlar'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Arkadaşlar'), 200,
        scrollable: find.byType(Scrollable));
    expect(find.text('Arkadaşlar'), findsOneWidget);
  });

  testWidgets('guests find the subscription, and nothing they merely set',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));
    expect(find.text('ROK Premium'), findsOneWidget);
    expect(find.text('Giriş yap'), findsOneWidget);
    // These are choices, not a record of who the player is; they belong to
    // the settings page now.
    for (final key in [
      'board-theme-link',
      'sound-effects-toggle',
      'puzzle-reminder-toggle',
      'privacy-policy-link',
      'support-link',
    ]) {
      expect(find.byKey(ValueKey(key)), findsNothing, reason: key);
    }
  });

  testWidgets('sound effects can be disabled and remain disabled',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'game_sound_effects_enabled': true,
    });
    await GameSounds.instance.setEnabled(true);
    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

    final toggle = find.byKey(const ValueKey('sound-effects-toggle'));
    await tester.scrollUntilVisible(
      toggle,
      250,
      scrollable: find.byType(Scrollable),
    );
    final switchFinder =
        find.descendant(of: toggle, matching: find.byType(Switch));
    await tester.ensureVisible(switchFinder);
    await tester.pumpAndSettle();
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    expect(GameSounds.instance.enabled, isFalse);
    expect(
      (await SharedPreferences.getInstance())
          .getBool('game_sound_effects_enabled'),
      isFalse,
    );
  });
}
