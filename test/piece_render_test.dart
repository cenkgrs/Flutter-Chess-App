import 'dart:io';
import 'dart:ui' as ui;
import 'package:chess/chess.dart' as c;
import 'package:chess_puzzle_app/theme/board_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'classic pawn is ten percent shorter without shrinking other pieces',
      (tester) async {
    final normal = GlobalKey(), reduced = GlobalKey();
    const reference = PieceSet(
        id: 'unscaled-classic',
        label: 'Reference',
        directory: 'lib/images/wood',
        whiteTint: Colors.white);
    final pawn = c.Piece(c.PieceType.PAWN, c.Color.WHITE);
    await tester.pumpWidget(MaterialApp(
        home: Center(
            child: Row(mainAxisSize: MainAxisSize.min, children: [
      RepaintBoundary(
          key: normal,
          child: SizedBox(
              width: 100,
              height: 100,
              child: BoardPieceArt(pawn, set: reference, padding: 0))),
      RepaintBoundary(
          key: reduced,
          child: SizedBox(
              width: 100,
              height: 100,
              child: BoardPieceArt(pawn, set: woodPieces, padding: 0))),
    ]))));
    await tester.runAsync(() => precacheImage(
        AssetImage(woodPieces.assetFor(pawn)),
        tester.element(find.byKey(normal))));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      Future<int> height(GlobalKey key) async {
        final image = await (key.currentContext!.findRenderObject()!
                as RenderRepaintBoundary)
            .toImage(pixelRatio: 3);
        final data =
            (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
        var top = image.height, bottom = 0;
        for (var y = 0; y < image.height; y++) {
          for (var x = 0; x < image.width; x++) {
            if (data.getUint8((y * image.width + x) * 4 + 3) > 128) {
              if (y < top) top = y;
              if (y > bottom) bottom = y;
            }
          }
        }
        image.dispose();
        return bottom - top + 1;
      }

      expect(await height(reduced), closeTo(await height(normal) * .9, 2));
    });
  });

  testWidgets('painted pieces keep matching footprints at phone square sizes',
      (tester) async {
    tester.view.physicalSize = const Size(390, 1480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const types = [
      c.PieceType.PAWN,
      c.PieceType.KNIGHT,
      c.PieceType.BISHOP,
      c.PieceType.ROOK,
      c.PieceType.QUEEN,
      c.PieceType.KING
    ];
    final shot = GlobalKey();
    final keys = <String, GlobalKey>{};
    await tester.pumpWidget(MaterialApp(
        home: Center(
            child: RepaintBoundary(
                key: shot,
                child: ColoredBox(
                    color: const Color(0xff414141),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      for (final set in pieceSets) ...[
                        Text(set.label,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12)),
                        for (final side in [c.Color.WHITE, c.Color.BLACK])
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            for (var i = 0; i < types.length; i++)
                              ColoredBox(
                                  color: i.isEven
                                      ? const Color(0xffd9b77e)
                                      : const Color(0xff85552f),
                                  child: RepaintBoundary(
                                      key: keys.putIfAbsent(
                                          '${set.id}/${side.name}/${types[i].name}',
                                          GlobalKey.new),
                                      child: SizedBox(
                                          width: 52,
                                          height: 52,
                                          child: BoardPieceArt(
                                              c.Piece(types[i], side),
                                              set: set,
                                              padding: 0))))
                          ])
                      ]
                    ]))))));
    final context = tester.element(find.byKey(shot));
    await tester.runAsync(() async {
      for (final set in pieceSets) {
        for (final side in [c.Color.WHITE, c.Color.BLACK]) {
          for (final type in types) {
            await precacheImage(
                AssetImage(set.assetFor(c.Piece(type, side))), context);
          }
        }
      }
    });
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.runAsync(() async {
      final ranges = <String, List<Rect>>{};
      for (final set in pieceSets.where((s) => s.art == PieceArt.painted)) {
        for (final side in [c.Color.WHITE, c.Color.BLACK]) {
          for (final type in types) {
            final key = keys['${set.id}/${side.name}/${type.name}']!;
            final boundary = key.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
            final image = await boundary.toImage(pixelRatio: 3);
            final data =
                (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
            var left = image.width, top = image.height, right = 0, bottom = 0;
            for (var y = 0; y < image.height; y++) {
              for (var x = 0; x < image.width; x++) {
                if (data.getUint8((y * image.width + x) * 4 + 3) < 128) {
                  continue;
                }
                if (x < left) left = x;
                if (x > right) right = x;
                if (y < top) top = y;
                if (y > bottom) bottom = y;
              }
            }
            expect(left, greaterThan(0),
                reason: 'clipped ${set.id}/${type.name}');
            expect(top, greaterThan(0));
            expect(right, lessThan(image.width - 1));
            expect(bottom, lessThan(image.height - 1));
            ranges.putIfAbsent(type.name, () => []).add(Rect.fromLTRB(
                left.toDouble(),
                top.toDouble(),
                right.toDouble(),
                bottom.toDouble()));
            image.dispose();
          }
        }
      }
      for (final entries in ranges.values) {
        final first = entries.first;
        for (final rect in entries.skip(1)) {
          expect((rect.height - first.height).abs(), lessThanOrEqualTo(4));
          expect((rect.width - first.width).abs(), lessThanOrEqualTo(4));
          expect((rect.bottom - first.bottom).abs(), lessThanOrEqualTo(3));
        }
      }
      final image = await (shot.currentContext!.findRenderObject()!
              as RenderRepaintBoundary)
          .toImage(pixelRatio: 3);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      final path = File('build/qa/piece-proportions.png');
      await path.parent.create(recursive: true);
      await path.writeAsBytes(png!.buffer.asUint8List());
      image.dispose();
    });
  });
}
