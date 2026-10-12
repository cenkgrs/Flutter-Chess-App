import 'package:chess_puzzle_app/screens/puzzle_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Puzzle mode requires login and leaves rating on the server',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PuzzleScreen()));
    expect(find.text('Bulmacalar için giriş yap'), findsOneWidget);
    expect(find.text('Sonraki bulmaca'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
