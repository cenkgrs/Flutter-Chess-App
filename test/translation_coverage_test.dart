import 'dart:io';

import 'package:chess_puzzle_app/l10n/translations.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every visible string that is not translated ships in Turkish to an
/// English, German or Russian phone. Nineteen of them had, so the gap is
/// worth a test rather than another reading of the screens.
void main() {
  test('Every fixed LText string has a translation', () {
    final literals = RegExp(r"LText\(\s*'([^'\$]+)'");
    final missing = <String>{};

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      // Not reachable from the app; left out rather than translated.
      if (entity.path.endsWith('home_page_screen.dart')) continue;
      if (entity.path.endsWith('fast_puzzles.dart')) continue;
      for (final match in literals.allMatches(entity.readAsStringSync())) {
        // The source carries \n as two characters; the table holds the
        // newline it stands for.
        final text = match.group(1)!.replaceAll(r'\n', '\n');
        if (text.length < 3) continue;
        // The brand, and the file letters the board indexes into.
        if (text == 'ROK' || text == 'abcdefgh') continue;
        if (translations.containsKey(text)) continue;
        if (templates.keys.any((pattern) => RegExp(pattern).hasMatch(text))) {
          continue;
        }
        missing.add(text);
      }
    }

    expect(missing, isEmpty, reason: 'untranslated: ${missing.join(' | ')}');
  });
}
