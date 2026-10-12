import 'package:chess_puzzle_app/online/game_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const whiteId = 'white-player';
  const blackId = 'black-player';

  Map<String, dynamic> game(String status) => {
        'status': status,
        'white_id': whiteId,
        'black_id': blackId,
      };

  test('winner status is interpreted from the current player perspective', () {
    expect(gameOutcomeFor(game('white_won'), whiteId), PlayerGameOutcome.win);
    expect(gameOutcomeFor(game('white_won'), blackId), PlayerGameOutcome.loss);
    expect(gameOutcomeFor(game('black_won'), blackId), PlayerGameOutcome.win);
    expect(gameOutcomeFor(game('black_won'), whiteId), PlayerGameOutcome.loss);
  });

  test('draw and result reasons have user-facing Turkish labels', () {
    expect(gameOutcomeFor(game('draw'), whiteId), PlayerGameOutcome.draw);
    expect(outcomeLabel(PlayerGameOutcome.draw), 'Berabere');
    expect(resultReasonLabel('checkmate'), 'Şah mat');
    expect(resultReasonLabel('timeout'), 'Süre doldu');
    expect(resultReasonLabel('resignation'), 'Teslim');
  });
}
