import 'dart:math';
import 'package:chess/chess.dart';
import 'package:chess_puzzle_app/prototype/engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Starting moves and illegal move rejection', () {
    final game = Chess();
    expect(game.generate_moves().length, 20);
    expect(game.move({'from': 'e2', 'to': 'e5'}), false);
    expect(game.move('e4'), true);
    expect(game.turn, Color.BLACK);
  });
  test('Castling moves both pieces and undo restores position', () {
    final game = Chess.fromFEN('r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1');
    final before = game.fen;
    expect(game.move('O-O'), true);
    expect(game.get('g1')?.type, PieceType.KING);
    expect(game.get('f1')?.type, PieceType.ROOK);
    game.undo();
    expect(game.fen, before);
  });
  test('En passant removes captured pawn', () {
    final game = Chess();
    for (final move in ['e4', 'a6', 'e5', 'd5', 'exd6']) {
      expect(game.move(move), true);
    }
    expect(game.get('d5'), null);
    expect(game.get('d6')?.color, Color.WHITE);
  });
  test('All four promotions available', () {
    final game = Chess.fromFEN('7k/P7/8/8/8/8/8/7K w - - 0 1');
    expect(
        game
            .generate_moves({'square': 'a7'})
            .map((m) => m.promotion?.name)
            .toSet(),
        {'q', 'r', 'b', 'n'});
    expect(game.move({'from': 'a7', 'to': 'a8', 'promotion': 'n'}), true);
    expect(game.get('a8')?.type, PieceType.KNIGHT);
  });
  test('Checkmate, stalemate and repetition stop games', () {
    final game = Chess();
    for (final m in ['f3', 'e5', 'g4', 'Qh4#']) {
      game.move(m);
    }
    expect(game.in_checkmate, true);
    expect(Chess.fromFEN('7k/5Q2/6K1/8/8/8/8/8 b - - 0 1').in_stalemate, true);
    final repetition = Chess();
    for (final m in ['Nf3', 'Nf6', 'Ng1', 'Ng8', 'Nf3', 'Nf6', 'Ng1', 'Ng8']) {
      repetition.move(m);
    }
    expect(repetition.in_threefold_repetition, true);
  });
  for (final level in Difficulty.values) {
    test('${level.name} returns legal move without changing game', () async {
      final game = Chess()..move('e4');
      final before = game.fen;
      final move = await ChessEngine(random: Random(42)).choose(game, level);
      expect(game.fen, before);
      expect(game.history.length, 1);
      expect(
          game.generate_moves().any((m) =>
              m.from == move?.from &&
              m.to == move?.to &&
              m.promotion == move?.promotion),
          true);
    });
  }
  test('Advanced engine finds immediate mate', () async {
    final game = Chess();
    for (final m in ['f3', 'e5', 'g4']) {
      game.move(m);
    }
    final move =
        await ChessEngine(random: Random(4)).choose(game, Difficulty.hard);
    expect(move, isNotNull);
    game.move(move!);
    expect(game.in_checkmate, true);
  });
}
