import '../online/time_control.dart';
import 'app_backend.dart';

class RatingSnapshot {
  const RatingSnapshot(this.values);

  final Map<SpeedPool, int> values;

  int ratingFor(SpeedPool pool) => values[pool] ?? 1500;

  static const initial = RatingSnapshot({
    SpeedPool.bullet: 1500,
    SpeedPool.blitz: 1500,
    SpeedPool.rapid: 1500,
    SpeedPool.classical: 1500,
  });
}

class MatchmakingResult {
  const MatchmakingResult({required this.waiting, this.gameId});

  final bool waiting;
  final String? gameId;

  factory MatchmakingResult.fromJson(Map<String, dynamic> json) =>
      MatchmakingResult(
        waiting: json['status'] == 'waiting',
        gameId: json['game_id'] as String?,
      );
}

class GameRepository {
  Future<RatingSnapshot> loadRatings() async {
    final user = AppBackend.currentUser;
    if (user == null) return RatingSnapshot.initial;
    final rows = await AppBackend.client
        .from('ratings')
        .select('pool,rating')
        .eq('user_id', user.id);
    final values = <SpeedPool, int>{};
    for (final row in rows) {
      final pool = SpeedPool.values
          .where((value) => value.databaseName == row['pool'])
          .firstOrNull;
      if (pool != null) values[pool] = (row['rating'] as num).round();
    }
    return RatingSnapshot(values);
  }

  Future<MatchmakingResult> joinQueue(TimeControl control) async {
    final response = await AppBackend.client.rpc(
      'join_matchmaking',
      params: {
        'p_pool': control.pool.databaseName,
        'p_minutes': control.minutes,
        'p_increment': control.increment,
      },
    );
    return MatchmakingResult.fromJson(
      Map<String, dynamic>.from(response as Map),
    );
  }

  Future<String?> findActiveGame() async {
    final response = await AppBackend.client.rpc('find_active_game');
    return response as String?;
  }

  Future<void> leaveQueue() => AppBackend.client.rpc('leave_matchmaking');

  Stream<Map<String, dynamic>> watchGame(String gameId) => AppBackend.client
      .from('games')
      .stream(primaryKey: ['id'])
      .eq('id', gameId)
      .map((rows) => rows.single);

  Future<void> submitMove({
    required String gameId,
    required int expectedPly,
    required String uci,
    required String san,
    required String fenAfter,
    required int whiteMs,
    required int blackMs,
  }) =>
      AppBackend.client.rpc(
        'submit_move',
        params: {
          'p_game_id': gameId,
          'p_expected_ply': expectedPly,
          'p_uci': uci,
          'p_san': san,
          'p_fen_after': fenAfter,
          'p_white_ms': whiteMs,
          'p_black_ms': blackMs,
        },
      );

  Future<void> finishGame({
    required String gameId,
    required String result,
    required String reason,
  }) =>
      AppBackend.client.rpc(
        'finish_game',
        params: {
          'p_game_id': gameId,
          'p_result': result,
          'p_reason': reason,
        },
      );
}
