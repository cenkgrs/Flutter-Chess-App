// Run on Android/iOS: flutter run -d emulator-5554 -t tools/stockfish_smoke.dart
import 'package:chess/chess.dart';
import 'package:flutter/material.dart';
import 'package:chess_puzzle_app/prototype/stockfish_engine.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(
      home: Scaffold(body: Center(child: Text('Native Stockfish test…')))));
  try {
    final board = Chess();
    for (final elo in [1320, 3190]) {
      final result = await DeviceEngine.instance.evaluate(board.fen, elo: elo);
      final move = result.move!;
      if (!board.move({
        'from': move.substring(0, 2),
        'to': move.substring(2, 4),
        if (move.length > 4) 'promotion': move[4]
      })) {
        throw StateError('Illegal engine move: $move');
      }
    }
    final result = await DeviceEngine.instance.evaluate(board.fen);
    if (result.cp == null && result.mate == null) {
      throw StateError('No evaluation');
    }
    debugPrint('ROK_STOCKFISH_SMOKE_PASS');
    runApp(const MaterialApp(
        home: Scaffold(
            body: Center(
                child: Text('Stockfish PASS: legal moves + evaluation')))));
  } catch (e) {
    debugPrint('ROK_STOCKFISH_SMOKE_FAIL: $e');
    runApp(MaterialApp(home: Scaffold(body: Center(child: Text('FAIL: $e')))));
  }
}
