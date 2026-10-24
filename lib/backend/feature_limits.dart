import 'app_backend.dart';

/// Free-tier daily allowances for the two engine-backed features.
///
/// The count is kept by Supabase, not here. ROK ships under
/// GPL-3.0-or-later with Stockfish inside the binary, so a check in this
/// file is advisory: anyone may rebuild the app without it. Holding the
/// count on the server is what makes the allowance real for the published
/// build, and it is the seam the 1.1 subscription will lift.

enum DailyFeature {
  /// One game played with the assistant available.
  assistantGame('assistant_game'),

  /// One engine pass over a finished game.
  gameAnalysis('game_analysis');

  const DailyFeature(this.key);

  final String key;
}

/// What the server said about one feature.
class FeatureAllowance {
  const FeatureAllowance({
    required this.allowed,
    required this.used,
    required this.limit,
    required this.remaining,
    this.resetsAt,
  });

  /// Treats a server or network failure as a grant. A player who cannot
  /// reach Supabase should still get their game; the count is a free-tier
  /// courtesy, not a paywall, and 1.1 moves the engine behind the API
  /// where the question cannot be dodged.
  const FeatureAllowance.unavailable()
      : allowed = true,
        used = 0,
        limit = 0,
        remaining = 0,
        resetsAt = null;

  final bool allowed;
  final int used, limit, remaining;
  final DateTime? resetsAt;

  static FeatureAllowance fromRow(Map<String, dynamic> row) =>
      FeatureAllowance(
        allowed: row['allowed'] == true,
        used: (row['used'] as num?)?.toInt() ?? 0,
        limit: (row['limit'] as num?)?.toInt() ?? 0,
        remaining: (row['remaining'] as num?)?.toInt() ?? 0,
        resetsAt: DateTime.tryParse(row['resets_at']?.toString() ?? '')
            ?.toLocal(),
      );
}

class DailyFeatureLimits {
  DailyFeatureLimits({this.request});

  /// Injected by tests in place of the Supabase call.
  final Future<Map<String, dynamic>> Function(
      String name, Map<String, dynamic> params)? request;

  static DailyFeatureLimits instance = DailyFeatureLimits();

  Future<Map<String, dynamic>> _rpc(
          String name, Map<String, dynamic> params) async =>
      request != null
          ? await request!(name, params)
          : Map<String, dynamic>.from(
              await AppBackend.client.rpc(name, params: params) as Map);

  /// Spends one use, or reports that today's allowance is gone.
  Future<FeatureAllowance> claim(DailyFeature feature) async {
    try {
      return FeatureAllowance.fromRow(
          await _rpc('claim_daily_feature', {'p_feature': feature.key}));
    } catch (_) {
      return const FeatureAllowance.unavailable();
    }
  }

  /// What is left today, without spending anything.
  Future<Map<DailyFeature, FeatureAllowance>> status() async {
    try {
      final row = await _rpc('daily_feature_status', const {});
      return {
        for (final feature in DailyFeature.values)
          if (row[feature.key] is Map)
            feature: FeatureAllowance.fromRow({
              ...Map<String, dynamic>.from(row[feature.key] as Map),
              'allowed': ((row[feature.key] as Map)['remaining'] as num? ?? 0) >
                  0,
              'resets_at': row['resets_at'],
            }),
      };
    } catch (_) {
      return const {};
    }
  }
}
