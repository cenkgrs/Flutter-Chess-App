import 'package:supabase_flutter/supabase_flutter.dart';

class AppBackend {
  AppBackend._();

  static const url = String.fromEnvironment('SUPABASE_URL');
  static const publishableKey =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  static bool get isConfigured => url.isNotEmpty && publishableKey.isNotEmpty;

  static SupabaseClient get client {
    if (!isConfigured) {
      throw const BackendNotConfiguredException();
    }
    return Supabase.instance.client;
  }

  static User? get currentUser => isConfigured ? client.auth.currentUser : null;

  static Future<void> initialize() async {
    if (!isConfigured) return;
    await Supabase.initialize(url: url, publishableKey: publishableKey);
  }
}

class BackendNotConfiguredException implements Exception {
  const BackendNotConfiguredException();

  @override
  String toString() =>
      'Supabase bağlantısı henüz yapılandırılmadı. SUPABASE_URL ve '
      'SUPABASE_PUBLISHABLE_KEY değerleriyle uygulamayı başlatın.';
}
