import 'package:chess_puzzle_app/legal/open_source_compliance.dart';
import 'package:chess_puzzle_app/screens/open_source_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('source revision produces an immutable source-tree URL', () {
    expect(
      sourceUriForRevision('0123456789abcdef0123456789abcdef01234567'),
      Uri.parse(
          'https://github.com/cenkgrs/Flutter-Chess-App/tree/0123456789abcdef0123456789abcdef01234567'),
    );
    expect(isValidSourceRevision('0123456789abcdef0123456789abcdef01234567'),
        isTrue);
    expect(isValidSourceRevision('0123456789abcdef'), isFalse);
    expect(isValidSourceRevision('v0.1.0+1'), isFalse);
    expect(isValidSourceRevision('master'), isFalse);
  });

  testWidgets('open-source screen exposes license and corresponding source',
      (tester) async {
    Uri? opened;
    await tester.pumpWidget(MaterialApp(
      home: OpenSourceScreen(openLink: (uri) async {
        opened = uri;
        return true;
      }),
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('GPL-3.0-or-later'), findsWidgets);
    expect(find.byKey(const ValueKey('source-revision')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('corresponding-source-link')));
    await tester.pump();
    expect(opened, correspondingSourceUri);
  });
}
