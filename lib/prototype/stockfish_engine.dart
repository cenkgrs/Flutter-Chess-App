import 'dart:async';
import 'package:stockfish/stockfish.dart';

class EngineEvaluation {
  const EngineEvaluation(this.move, this.cp, this.mate);
  final String? move;
  final int? cp, mate;
  int get score => mate == null ? cp ?? 0 : (mate! > 0 ? 100000 : -100000);
}

/// One native instance and one UCI search at a time, shared by play and review.
class DeviceEngine {
  static final instance = DeviceEngine();
  Stockfish? _engine;
  Future<void> _queue = Future.value();
  int minElo = 1320, maxElo = 3190;

  Future<void> _ready() async {
    if (_engine?.state.value == StockfishState.ready) return;
    final engine = _engine ??= Stockfish();
    final ready = Completer<void>();
    void changed() {
      if (engine.state.value == StockfishState.ready && !ready.isCompleted) {
        ready.complete();
      } else if (engine.state.value == StockfishState.error &&
          !ready.isCompleted) {
        ready.completeError(StateError('Motor başlatılamadı'));
      }
    }

    engine.state.addListener(changed);
    changed();
    try {
      await ready.future.timeout(const Duration(seconds: 20));
    } finally {
      engine.state.removeListener(changed);
    }
    final handshake = Completer<void>();
    final sub = engine.stdout.listen((line) {
      final range = RegExp(r'option name UCI_Elo .* min (\d+) max (\d+)')
          .firstMatch(line);
      if (range != null) {
        minElo = int.parse(range[1]!);
        maxElo = int.parse(range[2]!);
      }
      if (line == 'uciok' && !handshake.isCompleted) handshake.complete();
    });
    try {
      engine.stdin = 'uci';
      await handshake.future.timeout(const Duration(seconds: 10));
      engine.stdin = 'setoption name Threads value 1';
      engine.stdin = 'setoption name Hash value 32';
    } finally {
      await sub.cancel();
    }
  }

  Future<EngineEvaluation> evaluate(String fen,
      {int? elo, int milliseconds = 650}) {
    final result = Completer<EngineEvaluation>();
    _queue = _queue.then((_) async {
      try {
        await _ready();
        final engine = _engine!;
        final done = Completer<EngineEvaluation>();
        int? cp, mate;
        final sub = engine.stdout.listen((line) {
          final score = RegExp(r' score (cp|mate) (-?\d+)').firstMatch(line);
          if (score != null && !line.contains('bound')) {
            cp = score[1] == 'cp' ? int.parse(score[2]!) : null;
            mate = score[1] == 'mate' ? int.parse(score[2]!) : null;
          }
          if (line.startsWith('bestmove ') && !done.isCompleted) {
            final move = line.split(' ')[1];
            done.complete(EngineEvaluation(
                move == '(none)' || move == '0000' ? null : move, cp, mate));
          }
        }, onError: (Object e) {
          if (!done.isCompleted) done.completeError(e);
        }, onDone: () {
          if (!done.isCompleted) {
            done.completeError(StateError('Motor kapandı'));
          }
        });
        try {
          engine.stdin =
              'setoption name UCI_LimitStrength value ${elo != null}';
          if (elo != null) {
            engine.stdin =
                'setoption name UCI_Elo value ${elo.clamp(minElo, maxElo)}';
          }
          engine.stdin = 'position fen $fen';
          engine.stdin = 'go movetime $milliseconds';
          try {
            result.complete(
                await done.future.timeout(const Duration(seconds: 15)));
          } on TimeoutException {
            engine.stdin = 'stop';
            // Drain bestmove before another queued search can start.
            await done.future.timeout(const Duration(seconds: 5));
            throw TimeoutException('Motor yanıt vermedi');
          }
        } finally {
          await sub.cancel();
        }
      } catch (e, st) {
        if (!result.isCompleted) result.completeError(e, st);
      }
    });
    return result.future;
  }
}

String moveQuality(int loss, {required bool best}) {
  if (best) return 'En iyi';
  if (loss <= 30) return 'İyi';
  if (loss <= 100) return 'İsabetsizlik';
  if (loss <= 250) return 'Hata';
  return 'Büyük hata';
}
