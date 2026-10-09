import 'dart:async';
import 'dart:math' as math;

import 'package:chess/chess.dart' as c;
import 'package:flutter/material.dart';

import '../backend/app_backend.dart';
import '../backend/game_repository.dart';

class OnlineGameScreen extends StatefulWidget {
  const OnlineGameScreen({super.key, required this.gameId});

  final String gameId;

  @override
  State<OnlineGameScreen> createState() => _OnlineGameScreenState();
}

class _OnlineGameScreenState extends State<OnlineGameScreen> {
  final _repository = GameRepository();
  StreamSubscription<Map<String, dynamic>>? _subscription;
  Timer? _clockTimer;
  Map<String, dynamic>? _row;
  c.Chess _game = c.Chess();
  String? _selected;
  String? _dragFrom;
  List<c.Move> _targets = [];
  bool _sending = false;
  String? _error;
  bool _finishSent = false;

  String get _myId => AppBackend.currentUser!.id;
  bool get _isWhite => _row?['white_id'] == _myId;
  bool get _myTurn =>
      _row?['status'] == 'active' &&
      ((_game.turn == c.Color.WHITE) == _isWhite);
  bool get _flipped => !_isWhite;

  @override
  void initState() {
    super.initState();
    _subscription = _repository.watchGame(widget.gameId).listen(
      _applySnapshot,
      onError: (_) {
        if (mounted) setState(() => _error = 'Oyun bağlantısı kesildi.');
      },
    );
    _clockTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (mounted && _row?['status'] == 'active') {
        setState(() {});
        _checkTimeout();
      }
    });
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
    try {
      setState(() {
        _row = row;
        _game = c.Chess.fromFEN(row['fen'] as String);
        _selected = null;
        _targets = [];
        _sending = false;
        _error = null;
      });
    } catch (_) {
      setState(() => _error = 'Sunucudan geçersiz oyun konumu geldi.');
    }
  }

  ({int white, int black}) get _clocks {
    final row = _row;
    if (row == null) return (white: 0, black: 0);
    var white = row['white_ms'] as int;
    var black = row['black_ms'] as int;
    if (row['status'] == 'active') {
      final updated = DateTime.parse(row['updated_at'] as String).toUtc();
      final elapsed = DateTime.now().toUtc().difference(updated).inMilliseconds;
      if (_game.turn == c.Color.WHITE) {
        white = math.max(0, white - elapsed);
      } else {
        black = math.max(0, black - elapsed);
      }
    }
    return (white: white, black: black);
  }

  Future<void> _tap(String square) async {
    if (!_myTurn || _sending || _row == null) return;
    final candidates = _targets.where((move) => move.toAlgebraic == square);
    if (candidates.isNotEmpty) {
      var move = candidates.first;
      if (move.promotion != null) {
        final promotion = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Piyonunu terfi ettir'),
            actions: ['q', 'r', 'b', 'n']
                .map((piece) => TextButton(
                      onPressed: () => Navigator.pop(context, piece),
                      child: Text(const {
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
      await _repository.submitMove(
        gameId: widget.gameId,
        expectedPly: row['ply'] as int,
        uci:
            '${move.fromAlgebraic}${move.toAlgebraic}${move.promotion?.name ?? ''}',
        san: san,
        fenAfter: gameAfter.fen,
        whiteMs: whiteMs,
        blackMs: blackMs,
      );
      if (gameAfter.game_over) await _finish(gameAfter);
    } catch (_) {
      if (mounted) {
        setState(() {
          _sending = false;
          _error = 'Hamle gönderilemedi; konum yenileniyor.';
        });
      }
    }
  }

  Future<void> _finish(c.Chess game) async {
    if (_finishSent) return;
    _finishSent = true;
    final result = game.in_checkmate
        ? (game.turn == c.Color.WHITE ? 'black' : 'white')
        : 'draw';
    await _repository.finishGame(
      gameId: widget.gameId,
      result: result,
      reason: game.in_checkmate ? 'checkmate' : 'draw',
    );
  }

  Future<void> _resign() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Teslim olmak istiyor musun?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Devam et')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Teslim ol')),
        ],
      ),
    );
    if (confirmed != true) return;
    await _repository.finishGame(
      gameId: widget.gameId,
      result: _isWhite ? 'black' : 'white',
      reason: 'resignation',
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _clockTimer?.cancel();
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
                        : Text(_error!,
                            style: const TextStyle(color: Color(0xfff3eee7))),
                  )
                : LayoutBuilder(
                    builder: (context, box) {
                      final boardSize =
                          math.min(box.maxWidth, box.maxHeight - 180);
                      final clocks = _clocks;
                      return Column(
                        children: [
                          _PlayerBar(
                            label: _flipped ? 'Beyaz' : 'Siyah',
                            milliseconds:
                                _flipped ? clocks.white : clocks.black,
                            active: _game.turn ==
                                (_flipped ? c.Color.WHITE : c.Color.BLACK),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: boardSize,
                            height: boardSize,
                            child: _board(),
                          ),
                          const SizedBox(height: 10),
                          _PlayerBar(
                            label: _flipped ? 'Siyah · Sen' : 'Beyaz · Sen',
                            milliseconds:
                                _flipped ? clocks.black : clocks.white,
                            active: _myTurn,
                          ),
                          const Spacer(),
                          if (_error != null)
                            Text(_error!,
                                style:
                                    const TextStyle(color: Color(0xffffd8c7))),
                          TextButton.icon(
                            onPressed:
                                _row?['status'] == 'active' ? _resign : null,
                            icon: const Icon(Icons.flag_outlined),
                            label: const Text('Teslim ol'),
                            style: TextButton.styleFrom(
                                foregroundColor: const Color(0xfff3eee7)),
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
                  final square = squareAt(event.localPosition);
                  final mine = _isWhite ? c.Color.WHITE : c.Color.BLACK;
                  _dragFrom = _game.get(square)?.color == mine ? square : null;
                },
                onPointerCancel: (_) => _dragFrom = null,
                onPointerUp: (event) {
                  final from = _dragFrom;
                  _dragFrom = null;
                  if (from == null || !_myTurn || _sending) return;
                  final to = squareAt(event.localPosition);
                  if (from == to) return;
                  setState(() {
                    _selected = from;
                    _targets = _game.generate_moves({'square': from});
                  });
                  _tap(to);
                },
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 64,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                            : light
                                ? const Color(0xffd9b77e)
                                : const Color(0xff85552f),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (piece != null) _piece(piece),
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

class _PlayerBar extends StatelessWidget {
  const _PlayerBar({
    required this.label,
    required this.milliseconds,
    required this.active,
  });

  final String label;
  final int milliseconds;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final seconds = (milliseconds / 1000).ceil().clamp(0, 99999);
    final time =
        '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(
                  color: Color(0xfff3eee7), fontWeight: FontWeight.w600)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: active ? const Color(0xfff3eee7) : const Color(0xff202120),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(
              time,
              style: TextStyle(
                color:
                    active ? const Color(0xff202120) : const Color(0xfff3eee7),
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
