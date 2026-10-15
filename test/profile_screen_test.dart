import 'package:chess_puzzle_app/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('profile exposes recent games and friends links', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));

    expect(find.text('PROFİLİM'), findsOneWidget);
    expect(find.text('ROK Oyuncusu'), findsOneWidget);
    expect(find.text('Son Maçlar'), findsOneWidget);
    expect(find.text('Arkadaşlar'), findsOneWidget);
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
    await tester.tap(find.byKey(const ValueKey('privacy-policy-link')));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('support-link')),
      200,
      scrollable: find.byType(Scrollable),
    );
    await tester.tap(find.byKey(const ValueKey('support-link')));
    await tester.pump();

    expect(opened, [ProfileScreen.privacyUri, ProfileScreen.supportUri]);
  });
}
