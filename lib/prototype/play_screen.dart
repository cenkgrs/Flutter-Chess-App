import '../l10n/app_language.dart';
import '../widgets/rok_style.dart';
import 'dart:math' as math;

import 'package:chess/chess.dart' as c;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'engine.dart';
import 'stockfish_engine.dart';
import '../screens/profile_screen.dart';
import '../widgets/board_annotations.dart';
import 'premove.dart';
import '../ads/match_ads.dart';
import '../audio/game_sounds.dart';

class PlayScreen extends StatefulWidget {
  const PlayScreen(
      {super.key,
      this.assistantMode = false,
      this.initialFen,
      this.initialElo = 1500,
      this.evaluate});
  final Future<EngineEvaluation> Function(String fen, int elo)? evaluate;
  final bool assistantMode;
  final String? initialFen;
  static Future<void> launch(BuildContext context, {String? fen}) async {
    final elo = await showDialog<int>(
        context: context,
        builder: (ctx) => RokWoodDialog(
              title: const LText('Stockfish gücü'),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                const LText(
                    'Motor güç ayarıdır; online rating ile eşdeğer değildir.'),
                for (final value in [1320, 1500, 1800, 2100, 2400, 2800, 3190])
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, value),
                      child: LText('$value')),
              ]),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const LText('Vazgeç'))
              ],
            ));
    if (!context.mounted || elo == null) return;
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => PlayScreen(initialFen: fen, initialElo: elo)));
  }

  final int initialElo;
  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen>
    with SingleTickerProviderStateMixin {
  c.Chess game = c.Chess();
  int engineElo = 1500;
  String? startingFen;
  c.Color human = c.Color.WHITE;
  bool thinking = false, flipped = false, resigned = false;
  int generation = 0;
  String? selected, error, dragFrom;
  Offset? dragPosition;
  List<c.Move> targets = [];
  List<String> notation = [];
  c.Move? last;
  ChessAdvice? assistantAdvice;
  bool resultShown = false;
  Premove? premove;
  final drawing = BoardDrawingController();

  void queuePremove(String square) {
    if (ended) return;
    if (game.get(square)?.color == human) {
      setState(() => selected = square);
    } else if (selected != null) {
      setState(() {
        premove = Premove(selected!, square);
        selected = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: LText('Ön hamle: ${premove!.from} → ${premove!.to}'),
          action: SnackBarAction(
              label: tr(context, 'İptal'),
              onPressed: () => setState(() => premove = null))));
    }
  }

  late final AnimationController assistantPulse;

  @override
  void initState() {
    super.initState();
    MatchAds.instance.preload();
    engineElo = widget.initialElo;
    startingFen = widget.initialFen;
    if (widget.initialFen != null) {
      game = c.Chess.fromFEN(widget.initialFen!);
      human = game.turn;
      flipped = human == c.Color.BLACK;
    }
    assistantPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    if (widget.assistantMode) assistantPulse.repeat(reverse: true);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => GameSounds.instance.playStart());
  }

  bool get ended => resigned || game.game_over;
  void announceResult() {
    if (!mounted || !ended || resultShown) return;
    resultShown = true;
    final won = !resigned && game.in_checkmate && game.turn != human;
    if (won) GameSounds.instance.playVictory();
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => RokResultDialog(
        icon: Icon(won ? Icons.emoji_events_rounded : Icons.flag_outlined),
        title: LText(won
            ? 'Kazandın!'
            : resigned || game.in_checkmate
                ? 'Kaybettin'
                : 'Berabere'),
        content: LText(status),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const LText('Tahtayı incele')),
          TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                openAnalysis();
              },
              child: const LText('Motor analizi')),
          FilledButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await leaveCompletedGame();
              },
              child: const LText('Menüye dön')),
        ],
      ),
    );
  }

  void openAnalysis() {
    final replay =
        startingFen == null ? c.Chess() : c.Chess.fromFEN(startingFen!);
    final moves = <Map<String, dynamic>>[];
    for (final san in game.getHistory().cast<String>()) {
      replay.move(san);
      moves.add({'san': san, 'fen_after': replay.fen});
    }
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => GameReviewScreen(
                  game: const {},
                  playerColor: human,
                  localMoves: moves,
                  initialFen: startingFen,
                )));
  }

  Future<void> leaveCompletedGame() async {
    await MatchAds.instance
        .showIfReady('offline-${identityHashCode(this)}-$generation');
    if (mounted) Navigator.maybePop(context);
  }

  String get status {
    if (error != null) return error!;
    if (resigned) return 'Oyun bitti · Teslim oldun';
    if (game.in_checkmate) {
      return game.turn == human
          ? 'Şah mat · Bilgisayar kazandı'
          : 'Şah mat · Kazandın!';
    }
    if (game.in_stalemate) return 'Beraberlik · Pat';
    if (game.insufficient_material) return 'Beraberlik · Yetersiz taş';
    if (game.in_threefold_repetition) return 'Beraberlik · Üç konum tekrarı';
    if (game.in_draw) return 'Beraberlik · 50 hamle kuralı';
    if (thinking) return 'Bilgisayar düşünüyor…';
    return '${game.turn == human ? 'Sıra sende' : 'Bilgisayarın sırası'}${game.in_check ? ' · Şah!' : ''}';
  }

  void refresh() {
    notation = game.getHistory().cast<String>();
    last = game.history.isEmpty ? null : game.history.last.move;
    selected = null;
    dragFrom = null;
    dragPosition = null;
    targets = [];
  }

  Future<void> ai() async {
    if (ended || game.turn == human || thinking) return;
    final ticket = generation;
    setState(() {
      thinking = true;
      error = null;
    });
    try {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      if (!mounted || ticket != generation) return;
      final evaluation = widget.evaluate != null
          ? await widget.evaluate!(game.fen, engineElo)
          : await DeviceEngine.instance.evaluate(game.fen, elo: engineElo);
      final move = evaluation.move;
      if (!mounted || ticket != generation) return;
      var moved = false;
      setState(() {
        if (move != null) {
          game.move({
            'from': move.substring(0, 2),
            'to': move.substring(2, 4),
            if (move.length > 4) 'promotion': move[4]
          });
          moved = true;
        }
        assistantAdvice = null;
        thinking = false;
        refresh();
      });
      if (moved) GameSounds.instance.playMove();
      announceResult();
      final queued = premove;
      premove = null;
      if (!ended && queued != null) {
        final next = queued.resolve(game);
        if (next != null) {
          setState(() {
            game.move(next);
            refresh();
          });
          GameSounds.instance.playMove();
          await ai();
          announceResult();
        }
      }
    } catch (_) {
      if (!mounted || ticket != generation) return;
      setState(() {
        thinking = false;
        error = 'Hamle hesaplanamadı. Tekrar deneyin.';
      });
    }
  }

  Future<void> tap(String square) async {
    if (ended) return;
    if (thinking || game.turn != human) {
      queuePremove(square);
      return;
    }
    premove = null;
    final candidates = targets.where((m) => m.toAlgebraic == square).toList();
    if (candidates.isNotEmpty) {
      var move = candidates.first;
      if (move.promotion != null) {
        final ticket = generation;
        final promotion = await showDialog<String>(
            context: context,
            builder: (context) => RokDialog(
                  title: const LText('Piyonunu terfi ettir'),
                  content: Wrap(
                      spacing: 8,
                      children: ['q', 'r', 'b', 'n']
                          .map((p) => TextButton(
                                onPressed: () => Navigator.pop(context, p),
                                child: LText({
                                  'q': 'Vezir',
                                  'r': 'Kale',
                                  'b': 'Fil',
                                  'n': 'At'
                                }[p]!),
                              ))
                          .toList()),
                ));
        if (!mounted || ticket != generation || promotion == null) return;
        move = candidates.firstWhere((m) => m.promotion?.name == promotion);
      }
      setState(() {
        game.move(move);
        assistantAdvice = null;
        refresh();
      });
      GameSounds.instance.playMove();
      await ai();
      announceResult();
      return;
    }
    setState(() {
      selected = game.get(square)?.color == human && selected != square
          ? square
          : null;
      targets =
          selected == null ? [] : game.generate_moves({'square': selected});
    });
  }

  Future<void> newGame() async {
    var nextDifficulty = engineElo;
    var nextColor = human;
    final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
            builder: (context, update) => RokDialog(
                  title: const LText('Yeni bir oyun'),
                  content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const LText('Rakibin seviyesi'),
                        DropdownButton<int>(
                            isExpanded: true,
                            value: nextDifficulty,
                            items: const [
                              1320,
                              1500,
                              1800,
                              2100,
                              2400,
                              2800,
                              3190
                            ]
                                .map((d) => DropdownMenuItem(
                                    value: d, child: LText('Stockfish · $d')))
                                .toList(),
                            onChanged: (d) =>
                                update(() => nextDifficulty = d!)),
                        const SizedBox(height: 16),
                        const LText('Taş rengin'),
                        DropdownButton<c.Color>(
                            isExpanded: true,
                            value: nextColor,
                            items: const [
                              DropdownMenuItem(
                                  value: c.Color.WHITE,
                                  child: LText('Beyaz · İlk hamle sende')),
                              DropdownMenuItem(
                                  value: c.Color.BLACK,
                                  child: LText('Siyah · Bilgisayar başlar'))
                            ],
                            onChanged: (v) => update(() => nextColor = v!)),
                        const SizedBox(height: 12),
                        const LText(
                            'Stockfish güç ayarıdır; online rating ile eşdeğer değildir. Mevcut oyun sıfırlanır.',
                            style: TextStyle(fontSize: 12)),
                      ]),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const LText('Vazgeç')),
                    FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const LText('Oyuna başla'))
                  ],
                )));
    if (!mounted || accepted != true) return;
    setState(() {
      generation++;
      game = c.Chess();
      MatchAds.instance.preload();
      premove = null;
      startingFen = null;
      human = nextColor;
      engineElo = nextDifficulty;
      flipped = human == c.Color.BLACK;
      thinking = false;
      resigned = false;
      resultShown = false;
      error = null;
      assistantAdvice = null;
      refresh();
    });
    GameSounds.instance.playStart();
    await ai();
  }

  void undo() {
    premove = null;
    if (game.history.isEmpty) return;
    setState(() {
      generation++;
      thinking = false;
      resigned = false;
      resultShown = false;
      error = null;
      assistantAdvice = null;
      game.undo_move();
      if (game.turn != human && game.history.isNotEmpty) game.undo_move();
      refresh();
    });
    ai();
  }

  Future<void> resign() async {
    final yes = await showDialog<bool>(
        context: context,
        builder: (context) => RokDialog(
                title: const LText('Teslim olmak istiyor musun?'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const LText('Devam et')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const LText('Teslim ol'))
                ]));
    if (!mounted || yes != true) return;
    setState(() {
      generation++;
      thinking = false;
      resigned = true;
      selected = null;
      targets = [];
    });
    announceResult();
  }

  @override
  void dispose() {
    generation++;
    assistantPulse.dispose();
    drawing.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff3b1e0f),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          color: Color(0xff4b2714),
          image: DecorationImage(
            image: AssetImage('lib/images/wood/background.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Color(0x18000000), BlendMode.darken),
          ),
        ),
        child: SafeArea(
          child: Stack(children: [
            LayoutBuilder(builder: (context, box) {
              final boardSize = math.max(
                0.0,
                math.min(box.maxWidth, box.maxHeight - 154),
              );
              final showTurn =
                  !ended && !thinking && error == null && game.turn == human;
              return Padding(
                padding: EdgeInsets.zero,
                child: Column(children: [
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 42,
                    child: Center(
                      child: ended
                          ? LText(status,
                              style: const TextStyle(
                                  color: Color(0xfff3eee7),
                                  fontWeight: FontWeight.bold))
                          : showTurn
                              ? const _TurnIndicator()
                              : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: SizedBox(
                      width: boardSize,
                      height: boardSize,
                      child: Stack(children: [
                        Positioned.fill(
                            child: BoardAnnotations(
                                controller: drawing,
                                flipped: flipped,
                                child: boardWidget())),
                        if (assistantAdvice != null)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: CustomPaint(
                                key: const ValueKey('assistant-arrow'),
                                painter: _MoveArrowPainter(
                                  from: assistantAdvice!.from,
                                  to: assistantAdvice!.to,
                                  flipped: flipped,
                                ),
                              ),
                            ),
                          ),
                      ]),
                    ),
                  ),
                  if (widget.assistantMode && assistantAdvice != null)
                    Expanded(child: _assistantPanel())
                  else
                    const Spacer(),
                  if (ended)
                    TextButton.icon(
                      onPressed: leaveCompletedGame,
                      icon: const Icon(Icons.arrow_back),
                      label: const LText('Menüye dön'),
                      style: TextButton.styleFrom(
                          foregroundColor: const Color(0xfff3eee7)),
                    ),
                  _InspectionButton(onPressed: openReview),
                  const SizedBox(height: 18),
                ]),
              );
            }),
            Positioned(
                top: 8, left: 2, child: BoardDrawingTools(controller: drawing)),
            if (widget.assistantMode)
              Positioned(
                top: 8,
                right: 10,
                child: AnimatedBuilder(
                  animation: assistantPulse,
                  builder: (context, child) => Transform.scale(
                    scale: .94 + assistantPulse.value * .12,
                    child: Transform.rotate(
                      angle: math.sin(assistantPulse.value * math.pi * 2) * .1,
                      child: child,
                    ),
                  ),
                  child: IconButton.filledTonal(
                    key: const ValueKey('assistant-info'),
                    tooltip: tr(context, 'Asistana sor'),
                    onPressed: !ended && !thinking && game.turn == human
                        ? _showAssistant
                        : null,
                    icon: const Icon(Icons.auto_awesome_rounded),
                  ),
                ),
              ),
          ]),
        ),
      ),
    );
  }

  Future<void> _showAssistant() async {
    final fen = game.fen;
    final advice = await ChessEngine().explain(game);
    if (!mounted || game.fen != fen) return;
    setState(() => assistantAdvice = advice);
  }

  Widget _assistantPanel() => LayoutBuilder(
      builder: (context, bounds) => SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                onPressed: () => setState(() => assistantAdvice = null),
                icon: const Icon(Icons.close),
              ),
            ),
            SizedBox(
              height: math.min(120, bounds.maxHeight * .38),
              child: Image.asset('lib/images/assistant-strategist.png',
                  fit: BoxFit.contain),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 6, 4, 10),
              child: LText(
                '${assistantAdvice!.firstSentence}\n${assistantAdvice!.secondSentence}\nAna varyant: ${assistantAdvice!.variation.join('  ')}',
                style:
                    const TextStyle(color: rokBone, fontSize: 12, height: 1.35),
              ),
            ),
          ])));

  Future<void> openReview() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      barrierColor: Colors.black.withValues(alpha: .68),
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => reviewSheet(sheetContext),
    );
  }

  Widget boardWidget() => DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xff8f5b2e), Color(0xff3a1a0d)],
          ),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: const Color(0xffb9874f), width: 1.2),
          boxShadow: const [
            BoxShadow(
                color: Colors.black54, blurRadius: 18, offset: Offset(0, 9)),
            BoxShadow(color: Color(0x55301a0c), blurRadius: 2, spreadRadius: 2),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LayoutBuilder(builder: (context, boardBox) {
              String squareAt(Offset position) {
                final column =
                    (position.dx / (boardBox.maxWidth / 8)).floor().clamp(0, 7);
                final row = (position.dy / (boardBox.maxHeight / 8))
                    .floor()
                    .clamp(0, 7);
                final displayIndex = row * 8 + column;
                final index = flipped ? 63 - displayIndex : displayIndex;
                return '${'abcdefgh'[index % 8]}${8 - index ~/ 8}';
              }

              return Listener(
                onPointerDown: (event) {
                  if (event.buttons != 1) return;
                  final square = squareAt(event.localPosition);
                  if (!ended && game.get(square)?.color == human) {
                    setState(() {
                      dragFrom = square;
                      dragPosition = event.localPosition;
                    });
                  }
                },
                onPointerMove: (event) {
                  if (dragFrom != null) {
                    setState(() => dragPosition = event.localPosition);
                  }
                },
                onPointerCancel: (_) {
                  if (dragFrom != null) {
                    setState(() {
                      dragFrom = null;
                      dragPosition = null;
                    });
                  }
                },
                onPointerUp: (event) async {
                  final from = dragFrom;
                  setState(() {
                    dragFrom = null;
                    dragPosition = null;
                  });
                  if (from == null || ended) {
                    return;
                  }
                  if (event.localPosition.dx < 0 ||
                      event.localPosition.dy < 0 ||
                      event.localPosition.dx >= boardBox.maxWidth ||
                      event.localPosition.dy >= boardBox.maxHeight) {
                    return;
                  }
                  final to = squareAt(event.localPosition);
                  if (from == to) return;
                  if (thinking || game.turn != human) {
                    selected = from;
                    queuePremove(to);
                    return;
                  }
                  setState(() {
                    selected = from;
                    targets = game.generate_moves({'square': from});
                  });
                  await tap(to);
                },
                child: Stack(children: [
                  GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 64,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 8,
                    ),
                    itemBuilder: (context, i) {
                      final index = flipped ? 63 - i : i;
                      final file = index % 8, rank = 8 - index ~/ 8;
                      final square = '${'abcdefgh'[file]}$rank';
                      final piece = game.get(square);
                      final legal = targets.any((m) => m.toAlgebraic == square);
                      final recent = last?.fromAlgebraic == square ||
                          last?.toAlgebraic == square;
                      final check = piece?.type == c.PieceType.KING &&
                          piece?.color == game.turn &&
                          game.in_check;
                      final isLight = (index ~/ 8 + file).isEven;
                      final base = isLight
                          ? const Color(0xffd9b77e)
                          : const Color(0xff85552f);
                      final overlay = check
                          ? const Color(0x99a73e32)
                          : selected == square
                              ? const Color(0x99d39a35)
                              : premove?.from == square || premove?.to == square
                                  ? const Color(0x996b83ba)
                                  : recent
                                      ? const Color(0x667a743e)
                                      : Colors.transparent;
                      return Semantics(
                          label:
                              '$square ${piece == null ? 'boş' : '${piece.color == c.Color.WHITE ? 'beyaz' : 'siyah'} ${piece.type.name}'}',
                          button: true,
                          child: GestureDetector(
                            key: ValueKey('square-$square'),
                            onTap: () => tap(square),
                            child: _WoodSurface(
                                seed: index + (isLight ? 100 : 200),
                                base: base,
                                overlay: overlay,
                                child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      if (piece != null &&
                                          !(dragFrom == square &&
                                              dragPosition != null))
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
                                                border: piece != null
                                                    ? Border.all(
                                                        color: const Color(
                                                            0xaae2b75f),
                                                        width: 3)
                                                    : null)),
                                      if (i % 8 == 0)
                                        Positioned(
                                            top: 2,
                                            left: 3,
                                            child: LText('$rank',
                                                style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                    color: isLight
                                                        ? const Color(
                                                            0xff684426)
                                                        : const Color(
                                                            0xffe3c691)))),
                                      if (i >= 56)
                                        Positioned(
                                            bottom: 1,
                                            right: 3,
                                            child: LText('abcdefgh'[file],
                                                style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                    color: isLight
                                                        ? const Color(
                                                            0xff684426)
                                                        : const Color(
                                                            0xffe3c691)))),
                                    ])),
                          ));
                    },
                  ),
                  if (dragFrom != null && dragPosition != null)
                    Positioned(
                      key: const ValueKey('dragged-piece'),
                      left: dragPosition!.dx - boardBox.maxWidth / 16,
                      top: dragPosition!.dy - boardBox.maxHeight / 16,
                      width: boardBox.maxWidth / 8,
                      height: boardBox.maxHeight / 8,
                      child: IgnorePointer(
                        child: _piece(game.get(dragFrom!)!),
                      ),
                    ),
                ]),
              );
            }),
          ),
        ),
      );

  Widget _piece(c.Piece piece) {
    final asset = 'lib/images/wood/${{
      'p': 'pawn',
      'r': 'rook',
      'n': 'knight',
      'b': 'bishop',
      'q': 'queen',
      'k': 'king'
    }[piece.type.name]}.png';
    final pieceColor = piece.color == c.Color.WHITE
        ? const Color(0xfffff5df)
        : const Color(0xff48291c);
    return Padding(
      padding: const EdgeInsets.all(1),
      child: ClipRect(
        child: Transform.scale(
          scale: 1.14,
          child: Image.asset(asset,
              color: pieceColor,
              colorBlendMode: BlendMode.modulate,
              fit: BoxFit.contain),
        ),
      ),
    );
  }

  Widget reviewSheet(BuildContext sheetContext) {
    final screenHeight = MediaQuery.sizeOf(sheetContext).height;
    return Container(
      height: math.min(520, screenHeight * .58),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
      decoration: const BoxDecoration(
        color: Color(0xfffffbf2),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
              color: Colors.black38, blurRadius: 22, offset: Offset(0, -6))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(
          child: Container(
            width: 52,
            height: 5,
            decoration: BoxDecoration(
                color: const Color(0xffd5cbb9),
                borderRadius: BorderRadius.circular(99)),
          ),
        ),
        const SizedBox(height: 7),
        Row(children: [
          const Icon(Icons.manage_search_rounded,
              size: 30, color: Color(0xff2d2118)),
          const SizedBox(width: 9),
          const LText('İNCELEME',
              style: TextStyle(
                  color: Color(0xff2d2118),
                  fontFamily: 'serif',
                  fontSize: 19,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700)),
          const Spacer(),
          TextButton.icon(
            onPressed: () => Navigator.pop(sheetContext),
            icon: const Icon(Icons.close, size: 20),
            label: const LText('Kapat'),
          ),
        ]),
        const Divider(height: 20, color: Color(0xffddd3c2)),
        if (game.turn != human || ended || error != null) ...[
          LText(status,
              style: const TextStyle(
                  color: Color(0xff755b3e), fontWeight: FontWeight.w600)),
          const SizedBox(height: 9),
        ],
        Row(children: [
          const Icon(Icons.receipt_long_outlined,
              size: 23, color: Color(0xff2d2118)),
          const SizedBox(width: 9),
          const Expanded(
            child: LText('Hamle geçmişi',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ),
          IconButton(
            key: const ValueKey('new-game'),
            tooltip: tr(context, 'Yeni oyun'),
            onPressed: () {
              Navigator.pop(sheetContext);
              newGame();
            },
            icon: const Icon(Icons.restart_alt_rounded, size: 21),
          ),
          IconButton(
            tooltip: tr(context, 'PGN kopyala'),
            onPressed: notation.isEmpty ? null : copyPgn,
            icon: const Icon(Icons.copy_rounded, size: 20),
          ),
        ]),
        const SizedBox(height: 8),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xfff1eadc),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: const Color(0xffe5dac7)),
            ),
            child: notation.isEmpty
                ? const Center(
                    child: LText('Henüz hamle yapılmadı',
                        style: TextStyle(color: Color(0xff827566))))
                : ListView.builder(
                    itemCount: (notation.length + 1) ~/ 2,
                    itemBuilder: (context, i) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(children: [
                        SizedBox(
                          width: 34,
                          child: LText('${i + 1}.',
                              style: const TextStyle(color: Color(0xff9a8974))),
                        ),
                        Expanded(child: LText(notation[i * 2])),
                        Expanded(
                          child: LText(i * 2 + 1 < notation.length
                              ? notation[i * 2 + 1]
                              : '…'),
                        ),
                      ]),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 13),
        Row(children: [
          Expanded(
            child: _ReviewAction(
              icon: Icons.undo_rounded,
              label: 'Geri al',
              enabled: game.history.isNotEmpty,
              onPressed: () {
                Navigator.pop(sheetContext);
                undo();
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ReviewAction(
              icon: Icons.sync_rounded,
              label: 'Tahtayı çevir',
              onPressed: () {
                Navigator.pop(sheetContext);
                setState(() => flipped = !flipped);
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ReviewAction(
              icon: Icons.flag_rounded,
              label: 'Teslim ol',
              enabled: !ended,
              onPressed: () {
                Navigator.pop(sheetContext);
                resign();
              },
            ),
          ),
        ]),
      ]),
    );
  }

  Future<void> copyPgn() async {
    await Clipboard.setData(ClipboardData(text: game.pgn()));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: LText('PGN panoya kopyalandı')));
    }
  }
}

