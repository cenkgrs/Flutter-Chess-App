import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/board_theme.dart';

/// One square of the board, painted as the material its skin names.
///
/// Only the offline board used to carry a texture, and only the wooden
/// skin had one: everywhere else four flat colours stood in for marble,
/// slate and ice. A square is small, so the texture has to be cheap and
/// quiet — a lit gradient, a few strokes, and the square's own seed so
/// that neighbours never repeat.
class BoardSquareSurface extends StatelessWidget {
  const BoardSquareSurface({
    super.key,
    required this.skin,
    required this.isLight,
    required this.seed,
    required this.child,
    this.overlay = Colors.transparent,
    this.base,
  });

  final BoardSkin skin;
  final bool isLight;
  final int seed;

  /// A square the screen has already decided the colour of — a selection
  /// or a premove — keeps that colour and still gets the material.
  final Color? base;
  final Color overlay;
  final Widget child;

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: BoardSquarePainter(
          texture: skin.texture,
          base: base ?? skin.base(isLight),
          overlay: overlay,
          seed: seed,
          isLight: isLight,
        ),
        child: child,
      );
}

@visibleForTesting
class BoardSquarePainter extends CustomPainter {
  const BoardSquarePainter({
    required this.texture,
    required this.base,
    required this.overlay,
    required this.seed,
    required this.isLight,
  });

  final SurfaceTexture texture;
  final Color base;
  final Color overlay;
  final int seed;
  final bool isLight;

  Color _shift(double by) {
    final hsl = HSLColor.fromColor(base);
    return hsl.withLightness((hsl.lightness + by).clamp(0, 1)).toColor();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_shift(.045), base, _shift(-.035)],
        ).createShader(rect),
    );

    final random = math.Random(seed);
    switch (texture) {
      case SurfaceTexture.wood:
        _wood(canvas, size, random);
      case SurfaceTexture.marble:
        _marble(canvas, size, random);
      case SurfaceTexture.slate:
        _slate(canvas, size, random);
      case SurfaceTexture.frost:
        _frost(canvas, size, random);
      case SurfaceTexture.flat:
        break;
    }

    // The bevel every material shares: light from the top left, a shadow
    // under the bottom edge. It is what makes 64 rectangles read as a
    // surface rather than as a table.
    canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: .05),
              Colors.transparent,
              Colors.black.withValues(alpha: .07),
            ],
            stops: const [0, .45, 1],
          ).createShader(rect));

    if (overlay.a > 0) canvas.drawRect(rect, Paint()..color = overlay);
  }

  /// Long grain with the occasional darker ring.
  void _wood(Canvas canvas, Size size, math.Random random) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .55
      ..color = Colors.black.withValues(alpha: .09);
    final lines = math.max(5, (size.height / 9).round());
    for (var i = 0; i < lines; i++) {
      final y = random.nextDouble() * size.height;
      final wave = 1.2 + random.nextDouble() * 2.4;
      final path = Path()..moveTo(0, y);
      for (double x = 0; x <= size.width; x += 12) {
        path.lineTo(x, y + math.sin(x / 22 + i) * wave);
      }
      canvas.drawPath(path, stroke);
    }
  }

  /// One or two veins, each drawn twice: a soft halo under a hairline, the
  /// way a vein in stone is a seam rather than a pen stroke. They run on a
  /// shallow diagonal and curve, so no vein meets a square's edge squarely.
  void _marble(Canvas canvas, Size size, math.Random random) {
    final tint = isLight ? Colors.black : Colors.white;
    for (var i = 0; i < 1 + random.nextInt(2); i++) {
      final path = Path();
      final y = random.nextDouble() * size.height;
      final drop = (random.nextDouble() - .5) * size.height * .9;
      path.moveTo(-size.width * .15, y);
      path.cubicTo(
        size.width * .25,
        y + drop * .5,
        size.width * .7,
        y + drop * .2,
        size.width * 1.15,
        y + drop,
      );
      canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = 3.2
            ..color = tint.withValues(alpha: isLight ? .045 : .10)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.4));
      canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = .7
            ..color = tint.withValues(alpha: isLight ? .10 : .24));
    }
  }

  /// Cleavage: the long bands a slate splits along, with grit scattered
  /// over them. A handful of faint flecks read as noise; the bands are
  /// what makes the square look split from a larger stone.
  void _slate(Canvas canvas, Size size, math.Random random) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (var i = 0; i < 4; i++) {
      final dark = random.nextBool();
      final y = random.nextDouble() * size.height;
      canvas.drawLine(
          Offset(-size.width * .2, y),
          Offset(size.width * 1.2, y + size.height * .22),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = size.height * (.06 + random.nextDouble() * .12)
            ..color = (dark ? Colors.black : Colors.white)
                .withValues(alpha: dark ? .055 : .045)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.height * .05));
    }
    final grit = Paint();
    for (var i = 0; i < 26; i++) {
      final dark = random.nextBool();
      grit.color = (dark ? Colors.black : Colors.white)
          .withValues(alpha: dark ? .10 : .07);
      canvas.drawCircle(
          Offset(random.nextDouble() * size.width,
              random.nextDouble() * size.height),
          .4 + random.nextDouble() * .7,
          grit);
    }
    canvas.restore();
  }

  /// Frost: crystal needles out of one corner and a cold bloom over them.
  void _frost(Canvas canvas, Size size, math.Random random) {
    canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..shader = RadialGradient(
            center: Alignment(random.nextDouble() * 1.4 - .7,
                random.nextDouble() * 1.4 - .7),
            radius: .9,
            colors: [
              Colors.white.withValues(alpha: .16),
              Colors.white.withValues(alpha: 0),
            ],
          ).createShader(Offset.zero & size));

    // Fern frost grows in from an edge, not out of a star in the middle.
    // Three fronds, feathered and fading as they reach inward.
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    final edge = random.nextInt(4);
    for (var i = 0; i < 3; i++) {
      final along = random.nextDouble();
      final origin = switch (edge) {
        0 => Offset(along * size.width, 0),
        1 => Offset(size.width, along * size.height),
        2 => Offset(along * size.width, size.height),
        _ => Offset(0, along * size.height),
      };
      final inward = switch (edge) {
        0 => math.pi / 2,
        1 => math.pi,
        2 => -math.pi / 2,
        _ => 0.0,
      };
      final angle = inward + (random.nextDouble() - .5) * .9;
      final length = size.width * (.3 + random.nextDouble() * .3);
      final end =
          origin + Offset(math.cos(angle) * length, math.sin(angle) * length);
      canvas.drawLine(
          origin,
          end,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = .7
            ..strokeCap = StrokeCap.round
            ..shader = ui.Gradient.linear(origin, end, [
              Colors.white.withValues(alpha: .42),
              Colors.white.withValues(alpha: 0),
            ]));
      for (var b = 1; b <= 4; b++) {
        final at = Offset.lerp(origin, end, b / 5)!;
        final fade = .34 * (1 - b / 5);
        for (final side in [1, -1]) {
          final barbAngle = angle + side * .85;
          canvas.drawLine(
              at,
              at +
                  Offset(math.cos(barbAngle), math.sin(barbAngle)) *
                      (length * .22 * (1 - b / 6)),
              Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = .55
                ..strokeCap = StrokeCap.round
                ..color = Colors.white.withValues(alpha: fade));
        }
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant BoardSquarePainter old) =>
      texture != old.texture ||
      base != old.base ||
      overlay != old.overlay ||
      seed != old.seed ||
      isLight != old.isLight;
}
