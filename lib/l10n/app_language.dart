import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'translations.dart';

class AppLanguage extends ChangeNotifier {
  static final instance = AppLanguage();
  Locale? locale;
  static const supported = [
    Locale('tr'),
    Locale('en'),
    Locale('de'),
    Locale('ru')
  ];
  Future<void> load() async {
    final saved = (await SharedPreferences.getInstance()).getString('language');
    if (supported.any((l) => l.languageCode == saved)) locale = Locale(saved!);
  }

  Future<void> set(String? code) async {
    locale = code == null ? null : Locale(code);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (code == null) {
      await prefs.remove('language');
    } else {
      await prefs.setString('language', code);
    }
  }
}

String tr(BuildContext context, String source) {
  // Always register a locale dependency, including when the user overrides it.
  final inheritedLocale = Localizations.maybeLocaleOf(context);
  final code = AppLanguage.instance.locale?.languageCode ??
      inheritedLocale?.languageCode ??
      'tr';
  final index = ['en', 'de', 'ru'].indexOf(code);
  if (index < 0) return source;
  final direct = translations[source];
  if (direct != null) return direct[index];
  for (final entry in translations.entries) {
    if (_fold(entry.key) == _fold(source)) {
      return source == source.toUpperCase()
          ? entry.value[index].toUpperCase()
          : entry.value[index];
    }
  }
  // Only known UI templates are translated; arbitrary usernames stay intact.
  for (final entry in templates.entries) {
    final match = RegExp(entry.key).firstMatch(source);
    if (match == null) continue;
    var output = entry.value[index];
    for (var i = 1; i <= match.groupCount; i++) {
      final capture = match[i] ?? '';
      output = output.replaceAll('{$i}',
          capture.length < source.length ? tr(context, capture) : capture);
    }
    return output;
  }
  for (final separator in ['\n', '  ·  ', ' · ', ' ve ']) {
    if (source.contains(separator)) {
      final translated =
          source.split(separator).map((part) => tr(context, part)).toList();
      return translated.join(
          separator == ' ve ' ? [' and ', ' und ', ' и '][index] : separator);
    }
  }
  return source;
}

String _fold(String s) => s
    .replaceAll('İ', 'i')
    .replaceAll('I', 'i')
    .replaceAll('ı', 'i')
    .toLowerCase();

class LText extends StatelessWidget {
  const LText(this.data,
      {super.key,
      this.style,
      this.textAlign,
      this.maxLines,
      this.overflow,
      this.softWrap,
      this.textDirection});
  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;
  final TextDirection? textDirection;
  @override
  Widget build(BuildContext context) => Text(tr(context, data),
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
      textDirection: textDirection);
}
