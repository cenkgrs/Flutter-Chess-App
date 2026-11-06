import 'package:chess_puzzle_app/backend/puzzle_reminder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeChannel implements ReminderChannel {
  FakeChannel({this.grant = true});
  final bool grant;
  int asks = 0, cancels = 0;
  final scheduled = <DateTime>[];
  String? lastTitle;

  @override
  Future<bool> requestPermission() async {
    asks++;
    return grant;
  }

  @override
  Future<void> scheduleAt(DateTime when, String title, String body) async {
    scheduled.add(when);
    lastTitle = title;
  }

  @override
  Future<void> cancel() async => cancels++;
}

/// A reminder the player did not ask for is worse than none, and one that
/// fires after the puzzle is solved is worse still; both rules live here.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  var now = DateTime(2026, 11, 6, 10);
  late FakeChannel channel;

  PuzzleReminder build({bool grant = true}) {
    channel = FakeChannel(grant: grant);
    return PuzzleReminder(channel: channel, clock: () => now);
  }

  setUp(() {
    now = DateTime(2026, 11, 6, 10);
    SharedPreferences.setMockInitialValues({});
  });

  test('schedules nothing until the player turns it on', () async {
    final reminder = build();
    await reminder.load();
    expect(reminder.enabled, isFalse);
    await reminder.sync(solvedToday: false);
    expect(channel.scheduled, isEmpty);
  });

  test('an open day is reminded this evening', () async {
    final reminder = build();
    await reminder.setEnabled(true);
    await reminder.sync(solvedToday: false);
    expect(channel.scheduled.single, DateTime(2026, 11, 6, PuzzleReminder.hour));
    expect(channel.lastTitle, isNotEmpty);
  });

  test('a solved day is reminded tomorrow instead', () async {
    final reminder = build();
    await reminder.setEnabled(true);
    await reminder.sync(solvedToday: true);
    expect(channel.scheduled.single, DateTime(2026, 11, 7, PuzzleReminder.hour));
  });

  test('nothing is scheduled for an evening already past', () async {
    now = DateTime(2026, 11, 6, 22);
    final reminder = build();
    await reminder.setEnabled(true);
    await reminder.sync(solvedToday: false);
    expect(channel.scheduled, isEmpty);
    expect(channel.cancels, 1);
  });

  test('a refused permission leaves the switch off', () async {
    final reminder = build(grant: false);
    await reminder.setEnabled(true);
    expect(reminder.enabled, isFalse);
    expect(channel.asks, 1);
    await reminder.sync(solvedToday: false);
    expect(channel.scheduled, isEmpty);
  });

  test('turning it off cancels what was pending', () async {
    final reminder = build();
    await reminder.setEnabled(true);
    await reminder.sync(solvedToday: false);
    await reminder.setEnabled(false);
    expect(channel.cancels, 2);
    expect(reminder.enabled, isFalse);
  });

  test('the choice and the question both survive a restart', () async {
    final first = build();
    await first.setEnabled(true);
    await first.markAsked();
    final second = build();
    await second.load();
    expect(second.enabled, isTrue);
    expect(second.asked, isTrue);
  });
}
