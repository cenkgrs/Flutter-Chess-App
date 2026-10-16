import '../l10n/app_language.dart';
import '../widgets/rok_style.dart';
import 'profile_screen.dart';
import 'dart:async';
import 'dart:math' as math;

import 'package:chess/chess.dart' as c;
import 'package:flutter/material.dart';

import '../backend/app_backend.dart';
import '../backend/game_repository.dart';
import '../online/game_result.dart';
import '../online/game_sync.dart';
import '../widgets/board_annotations.dart';
import '../prototype/premove.dart';
import '../ads/match_ads.dart';
import '../audio/game_sounds.dart';

class OnlineGameScreen extends StatefulWidget {
  const OnlineGameScreen({super.key, required this.gameId});

  final String gameId;

  @override
  State<OnlineGameScreen> createState() => _OnlineGameScreenState();
}

class _OnlineGameScreenState extends State<OnlineGameScreen>
    with WidgetsBindingObserver {
  final _repository = GameRepository();
  StreamSubscription<Map<String, dynamic>>? _subscription;
  Timer? _clockTimer;
  Timer? _reconnectTimer;
  Map<String, dynamic>? _row;
  c.Chess _game = c.Chess();
  String? _selected;
  String? _dragFrom;
  final ValueNotifier<Offset?> _dragPosition = ValueNotifier(null);
  List<c.Move> _targets = [];
  bool _sending = false;
  Premove? _premove;
  final _drawing = BoardDrawingController();
  void _queuePremove(String square) {
    final mine = _isWhite ? c.Color.WHITE : c.Color.BLACK;
    if (_game.get(square)?.color == mine) {
      setState(() => _selected = square);
    } else if (_selected != null) {
      setState(() {
        _premove = Premove(_selected!, square);
        _selected = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: LText('Ön hamle: ${_premove!.from} → ${_premove!.to}'),
          action: SnackBarAction(
              label: tr(context, 'İptal'),
              onPressed: () => setState(() => _premove = null))));
    }
  }

  String? _error;
  bool _finishSent = false;
  bool _resultShown = false;
  bool _leaving = false;
  bool _refreshing = false;
  int _reconnectAttempt = 0;

  String get _myId => AppBackend.currentUser!.id;
  bool get _isWhite => _row?['white_id'] == _myId;
  bool get _myTurn =>
      _row?['status'] == 'active' &&
      ((_game.turn == c.Color.WHITE) == _isWhite);
  bool get _flipped => !_isWhite;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    MatchAds.instance.preload();
    _connectAndRefresh();
    _clockTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (mounted && _row?['status'] == 'active') _checkTimeout();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _connectAndRefresh();
    }
  }

  Future<void> _connectAndRefresh() async {
    _reconnectTimer?.cancel();
    await _subscription?.cancel();
    if (!mounted) return;
    _subscription = _repository.watchGame(widget.gameId).listen(
      (row) {
        _reconnectAttempt = 0;
        _applySnapshot(row);
      },
      onError: (_) => _connectionLost(),
      onDone: _connectionLost,
    );
    await _refreshGame();
  }

  Future<void> _refreshGame() async {
    if (_refreshing) return;
    _refreshing = true;
    try {
      final row = await _repository.fetchGame(widget.gameId);
      if (mounted) {
        _reconnectAttempt = 0;
        _applySnapshot(row);
        _checkTimeout();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = _row == null
            ? 'Oyuna bağlanılamadı. Yeniden deneniyor…'
            : 'Bağlantı kesildi. Oyun yeniden eşitleniyor…');
        _scheduleReconnect();
      }
    } finally {
      _refreshing = false;
    }
  }

  void _connectionLost() {
    if (!mounted) return;
    setState(() => _error = _row == null
        ? 'Oyuna bağlanılamadı. Yeniden deneniyor…'
        : 'Bağlantı kesildi. Oyun yeniden eşitleniyor…');
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_reconnectTimer?.isActive == true || _leaving || !mounted) return;
    final seconds = math.min(30, 1 << math.min(_reconnectAttempt, 5));
    _reconnectAttempt++;
    _reconnectTimer = Timer(Duration(seconds: seconds), _connectAndRefresh);
  }

  void _checkTimeout() {
    if (_finishSent || _row == null) return;
    final clocks = _clocks;
    if (clocks.white <= 0) {
      _finishByTimeout('black');
    } else if (clocks.black <= 0) {
      _finishByTimeout('white');
    }
  }

  Future<void> _finishByTimeout(String winner) async {
    if (_finishSent) return;
    _finishSent = true;
    try {
      await _repository.finishGame(
        gameId: widget.gameId,
        result: winner,
        reason: 'timeout',
      );
    } catch (_) {
      _finishSent = false;
    }
  }

  void _applySnapshot(Map<String, dynamic> row) {
    if (!mounted) return;
    if (!shouldApplyGameSnapshot(_row, row)) return;
    final previousRow = _row;
    final previousPly = (previousRow?['ply'] as num?)?.toInt();
    try {
      _dragPosition.value = null;
      setState(() {
        _row = row;
        _game = c.Chess.fromFEN(row['fen'] as String);
        _selected = null;
        _dragFrom = null;
        _targets = [];
        _sending = false;
        _error = null;
      });
      final nextPly = (row['ply'] as num?)?.toInt() ?? 0;
      if (previousRow == null) {
        if (row['status'] == 'active' && nextPly == 0) {
          GameSounds.instance.playStart();
        }
      } else if (previousPly != null && nextPly > previousPly) {
        GameSounds.instance.playMove();
      }
      if (row['status'] != 'active' && !_resultShown && !_leaving) {
        _premove = null;
        _resultShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_leaving) _showResult(row);
        });
      }
      if (_myTurn && !_sending && _premove != null) {
        final queued = _premove!;
        _premove = null;
        final move = queued.resolve(_game);
        if (move != null) _send(move);
      }
    } catch (_) {
      setState(() => _error = 'Sunucudan geçersiz oyun konumu geldi.');
    }
  }

  Future<void> _showResult(Map<String, dynamic> row) async {
    final outcome = gameOutcomeFor(row, _myId);
    if (outcome == PlayerGameOutcome.win) GameSounds.instance.playVictory();
    final reason = resultReasonLabel(row['result_reason']);
    final icon = switch (outcome) {
      PlayerGameOutcome.win => Icons.emoji_events_rounded,
      PlayerGameOutcome.loss => Icons.close_rounded,
      PlayerGameOutcome.draw => Icons.balance_rounded,
      _ => Icons.sports_esports_rounded,
    };
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => RokResultDialog(
        icon: Icon(icon, size: 42),
        title: LText(outcomeLabel(outcome)),
        content:
            reason.isEmpty ? null : LText(reason, textAlign: TextAlign.center),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const LText('Tahtaya dön'),
          ),
          TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => GameReviewScreen(game: row)));
              },
              child: const LText('Motor analizi')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await MatchAds.instance.showIfReady(widget.gameId);
              if (mounted) Navigator.maybePop(context);
            },
            child: const LText('Menüye dön'),
          ),
        ],
      ),
    );
  }

  ({int white, int black}) get _clocks {
    final row = _row;
    if (row == null) return (white: 0, black: 0);
    return gameClocks(row);
  }

  Future<void> _tap(String square) async {
    if (_sending || _row == null || _row!['status'] != 'active') return;
    if (!_myTurn) {
      _queuePremove(square);
      return;
    }
    _premove = null;
    final candidates = _targets.where((move) => move.toAlgebraic == square);
    if (candidates.isNotEmpty) {
      var move = candidates.first;
      if (move.promotion != null) {
        final promotion = await showDialog<String>(
          context: context,
          builder: (context) => RokDialog(
            title: const LText('Piyonunu terfi ettir'),
            actions: ['q', 'r', 'b', 'n']
                .map((piece) => TextButton(
                      onPressed: () => Navigator.pop(context, piece),
                      child: LText(const {
                        'q': 'Vezir',
                        'r': 'Kale',
                        'b': 'Fil',
                        'n': 'At',
                      }[piece]!),
                    ))
                .toList(),
          ),
        );
        if (!mounted || promotion == null) return;
        move =
            candidates.firstWhere((item) => item.promotion?.name == promotion);
      }
      await _send(move);
      return;
    }
    setState(() {
      final myColor = _isWhite ? c.Color.WHITE : c.Color.BLACK;
      _selected = _game.get(square)?.color == myColor ? square : null;
      _targets =
          _selected == null ? [] : _game.generate_moves({'square': _selected});
    });
  }

  Future<void> _send(c.Move move) async {
    final row = _row!;
    final gameAfter = c.Chess.fromFEN(_game.fen)..move(move);
    final history = gameAfter.getHistory().cast<String>();
    final san = history.isEmpty ? move.toString() : history.last;
    final clocks = _clocks;
    final increment = (row['increment_seconds'] as int) * 1000;
    final whiteMs = _isWhite ? clocks.white + increment : clocks.white;
    final blackMs = _isWhite ? clocks.black : clocks.black + increment;
    setState(() => _sending = true);
    try {
      final confirmedRow = await _repository.submitMove(
        gameId: widget.gameId,
        expectedPly: row['ply'] as int,
        uci:
            '${move.fromAlgebraic}${move.toAlgebraic}${move.promotion?.name ?? ''}',
        san: san,
        fenAfter: gameAfter.fen,
        whiteMs: whiteMs,
        blackMs: blackMs,
      );
      // The RPC can arrive after a newer realtime snapshot.
      if (mounted &&
          (_row?['status'] == 'active') &&
          (confirmedRow['ply'] as int) > (_row!['ply'] as int)) {
        _applySnapshot(confirmedRow);
      }
      if (gameAfter.game_over) await _finish(gameAfter);
    } catch (_) {
      if (mounted) {
        setState(() {
          _sending = false;
          _error = 'Hamle gönderilemedi; konum yenileniyor.';
        });
        await _refreshGame();
      }
    }
  }

  Future<void> _finish(c.Chess game) async {
    if (_finishSent) return;
    _finishSent = true;
    final result = game.in_checkmate
        ? (game.turn == c.Color.WHITE ? 'black' : 'white')
        : 'draw';
    try {
      await _repository.finishGame(
        gameId: widget.gameId,
        result: result,
        reason: game.in_checkmate ? 'checkmate' : 'draw',
      );
    } catch (_) {
      _finishSent = false;
      rethrow;
    }
  }

  Future<void> _resign({bool exitAfter = false}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => RokDialog(
        title: LText(exitAfter
            ? 'Oyundan çıkmak istiyor musun?'
            : 'Teslim olmak istiyor musun?'),
        content: exitAfter
            ? const LText('Devam eden oyundan çıkmak teslim olmak sayılır.')
            : null,
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const LText('Devam et')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const LText('Teslim ol')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    _leaving = exitAfter;
    try {
      await _repository.finishGame(
        gameId: widget.gameId,
        result: _isWhite ? 'black' : 'white',
        reason: 'resignation',
      );
      if (exitAfter && mounted) Navigator.pop(context);
    } catch (_) {
      _leaving = false;
      if (mounted) setState(() => _error = 'Teslim işlemi gönderilemedi.');
    }
  }

  void _exit() async {
    if (_row?['status'] == 'active') {
      _resign(exitAfter: true);
    } else {
      if (_row != null) await MatchAds.instance.showIfReady(widget.gameId);
      if (mounted) Navigator.maybePop(context);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    _clockTimer?.cancel();
    _reconnectTimer?.cancel();
    _dragPosition.dispose();
    _drawing.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xff3b1e0f),
        body: DecoratedBox(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('lib/images/wood/background.png'),
              fit: BoxFit.cover,
              colorFilter:
                  ColorFilter.mode(Color(0x18000000), BlendMode.darken),
            ),
          ),
          child: SafeArea(
            child: _row == null
                ? Center(
                    child: _error == null
                        ? const CircularProgressIndicator(
                            color: Color(0xfff3eee7))
                        : LText(_error!,
                            style: const TextStyle(color: Color(0xfff3eee7))),
                  )
                : LayoutBuilder(
                    builder: (context, box) {
                      final boardSize =
                          math.min(box.maxWidth, box.maxHeight - 235);
                      final row = _row!;
                      final clocks = _clocks;
                      final clockAnchor = DateTime.now().toUtc();
                      final active = row['status'] == 'active';
                      final topColor = _flipped ? c.Color.WHITE : c.Color.BLACK;
                      final bottomColor =
                          _flipped ? c.Color.BLACK : c.Color.WHITE;
                      return Column(
                        children: [
                          SizedBox(
                            height: 44,
                            child: Row(
                              children: [
                                IconButton(
                                  key: const ValueKey('online-exit'),
                                  onPressed: _exit,
                                  tooltip: tr(context, 'Oyundan çık'),
                                  icon: const Icon(Icons.arrow_back_rounded),
                                  color: const Color(0xfff3eee7),
                                ),
                                const Spacer(),
                                const LText(
                                  'ÇEVRİMİÇİ OYUN',
                                  style: TextStyle(
                                    color: Color(0xfff3eee7),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.4,
                                  ),
                                ),
                                const Spacer(),
                                BoardDrawingTools(controller: _drawing),
                              ],
                            ),
                          ),
                          _PlayerBar(
                            label: _flipped ? 'Beyaz' : 'Siyah',
                            milliseconds:
                                _flipped ? clocks.white : clocks.black,
                            updatedAt: clockAnchor,
                            running: active && _game.turn == topColor,
                            highlighted: active && _game.turn == topColor,
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: boardSize,
                            height: boardSize,
                            child: BoardAnnotations(
                                controller: _drawing,
                                flipped: _flipped,
                                child: _board()),
                          ),
                          const SizedBox(height: 10),
                          _PlayerBar(
                            label: _flipped ? 'Siyah · Sen' : 'Beyaz · Sen',
                            milliseconds:
                                _flipped ? clocks.black : clocks.white,
                            updatedAt: clockAnchor,
                            running: active && _game.turn == bottomColor,
                            highlighted: _myTurn,
                          ),
                          const Spacer(),
                          if (_error != null)
                            LText(_error!,
                                style:
                                    const TextStyle(color: Color(0xffffd8c7))),
                          if (active)
                            TextButton.icon(
                              onPressed: _resign,
                              icon: const Icon(Icons.flag_outlined),
                              label: const LText('Teslim ol'),
                              style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xfff3eee7)),
                            )
                          else
                            _GameResultBar(
                              outcome: gameOutcomeFor(row, _myId),
                              reason: resultReasonLabel(row['result_reason']),
                              onExit: _exit,
                            ),
                          const SizedBox(height: 8),
                        ],
                      );
                    },
                  ),
          ),
        ),
      );

  Widget _board() => DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xff4a2715),
          border: Border.all(color: const Color(0xffb9874f), width: 2),
          boxShadow: const [
            BoxShadow(
                color: Colors.black54, blurRadius: 16, offset: Offset(0, 8))
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: LayoutBuilder(
            builder: (context, boardBox) {
              String squareAt(Offset position) {
                final column =
                    (position.dx / (boardBox.maxWidth / 8)).floor().clamp(0, 7);
                final row = (position.dy / (boardBox.maxHeight / 8))
                    .floor()
                    .clamp(0, 7);
                final displayIndex = row * 8 + column;
                final index = _flipped ? 63 - displayIndex : displayIndex;
                return '${'abcdefgh'[index % 8]}${8 - index ~/ 8}';
              }

              return Listener(
                onPointerDown: (event) {
                  if (event.buttons != 1) return;
                  final square = squareAt(event.localPosition);
                  final mine = _isWhite ? c.Color.WHITE : c.Color.BLACK;
                  if (_row?['status'] == 'active' &&
                      !_sending &&
                      _game.get(square)?.color == mine) {
                    setState(() {
                      _dragFrom = square;
                    });
                    _dragPosition.value = event.localPosition;
                  }
                },
                onPointerMove: (event) {
                  if (_dragFrom != null) {
                    _dragPosition.value = event.localPosition;
                  }
                },
                onPointerCancel: (_) {
                  if (_dragFrom != null) {
                    _dragPosition.value = null;
                    setState(() {
                      _dragFrom = null;
                    });
                  }
                },
                onPointerUp: (event) {
                  final from = _dragFrom;
                  _dragPosition.value = null;
                  setState(() {
                    _dragFrom = null;
                  });
                  if (from == null || _sending) return;
                  if (event.localPosition.dx < 0 ||
                      event.localPosition.dy < 0 ||
                      event.localPosition.dx >= boardBox.maxWidth ||
                      event.localPosition.dy >= boardBox.maxHeight) {
                    return;
                  }
                  final to = squareAt(event.localPosition);
                  if (from == to) return;
                  if (!_myTurn) {
                    _selected = from;
                    _queuePremove(to);
                    return;
                  }
                  setState(() {
                    _selected = from;
                    _targets = _game.generate_moves({'square': from});
                  });
                  _tap(to);
                },
                child: Stack(children: [
                  GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 64,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 8),
                    itemBuilder: (context, displayIndex) {
                      final index = _flipped ? 63 - displayIndex : displayIndex;
                      final file = index % 8;
                      final rank = 8 - index ~/ 8;
                      final square = '${'abcdefgh'[file]}$rank';
                      final piece = _game.get(square);
                      final light = (index ~/ 8 + file).isEven;
                      final legal =
                          _targets.any((move) => move.toAlgebraic == square);
                      return GestureDetector(
                        key: ValueKey('online-square-$square'),
                        onTap: () => _tap(square),
                        child: ColoredBox(
                          color: _selected == square
                              ? const Color(0xffb5823b)
                              : _premove?.from == square ||
                                      _premove?.to == square
                                  ? const Color(0xff7985a2)
                                  : light
                                      ? const Color(0xffd9b77e)
                                      : const Color(0xff85552f),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              if (piece != null &&
                                  !(_dragFrom == square &&
                                      _dragPosition.value != null))
                                _piece(piece),
                              if (legal)
                                Container(
                                  width: piece == null ? 12 : null,
                                  height: piece == null ? 12 : null,
                                  margin: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: piece == null
                                        ? const Color(0x88412a18)
                                        : null,
                                    border: piece == null
                                        ? null
                                        : Border.all(
                                            color: const Color(0xaae2b75f),
                                            width: 3),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  ValueListenableBuilder<Offset?>(
                    valueListenable: _dragPosition,
                    builder: (context, position, _) {
                      final from = _dragFrom;
                      if (from == null || position == null) {
                        return const SizedBox.shrink();
                      }
                      return Positioned(
                        key: const ValueKey('online-dragged-piece'),
                        left: position.dx - boardBox.maxWidth / 16,
                        top: position.dy - boardBox.maxHeight / 16,
                        width: boardBox.maxWidth / 8,
                        height: boardBox.maxHeight / 8,
                        child: IgnorePointer(
                          child: _piece(_game.get(from)!),
                        ),
                      );
                    },
                  ),
                ]),
              );
            },
          ),
        ),
      );

  Widget _piece(c.Piece piece) {
    final asset = 'lib/images/wood/${const {
      'p': 'pawn',
      'r': 'rook',
      'n': 'knight',
      'b': 'bishop',
      'q': 'queen',
      'k': 'king',
    }[piece.type.name]}.png';
    return Padding(
      padding: const EdgeInsets.all(1),
      child: Image.asset(
        asset,
        color: piece.color == c.Color.WHITE
            ? const Color(0xfffff5df)
            : const Color(0xff48291c),
        colorBlendMode: BlendMode.modulate,
        fit: BoxFit.contain,
      ),
    );
  }
}

