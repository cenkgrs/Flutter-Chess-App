import 'package:chess_puzzle_app/online/game_sync.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> gameRow({
  int ply = 0,
  String status = 'active',
  String updatedAt = '2026-10-15T10:00:00Z',
  int whiteMs = 60000,
  int blackMs = 60000,
  String? serverNow,
  String? receivedAt,
}) =>
    {
      'ply': ply,
      'status': status,
      'updated_at': updatedAt,
      'white_ms': whiteMs,
      'black_ms': blackMs,
      if (serverNow != null) '_server_now': serverNow,
      if (receivedAt != null) '_received_at': receivedAt,
    };

void main() {
  test('stale realtime snapshots cannot roll a resumed game backwards', () {
    final current = gameRow(ply: 8, updatedAt: '2026-10-15T10:00:08Z');
    expect(shouldApplyGameSnapshot(current, gameRow(ply: 7)), isFalse);
    expect(shouldApplyGameSnapshot(current, gameRow(ply: 9)), isTrue);
  });

  test('a completed result cannot be replaced by an active snapshot', () {
    final finished = gameRow(ply: 8, status: 'white_won');
    expect(shouldApplyGameSnapshot(finished, gameRow(ply: 8)), isFalse);
  });

  test('equal realtime row keeps the authoritative server clock anchor', () {
    final refreshed = gameRow(
      ply: 8,
      serverNow: '2026-10-15T10:00:09Z',
      receivedAt: '2026-10-15T13:00:00Z',
    );
    final realtime = gameRow(
      ply: 8,
      receivedAt: '2026-10-15T13:00:00Z',
    );
    expect(shouldApplyGameSnapshot(refreshed, realtime), isFalse);
    expect(shouldApplyGameSnapshot(realtime, refreshed), isTrue);
  });

  test('clock uses server time and keeps ticking from receipt time', () {
    final row = gameRow(
      ply: 0,
      whiteMs: 60000,
      serverNow: '2026-10-15T10:00:05Z',
      receivedAt: '2026-10-15T13:00:00Z', // device is three hours fast
    );
    final clocks = gameClocks(
      row,
      now: DateTime.parse('2026-10-15T13:00:02Z'),
    );
    expect(clocks.white, 53000);
    expect(clocks.black, 60000);
  });

  test('only the side to move loses time', () {
    final clocks = gameClocks(
      gameRow(
        ply: 3,
        serverNow: '2026-10-15T10:00:04Z',
        receivedAt: '2026-10-15T10:00:04Z',
      ),
      now: DateTime.parse('2026-10-15T10:00:04Z'),
    );
    expect(clocks.white, 60000);
    expect(clocks.black, 56000);
  });
}
