@Tags(['preview'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:chess/chess.dart' as c;
import 'package:chess_puzzle_app/theme/board_theme.dart';
import 'package:chess_puzzle_app/theme/piece_geometry.dart';
import 'package:chess_puzzle_app/widgets/board_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every piece set on every board, one picture per set. A skin can look
/// right empty and still swallow a set's pieces; this is the only way to
/// see that before a player does. Run it with `--tags preview`.
///
/// It paints straight onto a canvas rather than through the widget tree:
/// the same picture built with `testWidgets` and `precacheImage` left each
/// test hanging until the ten-minute timeout, nine times over.
void main() {
  const square = 44.0;
  const board = square * 8;
  const columns = 3;

  final position = c.Chess.fromFEN(
      'r1bqk2r/pppp1ppp/2n2n2/2b1p3/2B1P3/2N2N2/PPPP1PPP/R1BQK2R w KQkq - 0 1');

  Future<ui.Image> load(String path) async {
    final codec = await ui.instantiateImageCodec(File(path).readAsBytesSync());
    return (await codec.getNextFrame()).image;
  }

  for (final set in pieceSets) {
    test('paints ${set.id} on every board', () async {
      final art = <String, ui.Image>{};
      for (final colour in [c.Color.WHITE, c.Color.BLACK]) {
        for (final type in [
          c.PieceType.KING,
          c.PieceType.QUEEN,
          c.PieceType.ROOK,
          c.PieceType.BISHOP,
          c.PieceType.KNIGHT,
          c.PieceType.PAWN,
        ]) {
          final asset = set.assetFor(c.Piece(type, colour));
          art[asset] ??= await load(asset);
        }
      }

      final rows = (boardSkins.length + columns - 1) ~/ columns;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      for (var s = 0; s < boardSkins.length; s++) {
        final skin = boardSkins[s];
        final origin = Offset((s % columns) * board, (s ~/ columns) * board);
        for (var i = 0; i < 64; i++) {
          final file = i % 8, rank = 8 - i ~/ 8;
          final light = (i ~/ 8 + file).isEven;
          final piece = position.get('${'abcdefgh'[file]}$rank');
          final at = origin + Offset(file * square, (8 - rank) * square);

          canvas.save();
          canvas.translate(at.dx, at.dy);
          BoardSquarePainter(
            texture: skin.texture,
            base: skin.base(light),
            overlay: Colors.transparent,
            seed: i + (light ? 100 : 200),
            isLight: light,
            pieceIsLight: piece == null ? null : piece.color == c.Color.WHITE,
          ).paint(canvas, const Size(square, square));

          if (piece != null) {
            final asset = set.assetFor(piece);
            final image = art[asset]!;
            // The same crop the board does: a product shot carries air
            // around the piece that a square cannot afford.
            final painted = set.art == PieceArt.painted &&
                paintedPieceBounds.containsKey(asset);
            final bounds = painted
                ? paintedPieceBounds[asset]!
                : const Rect.fromLTWH(0, 0, 1, 1);
            final source = Rect.fromLTWH(
                bounds.left * image.width,
                bounds.top * image.height,
                bounds.width * image.width,
                bounds.height * image.height);
            final frame = painted
                ? paintedPieceFrame(piece.type)
                : const Rect.fromLTWH(.07, .07, .86, .86);
            final paint = Paint()..filterQuality = FilterQuality.high;
            final tint = set.tintFor(piece);
            if (tint != null) {
              paint.colorFilter = ColorFilter.mode(tint, BlendMode.srcIn);
            }
            canvas.drawImageRect(
                image,
                source,
                Rect.fromLTWH(frame.left * square, frame.top * square,
                    frame.width * square, frame.height * square),
                paint);
          }
          canvas.restore();
        }
      }

      final image = await recorder
          .endRecording()
          .toImage((board * columns).toInt(), (board * rows).toInt());
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final out = File('build/matrix_${set.id}.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(bytes!.buffer.asUint8List());
      expect(out.lengthSync(), greaterThan(0));
    });
  }
}
