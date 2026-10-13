import 'app_backend.dart';

class FriendRepository {
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
