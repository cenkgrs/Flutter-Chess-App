import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'subscriptions.dart';
import 'app_backend.dart';

/// One daily free use per feature. Guests are counted on the device;
/// members are also counted on the server. Verified Apple subscribers bypass
/// both counters. Device usage survives sign-out and account switching.

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

  /// A verified paid entitlement has no daily limit.
  const FeatureAllowance.unlimited()
      : allowed = true,
        used = 0,
        limit = 0,
        remaining = 0,
        resetsAt = null;

  final bool allowed;
  final int used, limit, remaining;
  final DateTime? resetsAt;

  static FeatureAllowance fromRow(Map<String, dynamic> row) => FeatureAllowance(
        allowed: row['allowed'] == true,
        used: (row['used'] as num?)?.toInt() ?? 0,
        limit: (row['limit'] as num?)?.toInt() ?? 0,
        remaining: (row['remaining'] as num?)?.toInt() ?? 0,
        resetsAt:
            DateTime.tryParse(row['resets_at']?.toString() ?? '')?.toLocal(),
      );
}

class DailyFeatureLimits {
  DailyFeatureLimits(
      {this.request,
      bool Function()? signedIn,
      Future<bool> Function()? premium,
      DateTime Function()? now})
      : _signedIn = signedIn ?? (() => AppBackend.currentUser != null),
        _premium = premium ?? SubscriptionStore.instance.refresh,
        _now = now ?? DateTime.now;

  final Future<bool> Function() _premium;
  final DateTime Function() _now;
  Future<void> _pending = Future.value();

  /// Injected by tests in place of the Supabase call.
  final Future<Map<String, dynamic>> Function(
      String name, Map<String, dynamic> params)? request;

  /// Injected by tests in place of the Supabase session check.
  final bool Function() _signedIn;

  static DailyFeatureLimits instance = DailyFeatureLimits();

  Future<Map<String, dynamic>> _rpc(
          String name, Map<String, dynamic> params) async =>
      request != null
          ? await request!(name, params)
          : Map<String, dynamic>.from(
              await AppBackend.client.rpc(name, params: params) as Map);

  String _day() => _now()
      .toUtc()
      .add(const Duration(hours: 3))
      .toIso8601String()
      .substring(0, 10);

  String _key(DailyFeature feature) => 'daily_feature_device_${feature.key}';

  FeatureAllowance _local(bool used) {
    final local = _now().toUtc().add(const Duration(hours: 3));
    final reset = DateTime.utc(local.year, local.month, local.day + 1)
        .subtract(const Duration(hours: 3));
    return FeatureAllowance(
        allowed: !used,
        used: used ? 1 : 0,
        limit: 1,
        remaining: used ? 0 : 1,
        resetsAt: reset.toLocal());
  }

  /// Serialize device writes so simultaneous requests cannot spend one use twice.
  Future<FeatureAllowance> claim(DailyFeature feature) async {
    final previous = _pending;
    final finished = Completer<void>();
    _pending = finished.future;
    await previous;
    try {
      if (await _premium()) return const FeatureAllowance.unlimited();
      final prefs = await SharedPreferences.getInstance();
      final day = _day();
      if (prefs.getString(_key(feature)) == day) return _local(true);
      FeatureAllowance? server;
      if (_signedIn()) {
        try {
          server = FeatureAllowance.fromRow(
              await _rpc('claim_daily_feature', {'p_feature': feature.key})
                  .timeout(const Duration(seconds: 8)));
        } catch (_) {
          // Offline and guests still use the persistent device allowance.
        }
      }
      // Also remember refusals: signing out cannot unlock an exhausted account.
      final saved = await prefs.setString(_key(feature), day);
      if (!saved) return _local(true);
      return server ??
          FeatureAllowance(
              allowed: true,
              used: 1,
              limit: 1,
              remaining: 0,
              resetsAt: _local(true).resetsAt);
    } finally {
      finished.complete();
    }
  }

  Future<Map<DailyFeature, FeatureAllowance>> status() async {
    if (await _premium()) {
      return {
        for (final f in DailyFeature.values)
          f: const FeatureAllowance.unlimited()
      };
    }
    final prefs = await SharedPreferences.getInstance();
    final local = {
      for (final f in DailyFeature.values)
        f: _local(prefs.getString(_key(f)) == _day())
    };
    if (!_signedIn()) return local;
    try {
      final row = await _rpc('daily_feature_status', const {})
          .timeout(const Duration(seconds: 8));
      for (final feature in DailyFeature.values) {
        if (row[feature.key] is! Map) continue;
        final server = FeatureAllowance.fromRow({
          ...Map<String, dynamic>.from(row[feature.key] as Map),
          'allowed': ((row[feature.key] as Map)['remaining'] as num? ?? 0) > 0,
          'resets_at': row['resets_at'],
        });
        if (local[feature]!.allowed) local[feature] = server;
      }
    } catch (_) {}
    return local;
  }
}
