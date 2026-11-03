import 'package:chess/chess.dart' as c;
import 'package:flutter/material.dart';

import '../theme/board_theme.dart';

/// Whose move it is, as the king of that colour.
///
/// The puzzle screens said it in a line of text under the board, where it
/// was the easiest thing on the screen to miss — and getting it wrong costs
/// the attempt. A piece in the player's own set reads at a glance.
class TurnKing extends StatelessWidget {
  const TurnKing(this.turn, {super.key, this.size = 44});

  final c.Color turn;
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
        label: turn == c.Color.WHITE ? 'Beyaz oynar' : 'Siyah oynar',
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            // The piece stands on a square of the player's own board, so the
            // indicator belongs to the board rather than floating above it.
            color: turn == c.Color.WHITE ? boardSkin.light : boardSkin.dark,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xffb9874f), width: 1.2),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 6,
                  offset: Offset(0, 3)),
            ],
          ),
          padding: const EdgeInsets.all(2),
          child: BoardPiece(
            c.Piece(c.PieceType.KING, turn),
            padding: 0,
            scale: 1,
          ),
        ),
      );
}
