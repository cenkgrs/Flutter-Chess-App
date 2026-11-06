import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../l10n/app_language.dart';

/// What the reminder needs from the operating system, named small enough
/// that a test can stand in for it.
abstract class ReminderChannel {
  Future<bool> requestPermission();
  Future<void> scheduleAt(DateTime when, String title, String body);
  Future<void> cancel();
}

/// Reminds the player that today's puzzle is still unsolved.
///
/// The streak is the one thing in the app that is lost by not opening it,
/// so it is the one thing worth a notification. Nothing else gets one:
/// a reminder the player did not want is uninstalled faster than it is
/// turned off.
class PuzzleReminder extends ChangeNotifier {
  PuzzleReminder({ReminderChannel? channel, DateTime Function()? clock})
      : _channel = channel ?? _SystemNotifications(),
        _now = clock ?? DateTime.now;

  static PuzzleReminder instance = PuzzleReminder();

  /// Late enough that the day has had its chance, early enough to act on.
  static const hour = 19;

  static const _enabledKey = 'puzzle_reminder_enabled';
  static const _askedKey = 'puzzle_reminder_asked';

  final ReminderChannel _channel;
  final DateTime Function() _now;

  bool _enabled = false;
  bool get enabled => _enabled;

  /// Whether the player has already been asked once, in the app's own
  /// words. iOS shows its permission sheet once per install, so the
  /// question is worth asking where the answer is obvious.
  bool _asked = false;
  bool get asked => _asked;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _enabled = prefs.getBool(_enabledKey) ?? false;
      _asked = prefs.getBool(_askedKey) ?? false;
    } catch (_) {
      // A reminder is never worth a failed start.
    }
  }

  /// Records that the question has been put to the player, whatever they
  /// answered, so the app does not ask a second time.
  Future<void> markAsked() async {
    if (_asked) return;
    _asked = true;
    await _write(_askedKey, true);
  }

  Future<void> setEnabled(bool value) async {
    if (value && !await _channel.requestPermission()) {
      // Permission refused: the switch has nothing to turn on.
      if (_enabled) {
        _enabled = false;
        notifyListeners();
        await _write(_enabledKey, false);
      }
      return;
    }
    _enabled = value;
    notifyListeners();
    await _write(_enabledKey, value);
    if (!value) await _channel.cancel();
  }

  /// Puts the next reminder where it belongs: tonight when today's puzzle
  /// is still open, tomorrow night when it is already solved. Called every
  /// time the app learns the day's status, so a solve cancels the evening.
  Future<void> sync({required bool solvedToday}) async {
    if (!_enabled) return;
    try {
      await _channel.cancel();
      final when = nextReminder(solvedToday: solvedToday);
      if (when == null) return;
      final code = AppLanguage.instance.locale?.languageCode ?? 'tr';
      await _channel.scheduleAt(
        when,
        trLang(code, 'Günün bulmacası seni bekliyor'),
        trLang(code, 'Seriyi bozma — çözmek birkaç dakika sürer.'),
      );
    } catch (_) {
      // The puzzle itself must not fail because a reminder could not be set.
    }
  }

  /// The evening this reminder belongs to, or null when tonight has passed
  /// and today is still unsolved — a reminder for a day that is over helps
  /// nobody, and tomorrow's is set when tomorrow's status is known.
  @visibleForTesting
  DateTime? nextReminder({required bool solvedToday}) {
    final now = _now();
    final tonight = DateTime(now.year, now.month, now.day, hour);
    if (solvedToday) return tonight.add(const Duration(days: 1));
    return tonight.isAfter(now) ? tonight : null;
  }

  Future<void> _write(String key, bool value) async {
    try {
      await (await SharedPreferences.getInstance()).setBool(key, value);
    } catch (_) {}
  }
}

class _SystemNotifications implements ReminderChannel {
  static const _id = 41;
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> _prepare() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    final zone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(zone.identifier));
    await _plugin.initialize(const InitializationSettings(
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ));
    _ready = true;
  }

  @override
  Future<bool> requestPermission() async {
    await _prepare();
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(alert: true, sound: true) ?? false;
    }
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await android?.requestNotificationsPermission() ?? false;
  }

  @override
  Future<void> scheduleAt(DateTime when, String title, String body) async {
    await _prepare();
    await _plugin.zonedSchedule(
      _id,
      title,
      body,
      tz.TZDateTime.from(when, tz.local),
      const NotificationDetails(
        iOS: DarwinNotificationDetails(),
        android: AndroidNotificationDetails('daily_puzzle', 'Daily puzzle',
            importance: Importance.defaultImportance),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  @override
  Future<void> cancel() => _plugin.cancel(_id);
}
