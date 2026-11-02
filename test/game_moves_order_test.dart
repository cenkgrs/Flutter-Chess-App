import 'package:chess_puzzle_app/backend/game_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Moves come back in the order they were played', () {
    final rows = [
      {'ply': 3, 'san': 'Nf3'},
      {'ply': 1, 'san': 'e4'},
      {'ply': 2, 'san': 'e5'},
    ];
    expect(movesInPlayOrder(rows).map((row) => row['ply']), [1, 2, 3]);
  });

  test('Rows without a ply keep a defined place instead of throwing', () {
    final rows = [
      {'ply': 2, 'san': 'e5'},
      <String, dynamic>{'san': 'e4'},
    ];
    expect(() => movesInPlayOrder(rows), returnsNormally);
  });
}
