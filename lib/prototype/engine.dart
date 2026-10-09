import 'dart:math';
import 'package:chess/chess.dart';

enum Difficulty { easy, medium, hard }

extension DifficultyLabel on Difficulty {
  String get label => ['Başlangıç', 'Orta', 'İleri'][index];
}

/// Bounded local alpha-beta search; levels are not calibrated Elo ratings.
class ChessEngine {
  final Random random;
  ChessEngine({Random? random}) : random = random ?? Random();
  int _nodes = 0;
  static const values = {
    'p': 100,
    'n': 320,
    'b': 330,
    'r': 500,
    'q': 900,
    'k': 0
  };

  Future<Move?> choose(Chess position, Difficulty difficulty) async {
    final game = position.copy();
    final moves = game.generate_moves()..shuffle(random);
    if (moves.isEmpty || game.game_over) return null;
    if (difficulty == Difficulty.easy) {
      return moves[random.nextInt(moves.length)];
    }
    _nodes = 0;
    moves.sort((a, b) => _priority(b).compareTo(_priority(a)));
    var best = moves.first;
    var bestScore = -1000000;
    final depth = difficulty == Difficulty.hard ? 3 : 2;
    for (final move in moves) {
      await Future<void>.delayed(Duration.zero);
      game.make_move(move);
      final score = -_search(game, depth - 1, -1000000, -bestScore, 1);
      game.undo_move();
      if (score > bestScore) {
        bestScore = score;
        best = move;
      }
    }
    return best;
  }

  Future<ChessAdvice?> explain(Chess position) async {
    final move = await choose(position, Difficulty.hard);
    if (move == null) return null;
    final before = position.get(move.toAlgebraic);
    final copy = position.copy()..move(move);
    final san = copy.getHistory().cast<String>().last;
    final reasons = <String>[];
    if (before != null) {
      reasons.add('rakibin ${before.type.name} taşını kazanıyor');
    }
    if (copy.in_check) reasons.add('şah çekerek rakibi cevap vermeye zorluyor');
    if ('d4e4d5e5'.contains(move.toAlgebraic)) {
      reasons.add('merkez kontrolünü güçlendiriyor');
    }
    if (move.promotion != null) {
      reasons.add('piyonu güçlü bir taşa dönüştürüyor');
    }
    final mainReason = reasons.isEmpty
        ? 'taşlarının etkinliğini artırıp konumunu daha dengeli hale getiriyor'
        : reasons.join(' ve ');
    return ChessAdvice(
      san,
      '${move.fromAlgebraic} karesindeki taşı ${move.toAlgebraic} karesine götürmeni öneriyorum.',
      '$san hamlesi $mainReason. Bu hamleden sonra rakibin tehdidini kontrol edip taşlarını güvenli karelerde tut.',
    );
  }

  int _priority(Move m) =>
      (values[m.captured?.name] ?? 0) * 10 + (values[m.promotion?.name] ?? 0);

  int _search(Chess game, int depth, int alpha, int beta, int ply) {
    _nodes++;
    final moves = game.generate_moves();
    if (moves.isEmpty) return game.in_check ? -100000 + ply : 0;
    if (game.in_draw) return 0;
    if (depth == 0 || _nodes > 10000) return _evaluate(game);
    moves.sort((a, b) => _priority(b).compareTo(_priority(a)));
    for (final move in moves) {
      game.make_move(move);
      final score = -_search(game, depth - 1, -beta, -alpha, ply + 1);
      game.undo_move();
      if (score >= beta) return beta;
      alpha = max(alpha, score);
    }
    return alpha;
  }

  int _evaluate(Chess game) {
    var score = 0;
    for (var rank = 0; rank < 8; rank++) {
      for (var file = 0; file < 8; file++) {
        final piece = game.get('${'abcdefgh'[file]}${rank + 1}');
        if (piece == null) continue;
        final centrality =
            (7 - ((file - 3.5).abs() + (rank - 3.5).abs())).round();
        final advance = piece.color == Color.WHITE ? rank : 7 - rank;
        final bonus = piece.type == PieceType.PAWN
            ? advance * 8
            : piece.type == PieceType.KING
                ? 0
                : centrality * 6;
        score += ((values[piece.type.name] ?? 0) + bonus) *
            (piece.color == Color.WHITE ? 1 : -1);
      }
    }
    return game.turn == Color.WHITE ? score : -score;
  }
}

class ChessAdvice {
  const ChessAdvice(this.move, this.firstSentence, this.secondSentence);
  final String move;
  final String firstSentence;
  final String secondSentence;
}
