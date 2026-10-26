import 'package:chess_puzzle_app/audio/game_sounds.dart';
import 'package:chess_puzzle_app/screens/profile_screen.dart';
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

  testWidgets('guests can find subscription and appearance settings in profile',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));
    expect(find.text('ROK Premium'), findsOneWidget);
    expect(find.text('Giriş yap'), findsOneWidget);
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('board-theme-link')), 200,
        scrollable: find.byType(Scrollable));
    expect(find.text('Tahta görünümü'), findsOneWidget);
  });

  testWidgets('profile opens privacy and support URLs', (tester) async {
    final opened = <Uri>[];
    await tester
        .pumpWidget(MaterialApp(home: ProfileScreen(openLink: (uri) async {
      opened.add(uri);
      return true;
    })));

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('privacy-policy-link')),
      300,
      scrollable: find.byType(Scrollable),
    );
    await tester
        .ensureVisible(find.byKey(const ValueKey('privacy-policy-link')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('privacy-policy-link')));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('support-link')),
      200,
      scrollable: find.byType(Scrollable),
    );
    await tester.ensureVisible(find.byKey(const ValueKey('support-link')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('support-link')));
    await tester.pump();

    expect(opened, [ProfileScreen.privacyUri, ProfileScreen.supportUri]);
  });

  testWidgets('sound effects can be disabled and remain disabled',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'game_sound_effects_enabled': true,
    });
    await GameSounds.instance.setEnabled(true);
    await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));

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
