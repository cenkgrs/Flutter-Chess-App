import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chess_puzzle_app/screens/puzzle_leaderboard_screen.dart';

void main() {
  testWidgets('shows points, own rank and public player names', (tester) async {
    final row = {
      'username': 'Cenk',
      'place': 105,
      'points': 80,
      'rating': 1230,
      'played': 3
    };
    await tester.pumpWidget(MaterialApp(
        home: PuzzleLeaderboardScreen(
      loader: () async => {
        'leaders': [
          {...row, 'username': 'Rakip', 'place': 1}
        ],
        'me': row
      },
    )));
    await tester.pumpAndSettle();
    expect(find.text('Cenk · Sen'), findsOneWidget);
    expect(find.text('#105'), findsOneWidget);
    expect(find.text('Rakip'), findsOneWidget);
    expect(find.text('80\nPUAN'), findsNWidgets(2));
  });
  testWidgets('empty leaderboard invites first completion', (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: PuzzleLeaderboardScreen(
      loader: () async => {'leaders': [], 'me': null},
    )));
    await tester.pumpAndSettle();
    expect(find.text('Henüz sıralamada oyuncu yok.'), findsOneWidget);
    expect(
        find.text('İlk bulmacanı tamamla, sıralamaya katıl.'), findsOneWidget);
  });
  testWidgets('failed load can be retried', (tester) async {
    var calls = 0;
    await tester
        .pumpWidget(MaterialApp(home: PuzzleLeaderboardScreen(loader: () async {
      if (calls++ == 0) throw Exception('offline');
      return {'leaders': [], 'me': null};
    })));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sıralama yüklenemedi. Tekrar dene'));
    await tester.pumpAndSettle();
    expect(find.text('Henüz sıralamada oyuncu yok.'), findsOneWidget);
  });
}
