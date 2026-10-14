// Visual QA with a short local game; no backend writes.
import 'package:chess/chess.dart' as c;
import 'package:flutter/material.dart';
import 'package:chess_puzzle_app/screens/profile_screen.dart';
import 'package:chess_puzzle_app/widgets/rok_style.dart';

void main() {
  final board = c.Chess();
  final moves = <Map<String, dynamic>>[];
  for (final san in ['e4', 'e5', 'Nf3', 'Nc6', 'Bc4', 'Bc5']) {
    board.move(san);
    moves.add({'san': san, 'fen_after': board.fen});
  }
  runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: rokTheme(),
      home: GameReviewScreen(
          game: const {}, localMoves: moves, playerColor: c.Color.WHITE)));
}
