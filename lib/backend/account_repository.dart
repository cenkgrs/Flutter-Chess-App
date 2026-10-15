import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_backend.dart';

class AccountRepository {
  Future<void> deleteAccount() async {
    final client = AppBackend.client;
    final response = await client.functions
        .invoke('delete-account', body: {'confirmation': 'DELETE_MY_ACCOUNT'});
    if (response.status != 200 ||
        response.data is! Map ||
        response.data['deleted'] != true) {
      throw StateError('Account deletion was not confirmed');
    }
    // Only remove the local session after the server confirms deletion.
    try {
      await client.auth.signOut(scope: SignOutScope.local);
    } catch (_) {
      // GoTrue clears the local session before its network sign-out request.
      // A failed request must not misreport an already completed deletion.
      if (client.auth.currentSession != null) rethrow;
    }
  }
}
