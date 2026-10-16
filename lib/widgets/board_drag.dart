import 'package:flutter/material.dart';

/// Drag-and-drop input for an 8×8 board drawn by [builder]. While a piece
/// is held, [builder] receives its square so the grid can leave it empty,
/// and the piece follows the finger. Taps still reach the grid's own
/// gesture detectors.
class BoardDragInput extends StatefulWidget {
  const BoardDragInput({
    super.key,
    required this.flipped,
    required this.canDrag,
    required this.onDrop,
    required this.pieceBuilder,
    required this.builder,
    this.onPress,
  });

  final bool flipped;
  final bool Function(String square) canDrag;
  final void Function(String from, String to) onDrop;
  final Widget Function(String square) pieceBuilder;
  final Widget Function(BuildContext context, String? dragging) builder;

  /// Called on every touch on the board, before any drag starts.
  final VoidCallback? onPress;

  @override
  State<BoardDragInput> createState() => _BoardDragInputState();
}

class _BoardDragInputState extends State<BoardDragInput> {
  String? _from;
  final _position = ValueNotifier<Offset?>(null);

  @override
  void dispose() {
    _position.dispose();
    super.dispose();
  }

  String _squareAt(Offset position, Size size) {
    final column = (position.dx / (size.width / 8)).floor().clamp(0, 7);
    final row = (position.dy / (size.height / 8)).floor().clamp(0, 7);
    final index = widget.flipped ? 63 - (row * 8 + column) : row * 8 + column;
    return '${'abcdefgh'[index % 8]}${8 - index ~/ 8}';
  }

  void _release() {
    _position.value = null;
    if (_from != null) setState(() => _from = null);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final size = Size(box.maxWidth, box.maxHeight);
        return Listener(
          onPointerDown: (event) {
            widget.onPress?.call();
            if (event.buttons != 1) return;
            final square = _squareAt(event.localPosition, size);
            if (!widget.canDrag(square)) return;
            setState(() => _from = square);
            _position.value = event.localPosition;
          },
          onPointerMove: (event) {
            if (_from != null) _position.value = event.localPosition;
          },
          onPointerCancel: (_) => _release(),
          onPointerUp: (event) {
            final from = _from;
            _release();
            final position = event.localPosition;
            if (from == null ||
                position.dx < 0 ||
                position.dy < 0 ||
                position.dx >= size.width ||
                position.dy >= size.height) {
              return;
            }
            final to = _squareAt(position, size);
            if (from != to) widget.onDrop(from, to);
          },
          // Claims drags on the board so a scrolling page around it does not
          // move while a piece is carried.
          child: GestureDetector(
            onPanStart: (_) {},
            child: Stack(children: [
              widget.builder(context, _from),
              ValueListenableBuilder<Offset?>(
                valueListenable: _position,
                builder: (context, position, _) {
                  final from = _from;
                  if (from == null || position == null) {
                    return const SizedBox.shrink();
                  }
                  return Positioned(
                    left: position.dx - size.width / 16,
                    top: position.dy - size.height / 16,
                    width: size.width / 8,
                    height: size.height / 8,
                    child: IgnorePointer(child: widget.pieceBuilder(from)),
                  );
                },
              ),
            ]),
          ),
        );
      });
}

/// Tint laid over the two squares of the most recent move.
const lastMoveTint = Color(0x667a743e);

/// Marks a square the selected piece can move to: a dot on an empty square,
/// a ring around a piece that can be captured.
class LegalMoveMarker extends StatelessWidget {
  const LegalMoveMarker({super.key, required this.capture});

  final bool capture;

  @override
  Widget build(BuildContext context) => Container(
        width: capture ? null : 12,
        height: capture ? null : 12,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: capture ? null : const Color(0x88412a18),
          border: capture
              ? Border.all(color: const Color(0xaae2b75f), width: 3)
              : null,
        ),
      );
}
