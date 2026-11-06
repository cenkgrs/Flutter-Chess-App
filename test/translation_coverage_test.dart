import 'dart:io';

import 'package:chess_puzzle_app/l10n/translations.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every visible string that is not translated ships in Turkish to an
/// English, German or Russian phone. Scanning only `LText('…')` missed the
/// ones handed to a widget as `title:` or built in a getter, so this walks
/// every literal that can reach the screen and resolves it the way the
/// runtime translator does.
bool _covered(String text) {
  if (text.length < 3) return true;
  if (translations.containsKey(text)) return true;
  for (final pattern in templates.keys) {
    final match = RegExp(pattern).firstMatch(text);
    if (match == null) continue;
    for (var i = 1; i <= match.groupCount; i++) {
      final capture = match[i] ?? '';
      if (capture.length < text.length && !_covered(capture)) return false;
    }
    return true;
  }
  // The translator splits on these and translates each part on its own.
  for (final separator in ['\n', '  ·  ', ' · ', ' ve ']) {
    if (text.contains(separator)) {
      return text.split(separator).every(_covered);
    }
  }
  return false;
}

void main() {
  test('Every fixed Turkish string has a translation', () {
    final literal = RegExp(r"'((?:[^'\\\$]|\\.)*)'");
    // Lines that carry protocol, query or debug strings rather than UI.
    final plumbing = RegExp(r"debugPrint|ValueKey|AssetImage|package:|RegExp|"
        r"\.select\(|\.order\(|\.eq\(|\.rpc\(|import |export |print\(|assert\(");
    const exempt = {
      'ROK',
      'abcdefgh',
      // A proper name, the same in every language.
      'Art Deco',
      // Sent to Stockfish, never shown.
      'setoption name Threads value 1',
      'setoption name Hash value 32',
      // Thrown, not rendered.
      'Account deletion was not confirmed',
      // An Android notification channel name; the app ships on iOS only.
      'Daily puzzle',
    };
    final missing = <String>{};

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path.contains('l10n/')) continue;
      for (final line in entity.readAsLinesSync()) {
        if (line.trimLeft().startsWith('//')) continue;
        if (plumbing.hasMatch(line)) continue;
        for (final match in literal.allMatches(line)) {
          final raw = match.group(1)!;
          // The source carries \n as two characters; the table holds the
          // newline it stands for.
          final text = raw.replaceAll(r'\n', '\n');
          if (exempt.contains(text)) continue;
          if (text.contains('/') ||
              text.contains('_') ||
              RegExp(r'^[a-z ]+$').hasMatch(text)) {
            continue;
          }
          if (!RegExp(r'[A-Za-zıİşŞğĞüÜöÖçÇ]').hasMatch(text)) continue;
          // A single word is only UI when this line renders it; anything
          // else that short is a map key or an engine token.
          final shown = RegExp("LText\\(\\s*'${RegExp.escape(raw)}'")
                  .hasMatch(line) ||
              RegExp("(?:title|subtitle|note|label|tooltip|hintText|labelText|"
                      "message|text)\\s*:\\s*'${RegExp.escape(raw)}'")
                  .hasMatch(line);
          if (!text.contains(' ') && !shown) continue;
          if (_covered(text)) continue;
          missing.add(text);
        }
      }
    }

    expect(missing, isEmpty, reason: 'untranslated: ${missing.join(' | ')}');
  });
}
