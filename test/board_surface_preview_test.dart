@Tags(['preview'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chess_puzzle_app/theme/board_theme.dart';
import 'package:chess_puzzle_app/widgets/board_surface.dart';

/// Not an assertion but a darkroom: it paints every skin as a real board
/// and writes the picture out, so the materials can be judged by eye
/// rather than by reading hex codes. Run it with `--tags preview`.
void main() {
  test('paints each skin to build/board_preview.png', () async {
    const square = 64.0;
    // Laid out in rows of three: a single column of nine boards is taller
    // than anything that can be looked at at once.
    const columns = 3;
    final rows = (boardSkins.length + columns - 1) ~/ columns;
    const width = square * 8 * columns;
    final height = square * 8 * rows;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    for (var s = 0; s < boardSkins.length; s++) {
      final skin = boardSkins[s];
      for (var i = 0; i < 64; i++) {
        final file = i % 8, rank = i ~/ 8;
        final light = (rank + file).isEven;
        canvas.save();
        canvas.translate(
            (s % columns) * 8 * square + file * square,
            (s ~/ columns) * 8 * square + rank * square);
        BoardSquarePainter(
          texture: skin.texture,
          base: skin.base(light),
          overlay: Colors.transparent,
          seed: i + (light ? 100 : 200),
          isLight: light,
        ).paint(canvas, const Size(square, square));
        canvas.restore();
      }
    }
    final image = await recorder
        .endRecording()
        .toImage(width.toInt(), height.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final out = File('build/board_preview.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes!.buffer.asUint8List());
    expect(out.lengthSync(), greaterThan(0));
  });
}