class _TurnIndicator extends StatelessWidget {
  const _TurnIndicator();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xff684221),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: const Color(0xffd8aa5c)),
          boxShadow: const [
            BoxShadow(
                color: Colors.black38, blurRadius: 8, offset: Offset(0, 3))
          ],
        ),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.circle, size: 8, color: Color(0xffffd889)),
          SizedBox(width: 9),
          LText('Sıra sende',
              style: TextStyle(
                  color: Color(0xffffe2a9),
                  fontFamily: 'serif',
                  fontWeight: FontWeight.w600,
                  letterSpacing: .4)),
        ]),
      );
}

class _InspectionButton extends StatelessWidget {
  const _InspectionButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xff8b5c2d), Color(0xff573018)]),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: const Color(0xffd0a259)),
          boxShadow: const [
            BoxShadow(
                color: Colors.black45, blurRadius: 11, offset: Offset(0, 5))
          ],
        ),
        child: TextButton.icon(
          key: const ValueKey('inspection'),
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xffffd991),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
          ),
          icon: const Icon(Icons.manage_search_rounded, size: 22),
          label: const LText('İNCELEME',
              style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 13,
                  letterSpacing: 1.3,
                  fontWeight: FontWeight.w700)),
        ),
      );
}

class _ReviewAction extends StatelessWidget {
  const _ReviewAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        onPressed: enabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xff35271d),
          side: const BorderSide(color: Color(0xffded1bd)),
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
        ),
        icon: Icon(icon, size: 20),
        label: FittedBox(
          fit: BoxFit.scaleDown,
          child: LText(label, maxLines: 1),
        ),
      );
}

