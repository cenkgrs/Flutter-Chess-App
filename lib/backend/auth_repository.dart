import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_backend.dart';

class AuthRepository {
  SupabaseClient get _client => AppBackend.client;

  User? get currentUser => AppBackend.currentUser;

  Stream<AuthState> get changes => _client.auth.onAuthStateChange;

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) =>
      _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

  /// [crossBorderConsent] travels in the sign-up metadata so the database
  /// trigger can stamp the profile in the same statement that creates it.
  Future<AuthResponse> register({
    required String username,
    required String email,
    required String password,
    required bool crossBorderConsent,
  }) =>
      _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'username': username.trim(),
          'cross_border_consent': crossBorderConsent ? 'true' : 'false',
        },
        emailRedirectTo: 'com.silveroaktech.rok://login-callback/',
      );

  Future<void> signOut() => _client.auth.signOut();
}
