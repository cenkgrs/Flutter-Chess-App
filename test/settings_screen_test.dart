import 'package:chess_puzzle_app/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('settings gathers every choice the player makes',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('AYARLAR'), findsOneWidget);
    for (final key in [
      'language-link',
      'board-theme-link',
      'sound-effects-toggle',
      'puzzle-reminder-toggle',
    ]) {
      await tester.scrollUntilVisible(find.byKey(ValueKey(key)), 200,
          scrollable: find.byType(Scrollable));
      expect(find.byKey(ValueKey(key)), findsOneWidget, reason: key);
    }
  });

  testWidgets('settings opens privacy and support URLs', (tester) async {
    final opened = <Uri>[];
    await tester
        .pumpWidget(MaterialApp(home: SettingsScreen(openLink: (uri) async {
      opened.add(uri);
      return true;
    })));

    for (final key in ['privacy-policy-link', 'support-link']) {
      final link = find.byKey(ValueKey(key));
      await tester.scrollUntilVisible(link, 300,
          scrollable: find.byType(Scrollable));
      await tester.ensureVisible(link);
      await tester.pumpAndSettle();
      await tester.tap(link);
      await tester.pump();
    }

    expect(opened, [SettingsScreen.privacyUri, SettingsScreen.supportUri]);
  });
}
