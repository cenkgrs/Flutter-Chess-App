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
}
