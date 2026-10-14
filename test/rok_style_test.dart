import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chess_puzzle_app/widgets/rok_style.dart';

void main() {
  testWidgets('shared page has wood and transparent header', (tester) async {
    await tester.pumpWidget(MaterialApp(
        theme: rokTheme(),
        home: RokScaffold(
            appBar: AppBar(title: const Text('ROK')),
            body: const Text('Test'))));
    expect(tester.widget<AppBar>(find.byType(AppBar)).backgroundColor,
        Colors.transparent);
    expect(
        find.byWidgetPredicate(
            (w) => w is DecoratedBox && w.decoration == rokWood),
        findsOneWidget);
  });
  testWidgets('result dialog uses ROK colors and styled actions',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: RokDialog(title: const Text('Kazandın!'), actions: [
      FilledButton(onPressed: () {}, child: const Text('Menüye dön'))
    ]))));
    final context = tester.element(find.byType(AlertDialog));
    expect(Theme.of(context).dialogTheme.backgroundColor, rokGraphite);
    expect(find.text('Kazandın!'), findsOneWidget);
    expect(find.text('Menüye dön'), findsOneWidget);
  });
}
