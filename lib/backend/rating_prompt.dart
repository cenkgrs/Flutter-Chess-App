import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Asks iOS to show its own rating sheet, and only after something went well.
///
/// The store ranks on stars, so the app has to ask — but iOS shows the sheet
/// at most three times a year per player and may silently show nothing, so
/// the few chances there are get spent on good moments: a win, a solved
/// puzzle. Never after a loss, and never on the first one; a player who has
/// won once has not yet decided what they think of the app.
class RatingPrompt {
  RatingPrompt({
    Future<void> Function()? ask,
    DateTime Function()? clock,
    bool? supported,
  })  : _ask = ask ?? _systemSheet,
        _now = clock ?? DateTime.now,
        _supported = supported ??
            (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS);

  static RatingPrompt instance = RatingPrompt();

  /// How many good moments the player sees before the first ask.
  static const moments = 3;

  /// And how long before the app is allowed to ask again.
  static const again = Duration(days: 120);

  static const _countKey = 'rating_good_moments';
  static const _askedKey = 'rating_asked_at';

  final Future<void> Function() _ask;
  final DateTime Function() _now;
  final bool _supported;

  static Future<void> _systemSheet() async {
    await const MethodChannel('rok/review').invokeMethod<bool>('request');
  }

  /// Call this where the player is pleased. Returns whether iOS was asked,
  /// which is not the same as the sheet appearing — that is the system's
  /// call, and the app is never told.
  Future<bool> goodMoment() async {
    if (!_supported) return false;
    try {
      final prefs = await SharedPreferences.getInstance();
      final seen = (prefs.getInt(_countKey) ?? 0) + 1;
      await prefs.setInt(_countKey, seen);
      if (seen < moments) return false;

      final last = DateTime.tryParse(prefs.getString(_askedKey) ?? '');
      if (last != null && _now().difference(last) < again) return false;

      await prefs.setString(_askedKey, _now().toIso8601String());
      await _ask();
      return true;
    } catch (_) {
      // A rating prompt is never worth an error in front of the player.
      return false;
    }
  }
}
