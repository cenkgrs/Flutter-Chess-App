import 'package:chess/chess.dart' as c;

class Premove {
  const Premove(this.from, this.to);
  final String from, to;
  c.Move? resolve(c.Chess game) {
    for (final move in game.generate_moves()) {
      if (move.fromAlgebraic == from &&
          move.toAlgebraic == to &&
          (move.promotion == null || move.promotion!.name == 'q')) {
        return move;
      }
    }
    return null;
  }
}
