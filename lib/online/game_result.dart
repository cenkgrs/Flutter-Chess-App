enum PlayerGameOutcome { win, loss, draw, active, aborted }

PlayerGameOutcome gameOutcomeFor(
  Map<String, dynamic> game,
  String userId,
) {
  final status = game['status'] as String?;
  if (status == 'active') return PlayerGameOutcome.active;
  if (status == 'draw') return PlayerGameOutcome.draw;
  if (status == 'aborted') return PlayerGameOutcome.aborted;

  final isWhite = game['white_id'] == userId;
  final won =
      (status == 'white_won' && isWhite) || (status == 'black_won' && !isWhite);
  return won ? PlayerGameOutcome.win : PlayerGameOutcome.loss;
}

String outcomeLabel(PlayerGameOutcome outcome) => switch (outcome) {
      PlayerGameOutcome.win => 'Kazandın',
      PlayerGameOutcome.loss => 'Kaybettin',
      PlayerGameOutcome.draw => 'Berabere',
      PlayerGameOutcome.active => 'Devam ediyor',
      PlayerGameOutcome.aborted => 'İptal edildi',
    };

String resultReasonLabel(Object? reason) => switch (reason) {
      'checkmate' => 'Şah mat',
      'timeout' => 'Süre doldu',
      'resignation' => 'Teslim',
      'draw' => 'Beraberlik',
      'stalemate' => 'Pat',
      'insufficient_material' => 'Yetersiz materyal',
      _ => '',
    };
