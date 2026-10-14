import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../l10n/app_language.dart';

class BoardDrawingController extends ChangeNotifier {
  bool drawing = false;
  final List<(int, int)> marks = [];
  void toggle() {
    drawing = !drawing;
    notifyListeners();
  }

  void clear() {
    marks.clear();
    notifyListeners();
  }

  void toggleMark((int, int) mark) {
    if (!marks.remove(mark)) marks.add(mark);
    notifyListeners();
  }
}

class BoardDrawingTools extends StatelessWidget {
  const BoardDrawingTools({super.key, required this.controller});
  final BoardDrawingController controller;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: controller,
        builder: (_, __) => Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(
              tooltip: tr(context, 'Çizim modu'),
              onPressed: controller.toggle,
              icon: Icon(
                  controller.drawing ? Icons.touch_app : Icons.draw_outlined,
                  color: controller.drawing ? Colors.amber : Colors.white)),
          if (controller.marks.isNotEmpty)
            IconButton(
                tooltip: tr(context, 'Çizimleri temizle'),
                onPressed: controller.clear,
                icon: const Icon(Icons.layers_clear, color: Colors.white)),
        ]),
      );
}

/// Drawing is explicit on touch; right mouse drag works without changing modes.
class BoardAnnotations extends StatefulWidget {
  const BoardAnnotations(
      {super.key,
      required this.child,
      required this.flipped,
      required this.controller});
  final BoardDrawingController controller;
  final Widget child;
  final bool flipped;
  @override
  State<BoardAnnotations> createState() => _BoardAnnotationsState();
}

class _BoardAnnotationsState extends State<BoardAnnotations> {
  bool get drawing => widget.controller.drawing;
  int? start, end;
  List<(int, int)> get marks => widget.controller.marks;
  int square(Offset point, Size size) {
    final x = ((point.dx - 12) / ((size.width - 24) / 8)).floor().clamp(0, 7);
    final y = ((point.dy - 12) / ((size.height - 24) / 8)).floor().clamp(0, 7);
    final index = y * 8 + x;
    return widget.flipped ? 63 - index : index;
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: widget.controller,
      builder: (_, __) => LayoutBuilder(
          builder: (_, box) => Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (e) {
                  if (!drawing && e.buttons != 2) return;
                  setState(() {
                    start = square(e.localPosition, box.biggest);
                    end = start;
                  });
                },
                onPointerMove: (e) {
                  if (start != null) {
                    setState(() => end = square(e.localPosition, box.biggest));
                  }
                },
                onPointerCancel: (_) => setState(() {
                  start = null;
                  end = null;
                }),
                onPointerUp: (_) {
                  if (start == null || end == null) return;
                  setState(() {
                    final mark = (start!, end!);
                    widget.controller.toggleMark(mark);
                    start = null;
                    end = null;
                  });
                },
                child: Stack(fit: StackFit.expand, children: [
                  AbsorbPointer(absorbing: drawing, child: widget.child),
                  IgnorePointer(
                      child: CustomPaint(
                          painter: _Marks([
                    ...marks,
                    if (start != null && end != null) (start!, end!)
                  ], widget.flipped))),
                ]),
              )));
}

class _Marks extends CustomPainter {
  _Marks(this.marks, this.flipped);
  final List<(int, int)> marks;
  final bool flipped;
  @override
  void paint(Canvas canvas, Size size) {
    final cell = (size.width - 24) / 8;
    Offset center(int raw) {
      final i = flipped ? 63 - raw : raw;
      return Offset(12 + (i % 8 + .5) * cell, 12 + (i ~/ 8 + .5) * cell);
    }

    final paint = Paint()
      ..color = const Color(0xcc8bd3a0)
      ..strokeWidth = cell * .10
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final mark in marks) {
      final a = center(mark.$1), b = center(mark.$2);
      if (a == b) {
        canvas.drawCircle(a, cell * .38, paint);
        continue;
      }
      canvas.drawLine(a, b, paint);
      final angle = math.atan2(b.dy - a.dy, b.dx - a.dx);
      for (final offset in [-.6, .6]) {
        canvas.drawLine(
            b,
            b -
                Offset(math.cos(angle + offset), math.sin(angle + offset)) *
                    cell *
                    .32,
            paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _Marks old) => true;
}
