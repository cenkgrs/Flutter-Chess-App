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
      case SurfaceTexture.basalt:
        _basalt(canvas, size, random);
      case SurfaceTexture.ember:
        _ember(canvas, size, random);
      case SurfaceTexture.deco:
        _deco(canvas, size, random);
      case SurfaceTexture.paper:
        _paper(canvas, size, random);
      case SurfaceTexture.metal:
        _metal(canvas, size, random);
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

  /// Volcanic rock: gas pockets of a few sizes, each a dark pit with a lit
  /// upper rim, since the light on this board comes from the top left.
  void _basalt(Canvas canvas, Size size, math.Random random) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (var i = 0; i < 22; i++) {
      final at = Offset(random.nextDouble() * size.width,
          random.nextDouble() * size.height);
      final r = size.width * (.012 + random.nextDouble() * .035);
      canvas.drawCircle(
          at, r, Paint()..color = Colors.black.withValues(alpha: .22));
      canvas.drawCircle(
          at.translate(-r * .3, -r * .3),
          r * .55,
          Paint()..color = Colors.white.withValues(alpha: .07));
    }
    canvas.restore();
  }

  /// Cooled crust split by heat: cracks that fork, each with the glow of
  /// what is still burning under it.
  void _ember(Canvas canvas, Size size, math.Random random) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.4
      ..color = const Color(0xffff7a1e).withValues(alpha: isLight ? .24 : .32)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    final core = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = .9
      ..color = const Color(0xffffd089).withValues(alpha: .75);

    Path crack(Offset from, double angle, double length, int steps) {
      final path = Path()..moveTo(from.dx, from.dy);
      var at = from, heading = angle;
      for (var i = 0; i < steps; i++) {
        heading += (random.nextDouble() - .5) * .9;
        at += Offset(math.cos(heading), math.sin(heading)) * (length / steps);
        path.lineTo(at.dx, at.dy);
      }
      return path;
    }

    // Two squares in five crack; a crack on every one of them reads as a
    // pattern rather than as a break in the crust.
    if (random.nextDouble() > .4) {
      canvas.restore();
      return;
    }
    final start = Offset(random.nextDouble() * size.width, -size.height * .1);
    final main = crack(start, math.pi / 2 + (random.nextDouble() - .5) * .8,
        size.height * 1.3, 7);
    for (final paint in [glow, core]) {
      canvas.drawPath(main, paint);
    }
    if (random.nextBool()) {
      canvas.restore();
      return;
    }
    // One branch, so the crack belongs to a bigger break in the crust.
    final branchAt = Offset(start.dx + (random.nextDouble() - .5) * size.width * .3,
        size.height * (.3 + random.nextDouble() * .4));
    final branch = crack(branchAt,
        random.nextBool() ? .3 : math.pi - .3, size.width * .7, 4);
    for (final paint in [glow, core]) {
      canvas.drawPath(branch, paint);
    }
    canvas.restore();
  }

  /// The inlaid line the period put on everything: a border set in from the
  /// edge, with a stepped corner at one end of the square.
  void _deco(Canvas canvas, Size size, math.Random random) {
    final gold = const Color(0xffc9a24a)
        .withValues(alpha: isLight ? .55 : .70);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .9
      ..color = gold;
    final inset = size.width * .12;
    canvas.drawRect(
        Rect.fromLTWH(inset, inset, size.width - inset * 2,
            size.height - inset * 2),
        line);
    final step = size.width * .055;
    canvas.drawRect(
        Rect.fromLTWH(inset + step, inset + step,
            size.width - (inset + step) * 2, size.height - (inset + step) * 2),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = .5
          ..color = gold.withValues(alpha: gold.a * .55));
    // The corner bracket the period set inside the frame, in one of the
    // four corners so the board is not eight identical rows.
    final corner = random.nextInt(4);
    final cx = corner % 2 == 0 ? inset + step * 2 : size.width - inset - step * 2;
    final cy = corner ~/ 2 == 0 ? inset + step * 2 : size.height - inset - step * 2;
    final dx = corner % 2 == 0 ? size.width * .16 : -size.width * .16;
    final dy = corner ~/ 2 == 0 ? size.height * .16 : -size.height * .16;
    canvas.drawPath(
        Path()
          ..moveTo(cx + dx, cy)
          ..lineTo(cx, cy)
          ..lineTo(cx, cy + dy),
        line);
  }

  /// Paper: fibre, and the faint tooth of a sheet held to the light.
  void _paper(Canvas canvas, Size size, math.Random random) {
    final fibre = Paint()..style = PaintingStyle.stroke..strokeWidth = .5;
    for (var i = 0; i < 46; i++) {
      final dark = random.nextBool();
      fibre.color = (dark ? Colors.black : Colors.white)
          .withValues(alpha: dark ? .07 : .11);
      final at = Offset(random.nextDouble() * size.width,
          random.nextDouble() * size.height);
      final a = random.nextDouble() * math.pi;
      final l = size.width * (.03 + random.nextDouble() * .07);
      canvas.drawLine(
          at, at + Offset(math.cos(a), math.sin(a)) * l, fibre);
    }
  }

  /// Brushed plate: the fine parallel scoring a wire brush leaves, and the
  /// band of light that travels across it.
  void _metal(Canvas canvas, Size size, math.Random random) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    final brush = Paint()..strokeWidth = .6;
    for (var y = 0.0; y < size.height; y += 1.6) {
      final dark = random.nextBool();
      brush.color = (dark ? Colors.black : Colors.white)
          .withValues(alpha: (dark ? .05 : .055) * random.nextDouble());
      canvas.drawLine(Offset(0, y), Offset(size.width, y), brush);
    }
    canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset.zero,
            Offset(size.width, size.height),
            [
              Colors.white.withValues(alpha: 0),
              Colors.white.withValues(alpha: .07),
              Colors.white.withValues(alpha: 0),
            ],
            [0, .5, 1],
          ));
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
