import 'package:chess_puzzle_app/backend/friend_repository.dart';
import 'package:chess_puzzle_app/online/time_control.dart';
import 'package:chess_puzzle_app/screens/chess_leaderboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class RecordingRepository extends FriendRepository {
  final actions = <String>[];
  final invites = <String>[];

  @override
  Future<void> action(String id, String action) async =>
      actions.add('$action:$id');

  @override
  Future<void> invite(String id, TimeControl control) async =>
      invites.add('$id:${control.minutes}+${control.increment}');
}

Map<String, dynamic> board(String pool) => {
      'pool': pool,
      'leaders': [
        {
          'user_id': 'u-friend',
          'username': 'Bob',
          'rating': pool == 'bullet' ? 2400 : 2000,
          'games_played': 30,
          'place': 1,
          'friendship': 'accepted',
        },
        {
          'user_id': 'u-me',
          'username': 'Alice',
          'rating': 1800,
          'games_played': 12,
          'place': 2,
          'friendship': 'self',
        },
        {
          'user_id': 'u-stranger',
          'username': 'Carol',
          'rating': 1600,
          'games_played': 5,
          'place': 3,
          'friendship': 'none',
        },
        {
          'user_id': 'u-asked',
          'username': 'Dave',
          'rating': 1500,
          'games_played': 3,
          'place': 4,
          'friendship': 'pending',
        },
      ],
      'me': {
        'user_id': 'u-me',
        'username': 'Alice',
        'rating': 1800,
        'games_played': 12,
        'place': 2,
      },
    };

/// A public board is not consent to be challenged, so what each row offers
/// is the point of this screen.
void main() {
  late RecordingRepository repo;
  final pools = <String>[];

  Widget app() => MaterialApp(
          home: ChessLeaderboardScreen(
        repository: repo,
        loader: (pool) async {
          pools.add(pool);
          return board(pool);
        },
      ));

  setUp(() {
    repo = RecordingRepository();
    pools.clear();
  });

  testWidgets('a stranger can be befriended, never challenged',
      (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('befriend-u-stranger')), findsOneWidget);
    expect(find.byKey(const ValueKey('challenge-u-stranger')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('befriend-u-stranger')));
    await tester.pumpAndSettle();
    expect(repo.actions, ['send:u-stranger']);
  });

  testWidgets('a friend can be challenged at this pool only', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('challenge-u-friend')));
    await tester.pumpAndSettle();
    // Blitz is the pool on screen; a classical preset has no place here.
    expect(find.text('Blitz · 3+0'), findsOneWidget);
    expect(find.text('Klasik · 30+0'), findsNothing);

    await tester.tap(find.text('Blitz · 3+0'));
    await tester.pumpAndSettle();
    expect(repo.invites, ['u-friend:3+0']);
  });

  testWidgets('a request already sent is not offered again', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('befriend-u-asked')), findsNothing);
    expect(find.text('Beklemede'), findsOneWidget);
  });

  testWidgets('the player themselves is offered nothing', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('befriend-u-me')), findsNothing);
    expect(find.byKey(const ValueKey('challenge-u-me')), findsNothing);
  });

  testWidgets('each pool is its own board', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(pools, ['blitz']);

    await tester.tap(find.byKey(const ValueKey('pool-bullet')));
    await tester.pumpAndSettle();
    expect(pools, ['blitz', 'bullet']);
    expect(find.text('2400'), findsOneWidget);
    expect(find.text('30 oyun'), findsOneWidget);
  });
}