class _WoodSurface extends StatelessWidget {
  const _WoodSurface({
    required this.seed,
    required this.base,
    required this.child,
    this.overlay = Colors.transparent,
  });

  final int seed;
  final Color base;
  final Color overlay;
  final Widget child;

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _WoodPainter(seed: seed, base: base, overlay: overlay),
        child: child,
      );
}

class _WoodPainter extends CustomPainter {
  const _WoodPainter(
      {required this.seed, required this.base, required this.overlay});

  final int seed;
  final Color base;
  final Color overlay;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final lightness = HSLColor.fromColor(base);
    final lighter = lightness
        .withLightness((lightness.lightness + .07).clamp(0, 1))
        .toColor();
    final darker = lightness
        .withLightness((lightness.lightness - .05).clamp(0, 1))
        .toColor();
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [lighter, base, darker],
        ).createShader(rect),
    );

    final random = math.Random(seed);
    final grain = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .55
      ..color = Colors.black.withValues(alpha: .09);
    final lineCount = math.max(5, (size.height / 9).round());
    for (var i = 0; i < lineCount; i++) {
      final y = random.nextDouble() * size.height;
      final wave = 1.2 + random.nextDouble() * 2.4;
      final path = Path()..moveTo(0, y);
      for (double x = 0; x <= size.width; x += 12) {
        path.lineTo(x, y + math.sin(x / 22 + i) * wave);
      }
      canvas.drawPath(path, grain);
    }
    if (overlay.a > 0) canvas.drawRect(rect, Paint()..color = overlay);
  }

  @override
  bool shouldRepaint(covariant _WoodPainter oldDelegate) =>
      seed != oldDelegate.seed ||
      base != oldDelegate.base ||
      overlay != oldDelegate.overlay;
}

