import 'dart:math' as math;

/// Returns whether [next] is at least as recent as [current].
///
/// Realtime can deliver a cached row after an explicit resume refresh. Never
/// let that row roll the board, result, or clocks backwards.
bool shouldApplyGameSnapshot(
  Map<String, dynamic>? current,
  Map<String, dynamic> next,
) {
  if (current == null) return true;

  final currentFinished = current['status'] != 'active';
  final nextFinished = next['status'] != 'active';
  if (currentFinished && !nextFinished) return false;

  final currentPly = (current['ply'] as num?)?.toInt() ?? 0;
  final nextPly = (next['ply'] as num?)?.toInt() ?? 0;
  if (nextPly != currentPly) return nextPly > currentPly;

  final currentUpdated = DateTime.tryParse('${current['updated_at']}');
  final nextUpdated = DateTime.tryParse('${next['updated_at']}');
  if (currentUpdated == null || nextUpdated == null) return true;
  if (nextUpdated.isAtSameMomentAs(currentUpdated) &&
      current['_server_now'] != null &&
      next['_server_now'] == null) {
    return false;
  }
  return !nextUpdated.isBefore(currentUpdated);
}

({int white, int black}) gameClocks(
  Map<String, dynamic> row, {
  DateTime? now,
}) {
  var white = (row['white_ms'] as num).toInt();
  var black = (row['black_ms'] as num).toInt();
  if (row['status'] != 'active') return (white: white, black: black);

  final updatedAt = DateTime.parse(row['updated_at'] as String).toUtc();
  final receivedAt = DateTime.tryParse('${row['_received_at']}')?.toUtc();
  final serverAtReceipt =
      DateTime.tryParse('${row['_server_now']}')?.toUtc() ?? receivedAt;
  final localNow = (now ?? DateTime.now()).toUtc();

  // A refresh includes the database clock. This avoids device clock skew while
  // still letting the display tick locally after the response was received.
  final elapsedAtReceipt = serverAtReceipt == null
      ? localNow.difference(updatedAt).inMilliseconds
      : serverAtReceipt.difference(updatedAt).inMilliseconds;
  final elapsedSinceReceipt = receivedAt == null
      ? 0
      : math.max(0, localNow.difference(receivedAt).inMilliseconds);
  final elapsed = math.max(0, elapsedAtReceipt + elapsedSinceReceipt);

  final whiteToMove = (row['ply'] as num).toInt().isEven;
  if (whiteToMove) {
    white = math.max(0, white - elapsed);
  } else {
    black = math.max(0, black - elapsed);
  }
  return (white: white, black: black);
}
