import 'dart:async';

import 'package:chess_puzzle_app/backend/analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records what would have been sent to Supabase.
class _Recorder {
  final calls = <Map<String, dynamic>>[];

  Future<void> call(String name, Map<String, dynamic> params) async {
    calls.add({'rpc': name, ...params});
  }
}

void main() {
  test('an event carries its name, version and platform', () async {
    final sent = _Recorder();
    await AnalyticsService(request: sent.call)
        .record(AnalyticsEvent.gameStarted, metadata: {'mode': 'offline'});

    expect(sent.calls, hasLength(1));
    final call = sent.calls.single;
    expect(call['rpc'], 'log_analytics_event');
    expect(call['p_event'], 'game_started');
    expect(call['p_metadata'], {'mode': 'offline'});
    expect(call['p_app_version'], appVersion);
    expect(call['p_platform'], currentPlatform);
  });

  test('every declared event has a distinct wire name', () {
    final names = AnalyticsEvent.values.map((e) => e.name).toList();
    expect(names.toSet(), hasLength(names.length));
    // The database check constraint lists exactly these.
    expect(names, containsAll(<String>[
      'app_opened',
      'user_signed_up',
      'user_logged_in',
      'game_started',
      'game_finished',
      'assistant_used',
      'analysis_used',
      'subscription_started',
      'subscription_restored',
      'theme_changed',
      'piece_set_changed',
    ]));
    expect(names, hasLength(11));
  });

  test('the client never sends a user id; the database decides', () async {
    // Guest or member, the payload is identical: user attribution happens in
    // `log_analytics_event` from auth.uid(), so a caller cannot forge it.
    final sent = _Recorder();
    await AnalyticsService(request: sent.call).record(AnalyticsEvent.appOpened);
    expect(sent.calls.single.keys, isNot(contains('p_user_id')));
    expect(sent.calls.single.keys,
        unorderedEquals(['rpc', 'p_event', 'p_metadata', 'p_app_version', 'p_platform']));
  });

  test('metadata defaults to an empty map rather than null', () async {
    final sent = _Recorder();
    await AnalyticsService(request: sent.call).record(AnalyticsEvent.appOpened);
    expect(sent.calls.single['p_metadata'], isEmpty);
  });

  test('a backend failure is swallowed', () async {
    final service = AnalyticsService(
        request: (name, params) async => throw StateError('offline'));
    await expectLater(
        service.record(AnalyticsEvent.appOpened), completes);
  });

  test('a hanging backend gives up instead of waiting forever', () async {
    final service = AnalyticsService(
        request: (name, params) => Completer<void>().future);
    await expectLater(
        service.record(AnalyticsEvent.appOpened).timeout(
            const Duration(seconds: 20)),
        completes);
  }, timeout: const Timeout(Duration(seconds: 30)));

  test('log returns without waiting for the backend', () async {
    final released = Completer<void>();
    var finished = false;
    final service = AnalyticsService(request: (name, params) async {
      await released.future;
      finished = true;
    });

    service.log(AnalyticsEvent.appOpened);
    // The caller carried on while the request was still in flight.
    expect(finished, isFalse);
    released.complete();
    await Future<void>.delayed(Duration.zero);
    expect(finished, isTrue);
  });

  test('a disabled service stays silent', () async {
    final sent = _Recorder();
    await AnalyticsService(request: sent.call, enabled: false)
        .record(AnalyticsEvent.appOpened);
    expect(sent.calls, isEmpty);
  });

  test('the platform name is one the database accepts', () {
    const accepted = {
      'ios',
      'android',
      'macos',
      'windows',
      'linux',
      'web',
      'unknown'
    };
    expect(accepted, contains(currentPlatform));
    // Guards the mapping if a new TargetPlatform appears.
    for (final platform in TargetPlatform.values) {
      debugDefaultTargetPlatformOverride = platform;
      expect(accepted, contains(currentPlatform), reason: '$platform');
    }
    debugDefaultTargetPlatformOverride = null;
  });

  test('the app version fits the column', () {
    expect(appVersion, isNotEmpty);
    expect(appVersion.length, lessThanOrEqualTo(32));
  });
}