class _MoveArrowPainter extends CustomPainter {
  const _MoveArrowPainter({
    required this.from,
    required this.to,
    required this.flipped,
  });

  final String from;
  final String to;
  final bool flipped;

  Offset _center(String square, Size size) {
    const boardInset = 7.0;
    final squareSize = (size.width - boardInset * 2) / 8;
    final file = 'abcdefgh'.indexOf(square[0]);
    final rank = int.parse(square[1]);
    final column = flipped ? 7 - file : file;
    final row = flipped ? rank - 1 : 8 - rank;
    return Offset(
      boardInset + (column + .5) * squareSize,
      boardInset + (row + .5) * squareSize,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final start = _center(from, size);
    final end = _center(to, size);
    final direction = end - start;
    if (direction.distance == 0) return;
    final unit = direction / direction.distance;
    final shortenedEnd = end - unit * (size.width / 34);
    final width = math.max(7.0, size.width / 42);
    final paint = Paint()
      ..color = const Color(0xd96c7074)
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(start, shortenedEnd, paint);

    final normal = Offset(-unit.dy, unit.dx);
    final headLength = size.width / 18;
    final headWidth = size.width / 25;
    final path = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(
        end.dx - unit.dx * headLength + normal.dx * headWidth,
        end.dy - unit.dy * headLength + normal.dy * headWidth,
      )
      ..lineTo(
        end.dx - unit.dx * headLength - normal.dx * headWidth,
        end.dy - unit.dy * headLength - normal.dy * headWidth,
      )
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xe66c7074)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _MoveArrowPainter oldDelegate) =>
      oldDelegate.from != from ||
      oldDelegate.to != to ||
      oldDelegate.flipped != flipped;
}
