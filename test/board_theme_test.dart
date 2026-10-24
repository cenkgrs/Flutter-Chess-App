import 'package:chess/chess.dart' as c;
import 'package:chess_puzzle_app/screens/board_theme_screen.dart';
import 'package:chess_puzzle_app/theme/board_theme.dart';
import 'package:chess_puzzle_app/widgets/rok_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tall enough that the whole list lays out, so every option can be tapped
/// without scrolling the lazily built list first.
Future<void> _open(WidgetTester tester) async {
  tester.view.physicalSize = const Size(900, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester
      .pumpWidget(MaterialApp(theme: rokTheme(), home: const BoardThemeScreen()));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await BoardTheme.instance.load();
  });

  tearDown(() async {
    SharedPreferences.setMockInitialValues({});
    await BoardTheme.instance.load();
  });

  testWidgets('a skin applies at once and is remembered', (tester) async {
    expect(boardSkin.id, woodSkin.id);

    await _open(tester);
    await tester.tap(find.text(marbleSkin.label));
    await tester.pumpAndSettle();

    expect(boardSkin.id, marbleSkin.id);
    expect(
        (await SharedPreferences.getInstance()).getString('board_skin'),
        marbleSkin.id);
    expect(boardSkin.base(true), marbleSkin.light);
    expect(boardSkin.base(false), marbleSkin.dark);
  });

  testWidgets('every skin is offered and only bundled piece sets are',
      (tester) async {
    await _open(tester);

    // The wooden skin and the wooden piece set share one label, so a skin is
    // only required to appear, not to appear alone.
    for (final skin in boardSkins) {
      expect(find.text(skin.label), findsWidgets);
    }
    expect(find.text(woodPieces.label), findsWidgets);
    // The glass set is what proves unbundled artwork stays hidden.
    expect(BoardTheme.isPieceSetAvailable(glassPieces), isFalse);
    expect(find.text(glassPieces.label), findsNothing);
  });

  test('a piece set that is not bundled is never restored', () async {
    SharedPreferences.setMockInitialValues({'board_piece_set': glassPieces.id});
    await BoardTheme.instance.load();
    expect(boardPieces.id, woodPieces.id);
  });

  test('painted sets name one file per side, silhouettes one per type', () {
    final whiteKing = c.Piece(c.PieceType.KING, c.Color.WHITE);
    final blackKing = c.Piece(c.PieceType.KING, c.Color.BLACK);

    expect(woodPieces.assetFor(whiteKing), woodPieces.assetFor(blackKing));
    expect(woodPieces.tintFor(whiteKing), isNot(woodPieces.tintFor(blackKing)));

    expect(glassPieces.assetFor(whiteKing), 'assets/pieces/glass/w_king.png');
    expect(glassPieces.assetFor(blackKing), 'assets/pieces/glass/b_king.png');
    expect(glassPieces.tintFor(whiteKing), isNull);
  });
}
