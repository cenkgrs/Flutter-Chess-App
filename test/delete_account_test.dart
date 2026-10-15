import 'dart:async';
import 'package:chess_puzzle_app/screens/delete_account_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'Deletion requires checkbox and final confirmation; cancel is safe',
      (tester) async {
    var calls = 0;
    await tester.pumpWidget(
        MaterialApp(home: DeleteAccountScreen(deleteAccount: () async {
      calls++;
    })));
    final button = find.widgetWithText(FilledButton, 'Hesabımı sil');
    await tester.ensureVisible(button);
    expect(tester.widget<FilledButton>(button).onPressed, isNull);
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    await tester.tap(button);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vazgeç'));
    await tester.pumpAndSettle();
    expect(calls, 0);
  });
  testWidgets(
      'Waits for server confirmation, blocks duplicates, then shows success',
      (tester) async {
    final done = Completer<void>();
    var calls = 0;
    await tester
        .pumpWidget(MaterialApp(home: DeleteAccountScreen(deleteAccount: () {
      calls++;
      return done.future;
    })));
    await tester.ensureVisible(find.byType(CheckboxListTile));
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    final button = find.widgetWithText(FilledButton, 'Hesabımı sil');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kalıcı olarak sil'));
    await tester.pump();
    expect(calls, 1);
    expect(find.text('Hesabın silindi'), findsNothing);
    expect(
        tester
            .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Siliniyor…'))
            .onPressed,
        isNull);
    done.complete();
    await tester.pumpAndSettle();
    expect(find.text('Hesabın silindi'), findsOneWidget);
  });
  testWidgets('Server error does not claim deletion', (tester) async {
    await tester.pumpWidget(
        MaterialApp(home: DeleteAccountScreen(deleteAccount: () async {
      throw StateError('offline');
    })));
    await tester.ensureVisible(find.byType(CheckboxListTile));
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    final button = find.widgetWithText(FilledButton, 'Hesabımı sil');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kalıcı olarak sil'));
    await tester.pumpAndSettle();
    expect(find.text('Hesabın silindi'), findsNothing);
    expect(find.textContaining('Silme işlemi doğrulanamadı.'), findsOneWidget);
  });
}
