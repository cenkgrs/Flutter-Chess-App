import 'package:chess_puzzle_app/backend/rating_prompt.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// iOS gives an app three rating sheets a year at most, so the rules that
/// decide when to spend one are worth holding still.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  var asked = 0;
  var now = DateTime(2026, 11, 4);

  RatingPrompt build() => RatingPrompt(
        ask: () async => asked++,
        clock: () => now,
        supported: true,
      );

  setUp(() {
    asked = 0;
    now = DateTime(2026, 11, 4);
    SharedPreferences.setMockInitialValues({});
  });

  test('stays quiet until the player has had a few good moments', () async {
    final prompt = build();
    for (var i = 1; i < RatingPrompt.moments; i++) {
      expect(await prompt.goodMoment(), isFalse, reason: 'moment $i');
    }
    expect(asked, 0);

    expect(await prompt.goodMoment(), isTrue);
    expect(asked, 1);
  });

  test('does not ask twice in the same four months', () async {
    final prompt = build();
    for (var i = 0; i < RatingPrompt.moments; i++) {
      await prompt.goodMoment();
    }
    expect(asked, 1);

    now = now.add(RatingPrompt.again - const Duration(days: 1));
    expect(await prompt.goodMoment(), isFalse);
    expect(asked, 1);

    now = now.add(const Duration(days: 2));
    expect(await prompt.goodMoment(), isTrue);
    expect(asked, 2);
  });

  test('asks nothing where the sheet does not exist', () async {
    final prompt = RatingPrompt(
      ask: () async => asked++,
      clock: () => now,
      supported: false,
    );
    for (var i = 0; i < RatingPrompt.moments + 1; i++) {
      expect(await prompt.goodMoment(), isFalse);
    }
    expect(asked, 0);
  });

  test('a losing streak after the ask does not reset the wait', () async {
    final prompt = build();
    for (var i = 0; i < RatingPrompt.moments + 5; i++) {
      await prompt.goodMoment();
    }
    expect(asked, 1);
  });
}
