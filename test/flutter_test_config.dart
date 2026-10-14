import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:chess_puzzle_app/l10n/app_language.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  AppLanguage.instance.locale = const Locale('tr');
  await testMain();
}
