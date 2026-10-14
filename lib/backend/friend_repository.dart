import 'app_backend.dart';
import '../online/time_control.dart';

class FriendRepository {
  Future<List<Map<String, dynamic>>> invitations() async {
    final chess = List<Map<String, dynamic>>.from(
        await AppBackend.client.rpc('game_invitation_list') as List);
    final duels = List<Map<String, dynamic>>.from(
        await AppBackend.client.rpc('duel_invitation_list') as List);
    return [...chess, ...duels];
  }

  Future<void> inviteDuel(String id) async {
    await AppBackend.client.rpc('send_duel_invitation', params: {'p_user': id});
  }

  Future<String?> respondDuel(String id, bool accept) async =>
      await AppBackend.client.rpc('respond_duel_invitation',
          params: {'p_id': id, 'p_accept': accept}) as String?;
  Future<void> invite(String id, TimeControl control) async {
    await AppBackend.client.rpc('send_game_invitation', params: {
      'p_user': id,
      'p_pool': control.pool.databaseName,
      'p_minutes': control.minutes,
      'p_increment': control.increment,
    });
  }

  Future<String?> respond(String id, bool accept) async =>
      await AppBackend.client.rpc('respond_game_invitation',
          params: {'p_id': id, 'p_accept': accept}) as String?;
  Future<List<Map<String, dynamic>>> list() async =>
      List<Map<String, dynamic>>.from(
          await AppBackend.client.rpc('friend_list') as List);
  Future<List<Map<String, dynamic>>> search(String query) async =>
      List<Map<String, dynamic>>.from(await AppBackend.client
          .rpc('search_players', params: {'p_query': query}) as List);
  Future<void> action(String id, String action) async {
    await AppBackend.client
        .rpc('friend_action', params: {'p_user': id, 'p_action': action});
  }
}