class _PlayerBar extends StatefulWidget {
  const _PlayerBar({
    required this.label,
    required this.milliseconds,
    required this.updatedAt,
    required this.running,
    required this.highlighted,
  });

  final String label;
  final int milliseconds;
  final DateTime updatedAt;
  final bool running;
  final bool highlighted;

  @override
  State<_PlayerBar> createState() => _PlayerBarState();
}

class _PlayerBarState extends State<_PlayerBar> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _syncTimer();
  }

  @override
  void didUpdateWidget(covariant _PlayerBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.running != widget.running ||
        oldWidget.updatedAt != widget.updatedAt ||
        oldWidget.milliseconds != widget.milliseconds) {
      _syncTimer();
    }
  }

  void _syncTimer() {
    _timer?.cancel();
    if (widget.running) {
      _timer = Timer.periodic(const Duration(milliseconds: 250), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  int get _milliseconds {
    if (!widget.running) return widget.milliseconds;
    final elapsed =
        DateTime.now().toUtc().difference(widget.updatedAt).inMilliseconds;
    return math.max(0, widget.milliseconds - elapsed);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final seconds = (_milliseconds / 1000).ceil().clamp(0, 99999);
    final time =
        '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Row(
        children: [
          LText(widget.label,
              style: const TextStyle(
                  color: Color(0xfff3eee7), fontWeight: FontWeight.w600)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: widget.highlighted
                  ? const Color(0xfff3eee7)
                  : const Color(0xff202120),
              borderRadius: BorderRadius.circular(7),
            ),
            child: LText(
              time,
              style: TextStyle(
                color: widget.highlighted
                    ? const Color(0xff202120)
                    : const Color(0xfff3eee7),
                fontSize: 20,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GameResultBar extends StatelessWidget {
  const _GameResultBar({
    required this.outcome,
    required this.reason,
    required this.onExit,
  });

  final PlayerGameOutcome outcome;
  final String reason;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final icon = switch (outcome) {
      PlayerGameOutcome.win => Icons.emoji_events_rounded,
      PlayerGameOutcome.loss => Icons.close_rounded,
      PlayerGameOutcome.draw => Icons.balance_rounded,
      _ => Icons.sports_esports_rounded,
    };
    return Container(
      key: const ValueKey('online-result'),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: const Color(0xee202120),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xff81776c)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xfff4d28d)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                LText(
                  outcomeLabel(outcome),
                  style: const TextStyle(
                    color: Color(0xfff3eee7),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (reason.isNotEmpty)
                  LText(reason,
                      style: const TextStyle(color: Color(0xffbdb7af))),
              ],
            ),
          ),
          TextButton(onPressed: onExit, child: const LText('Çık')),
        ],
      ),
    );
  }
}
