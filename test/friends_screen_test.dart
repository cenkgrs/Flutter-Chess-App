import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chess_puzzle_app/backend/friend_repository.dart';
import 'package:chess_puzzle_app/screens/friends_screen.dart';

class FakeFriends extends FriendRepository {
  @override
  Future<List<Map<String, dynamic>>> invitations() async => [];
  final rows = <Map<String, dynamic>>[
    {'id': 'a', 'username': 'Rakip', 'status': 'pending', 'incoming': true}
  ];
  String? lastAction;
  @override
  Future<void> inviteDuel(String id) async {
    lastAction = 'duel';
  }

  @override
  Future<List<Map<String, dynamic>>> list() async => rows;
  @override
  Future<List<Map<String, dynamic>>> search(String query) async => [
        {'id': 'b', 'username': 'Cenk'}
      ];
  @override
  Future<void> action(String id, String action) async {
    lastAction = action;
    if (action == 'accept') rows.first['status'] = 'accepted';
  }
}

void main() {
  testWidgets('friend invitation offers chess and puzzle duel', (tester) async {
    final repo = FakeFriends();
    repo.rows.first['status'] = 'accepted';
    await tester.pumpWidget(MaterialApp(home: FriendsScreen(repository: repo)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Oyuna davet et'));
    await tester.pumpAndSettle();
    expect(find.text('Satranç'), findsOneWidget);
    await tester.tap(find.text('Bulmaca Düellosu'));
    await tester.pumpAndSettle();
    expect(repo.lastAction, 'duel');
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('incoming request can be accepted and player can be searched',
      (tester) async {
    final repo = FakeFriends();
    await tester.pumpWidget(MaterialApp(home: FriendsScreen(repository: repo)));
    await tester.pumpAndSettle();
    expect(find.text('Rakip'), findsOneWidget);
    await tester.tap(find.text('Kabul et'));
    await tester.pumpAndSettle();
    expect(repo.lastAction, 'accept');
    expect(find.text('Kabul et'), findsNothing);
    await tester.enterText(find.byType(TextField), 'Cen');
    await tester.tap(find.byTooltip('Ara'));
    await tester.pumpAndSettle();
    expect(find.text('Cenk'), findsOneWidget);
    await tester.tap(find.text('İstek gönder'));
    await tester.pumpAndSettle();
    expect(repo.lastAction, 'send');
    await tester.pumpWidget(const SizedBox());
  });
}
