import 'dart:io';

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
  await tester.pumpWidget(
      MaterialApp(theme: rokTheme(), home: const BoardThemeScreen()));
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
    expect((await SharedPreferences.getInstance()).getString('board_skin'),
        marbleSkin.id);
    expect(boardSkin.base(true), marbleSkin.light);
    expect(boardSkin.base(false), marbleSkin.dark);
  });

  testWidgets('every skin and every bundled piece set is offered',
      (tester) async {
    await _open(tester);

    // The wooden skin and the wooden piece set share one label, so a skin is
    // only required to appear, not to appear alone.
    for (final skin in boardSkins) {
      expect(find.text(skin.label), findsWidgets);
    }
    await tester.tap(find.text('Taşlar'));
    await tester.pumpAndSettle();
    for (final set in pieceSets) {
      expect(BoardTheme.isPieceSetAvailable(set), isTrue,
          reason: '${set.id} artwork is missing from the bundle');
      expect(find.text(set.label), findsWidgets);
    }
  });

  testWidgets('preview stays fixed while piece choices scroll on a phone',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
        MaterialApp(theme: rokTheme(), home: const BoardThemeScreen()));
    await tester.pumpAndSettle();
    final preview = find.byKey(const ValueKey('theme-fixed-preview'));
    final initial = tester.getRect(preview);
    await tester.tap(find.text('Taşlar'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('board-options')), findsNothing);
    final list = find.byKey(const ValueKey('piece-options'));
    final scrolling =
        find.descendant(of: list, matching: find.byType(Scrollable)).first;
    await tester.scrollUntilVisible(find.text(iceLavaPieces.label), 200,
        scrollable: scrolling);
    await tester.tap(find.text(iceLavaPieces.label));
    await tester.pumpAndSettle();
    expect(boardPieces.id, iceLavaPieces.id);
    expect(tester.getRect(preview), initial);
    await tester.tap(find.text('Tahta'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('piece-options')), findsNothing);
    expect(find.text(marbleSkin.label), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('a set whose artwork is not bundled stays unavailable', () {
    // Nothing outside `pieceSets` can have been found in the bundle, so this
    // stands in for a set whose files were never added.
    const absent = PieceSet(
        id: 'absent', label: 'Absent', directory: 'assets/pieces/absent');
    expect(BoardTheme.isPieceSetAvailable(absent), isFalse);
  });

  test('an unknown stored piece set falls back to wood', () async {
    SharedPreferences.setMockInitialValues({'board_piece_set': 'absent'});
    await BoardTheme.instance.load();
    expect(boardPieces.id, woodPieces.id);
  });

  test('the glass set names twelve files that are all in the bundle', () async {
    for (final type in [
      c.PieceType.PAWN,
      c.PieceType.KNIGHT,
      c.PieceType.BISHOP,
      c.PieceType.ROOK,
      c.PieceType.QUEEN,
      c.PieceType.KING,
    ]) {
      for (final colour in [c.Color.WHITE, c.Color.BLACK]) {
        final asset = glassPieces.assetFor(c.Piece(type, colour));
        expect(File(asset).existsSync(), isTrue, reason: '$asset is missing');
      }
    }
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
