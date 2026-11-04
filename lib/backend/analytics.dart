import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'app_backend.dart';

/// Product analytics. Every event in the app goes through here; no screen
/// writes to Supabase itself.
///
/// Analytics is never allowed to affect play. `log` returns immediately,
/// swallows every failure, and gives up after a few seconds, so a phone with
/// no signal behaves exactly like one with it. Nothing here is read back.
///
/// The row's user is taken from the session by the database, not sent from
/// here, so a guest is recorded as a guest and a member cannot be attributed
/// to anyone else.

enum AnalyticsEvent {
  appOpened('app_opened'),
  userSignedUp('user_signed_up'),
  userLoggedIn('user_logged_in'),
  gameStarted('game_started'),
  gameFinished('game_finished'),
  assistantUsed('assistant_used'),
  analysisUsed('analysis_used'),
  subscriptionStarted('subscription_started'),
  subscriptionRestored('subscription_restored'),
  themeChanged('theme_changed'),
  pieceSetChanged('piece_set_changed');

  const AnalyticsEvent(this.name);

  final String name;
}

/// Reported with every event so one build can be told apart from another.
///
/// `loadAppVersion` reads it from the bundle at startup, which is the only
/// source that cannot be forgotten: the App Store build of 1.0 went out
/// without the dart-define and reported "1.0.0" for every build number. The
/// define stays as the fallback for tests and for a platform with no bundle.
String appVersion =
    const String.fromEnvironment('ROK_APP_VERSION', defaultValue: '1.0.0');

/// Never throws: analytics must not be able to stop the app from starting.
Future<void> loadAppVersion() async {
  try {
    final info = await PackageInfo.fromPlatform();
    if (info.version.isEmpty) return;
    final build = info.buildNumber;
    appVersion = build.isEmpty ? info.version : '${info.version}+$build';
  } catch (_) {
    // Keep whatever the dart-define left.
  }
}

String get currentPlatform {
  if (kIsWeb) return 'web';
  return switch (defaultTargetPlatform) {
    TargetPlatform.iOS => 'ios',
    TargetPlatform.android => 'android',
    TargetPlatform.macOS => 'macos',
    TargetPlatform.windows => 'windows',
    TargetPlatform.linux => 'linux',
    _ => 'unknown',
  };
}

class AnalyticsService {
  AnalyticsService({this.request, this.enabled = true});

  /// Injected by tests in place of the Supabase call.
  final Future<void> Function(String name, Map<String, dynamic> params)?
      request;

  /// Off in widget tests that have no backend, so they do not reach out.
  final bool enabled;

  static AnalyticsService instance = AnalyticsService();

  static const _timeout = Duration(seconds: 5);

  /// Records an event without making the caller wait or handle failure.
  void log(AnalyticsEvent event, {Map<String, dynamic>? metadata}) {
    unawaited(record(event, metadata: metadata));
  }

  /// The awaitable form, for tests. It never throws either.
  Future<void> record(AnalyticsEvent event,
      {Map<String, dynamic>? metadata}) async {
    if (!enabled) return;
    try {
      final params = <String, dynamic>{
        'p_event': event.name,
        'p_metadata': metadata ?? const <String, dynamic>{},
        'p_app_version': appVersion,
        'p_platform': currentPlatform,
      };
      if (request != null) {
        await request!('log_analytics_event', params).timeout(_timeout);
        return;
      }
      if (!AppBackend.isConfigured) return;
      await AppBackend.client
          .rpc('log_analytics_event', params: params)
          .timeout(_timeout);
    } catch (_) {
      // Analytics is the least important thing the app does.
    }
  }
}
