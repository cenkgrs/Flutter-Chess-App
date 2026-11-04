import '../theme/board_theme.dart';
import '../l10n/app_language.dart';
import '../widgets/rok_style.dart';
import 'dart:async';
import 'package:chess/chess.dart' as c;
import 'package:flutter/material.dart';

import '../widgets/turn_king.dart';
import '../backend/app_backend.dart';
import '../backend/rating_prompt.dart';
import 'auth_screen.dart';
import '../audio/game_sounds.dart';
import '../widgets/move_animation.dart';

typedef DailyPuzzleRequest = Future<Map<String, dynamic>> Function(
    String, Map<String, dynamic>);

Future<Map<String, dynamic>> _call(DailyPuzzleRequest? request, String name,
        [Map<String, dynamic> params = const {}]) async =>
    request != null
        ? await request(name, params)
        : Map<String, dynamic>.from(
            await AppBackend.client.rpc(name, params: params) as Map);

/// One shared puzzle per Istanbul day. Validation, the clock, points and the
/// streak all live in the `start_daily_puzzle`/`daily_puzzle_action` RPCs.
class DailyPuzzleScreen extends StatefulWidget {
  const DailyPuzzleScreen({super.key, this.request});
  final DailyPuzzleRequest? request;
  @override
  State<DailyPuzzleScreen> createState() => _DailyPuzzleScreenState();
}

class _DailyPuzzleScreenState extends State<DailyPuzzleScreen> {
  Map<String, dynamic>? attempt;
  c.Chess game = c.Chess();
  bool busy = false, flipped = false;
  String? selected, hint;
  String message = '';
  List<c.Move> targets = [];
  final elapsed = ValueNotifier<int>(0);
  Timer? timer;

  bool get signedIn => widget.request != null || AppBackend.currentUser != null;

  @override
  void initState() {
    super.initState();
    if (signedIn) load();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final start = attempt?['started_at'];
      if (start is String && attempt?['status'] == 'active') {
        elapsed.value = DateTime.now()
            .difference(DateTime.parse(start))
            .inSeconds
            .clamp(0, 864000);
      }
    });
  }

  Future<void> load() async {
    if (busy) return;
    setState(() {
      busy = true;
      message = '';
    });
    try {
      final row = await _call(widget.request, 'start_daily_puzzle');
      if (!mounted) return;
      setState(() {
        attempt = row;
        selected = hint = null;
        targets = [];
        elapsed.value = 0;
        if (row['empty'] != true) {
          game = c.Chess.fromFEN(row['fen'] as String);
          // Steps count plies, so after an odd step (a finished solution)
          // the opponent is to move; keep the player's side at the bottom.
          final playerToMove = (row['step'] as num? ?? 0).toInt().isEven;
          flipped = (game.turn == c.Color.BLACK) == playerToMove;
          message = _finishedMessage(row) ??
              '${flipped ? 'Siyah' : 'Beyaz'} oynar · Matı bul';
        }
      });
      if (row['status'] == 'active' && row['step'] == 0) {
        GameSounds.instance.playStart();
      }
    } catch (_) {
      if (mounted) {
        setState(() => message =
            'Günlük bulmaca yüklenemedi. Bağlantını kontrol edip tekrar dene.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  String? _finishedMessage(Map<String, dynamic> row) => switch (row['status']) {
        'solved' => (row['awarded_points'] as num? ?? 0) > 0
            ? 'Çözüldü! +${row['awarded_points']} puan'
            : 'Bugün çözüldü · Puan verilmedi',
        'revealed' => _solutionText(row) ?? 'Bugün kaçırıldı',
        'expired' => 'Bugün kaçırıldı',
        _ => null,
      };

  String? _solutionText(Map<String, dynamic> row) {
    if (row['initial_fen'] is! String || row['solution'] is! List) return null;
    final replay = c.Chess.fromFEN(row['initial_fen'] as String);
    for (final uci in (row['solution'] as List).cast<String>()) {
      replay.move({
        'from': uci.substring(0, 2),
        'to': uci.substring(2, 4),
        if (uci.length > 4) 'promotion': uci.substring(4)
      });
    }
    return 'Çözüm: ${replay.getHistory().join(' ')} · Puan verilmedi';
  }

  /// Lets the player's own slide finish before the reply starts moving.
  static const _replyDelay = Duration(milliseconds: 420);

  Future<void> action(String kind,
      [String? move, c.Chess? rollback, DateTime? movedAt]) async {
    if (busy || attempt == null) return;
    setState(() => busy = true);
    var reload = false;
    try {
      final response = await _call(widget.request, 'daily_puzzle_action', {
        'p_attempt_id': attempt!['attempt_id'],
        'p_action': kind,
        'p_move': move,
        'p_step': attempt!['step'],
      });
      if (!mounted) return;
      final acceptedMove = kind == 'move' && response['correct'] != false;
      final solved = response['status'] == 'solved';
      if (movedAt != null) {
        final wait = _replyDelay - DateTime.now().difference(movedAt);
        if (wait > Duration.zero) await Future<void>.delayed(wait);
        if (!mounted) return;
      }
      final previous = game;
      setState(() {
        attempt = {...attempt!, ...response};
        selected = null;
        targets = [];
        if (response['fen'] is String) {
          game = c.Chess.fromFEN(response['fen'] as String);
        } else if (rollback != null && response['correct'] == false) {
          game = rollback;
        }
        if (response['status'] == 'expired') {
          reload = true;
          message = 'Gün değişti. Yeni bulmaca yükleniyor.';
        } else if (response['resynced'] == true) {
          message = 'Konum güncellendi. Buradan devam et.';
        } else if (kind == 'hint' && response['status'] == 'active') {
          hint = response['hint'] as String?;
          message = 'İşaretli taşla oyna · Yardımlı çözüm puan kazandırmaz';
        } else if (response['correct'] == false) {
          message = 'Bu çözüm değil. Tekrar dene; yanlış deneme puanı azaltır.';
        } else if (response['status'] == 'active') {
          hint = null;
          message = 'Doğru! Rakip yanıtladı, devamını bul.';
        } else {
          hint = null;
          message = _finishedMessage(attempt!) ?? message;
        }
      });
      // The player's move already sounded when it was shown; this is the
      // opponent's reply.
      final replied =
          previous.fen.split(' ').first != game.fen.split(' ').first;
      if (acceptedMove && replied) {
        GameSounds.instance.playMove(capture: capturedBetween(previous, game));
      }
      if (solved) {
        GameSounds.instance.playVictory();
        unawaited(_celebrate());
        unawaited(RatingPrompt.instance.goodMoment());
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          if (rollback != null) game = rollback;
          message = 'İşlem doğrulanamadı. Tekrar dene.';
        });
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
    if (reload && mounted) await load();
  }

  Future<void> _celebrate() => showDialog<void>(
      context: context,
      builder: (context) => RokWoodDialog(
            title: const LText('Bugünün bulmacası çözüldü!',
                textAlign: TextAlign.center),
            content: Column(children: [
              const Icon(Icons.local_fire_department_rounded,
                  color: Color(0xffe0a050), size: 48),
              const SizedBox(height: 8),
              LText('Seri: ${attempt?['current_streak'] ?? 0} gün',
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              LText(
                  (attempt?['awarded_points'] as num? ?? 0) > 0
                      ? '+${attempt!['awarded_points']} puan'
                      : 'Puan verilmedi',
                  style: const TextStyle(color: Color(0xffd2c8be))),
              const SizedBox(height: 6),
              const LText('Yarın yeni bulmaca seni bekliyor.',
                  textAlign: TextAlign.center),
            ]),
            actions: [
              FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const LText('Kapat')),
            ],
          ));

  Future<void> _confirmReveal() async {
    final reveal = await showDialog<bool>(
        context: context,
        builder: (context) => RokDialog(
              icon: const Icon(Icons.visibility_outlined),
              title: const LText('Çözüm gösterilsin mi?'),
              content: const LText(
                  'Çözümü görürsen bugünün bulmacası puansız biter ve serin sıfırlanır.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const LText('Vazgeç')),
                FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const LText('Göster')),
              ],
            ));
    if (reveal == true && mounted) await action('reveal');
  }

  Future<void> tap(String square) async {
    if (busy || attempt?['status'] != 'active') return;
    final moves = targets.where((m) => m.toAlgebraic == square).toList();
    if (moves.isNotEmpty) {
      var move = moves.first;
      if (move.promotion != null) {
        final promotion = await showDialog<String>(
            context: context,
            builder: (ctx) => SimpleDialog(
                title: const LText('Terfi'),
                children: ['q', 'r', 'b', 'n']
                    .map((p) => SimpleDialogOption(
                          onPressed: () => Navigator.pop(ctx, p),
                          child: LText({
                            'q': 'Vezir',
                            'r': 'Kale',
                            'b': 'Fil',
                            'n': 'At'
                          }[p]!),
                        ))
                    .toList()));
        if (!mounted || promotion == null) return;
        move = moves.firstWhere((m) => m.promotion?.name == promotion);
      }
      if (busy) return;
      // Show the player's move right away; the server answers with the
      // position after the opponent's reply, or the move is rolled back.
      final rollback = c.Chess.fromFEN(game.fen);
      setState(() {
        game.move(move);
        selected = null;
        targets = [];
      });
      GameSounds.instance.playMove(capture: move.captured != null);
      await action(
          'move',
          '${move.fromAlgebraic}${move.toAlgebraic}${move.promotion?.name ?? ''}',
          rollback,
          DateTime.now());
    } else {
      setState(() {
        selected = game.get(square)?.color == game.turn ? square : null;
        targets =
            selected == null ? [] : game.generate_moves({'square': selected});
      });
    }
  }

  Widget _piece(c.Piece piece) => BoardPiece(piece);

  Widget _board() => AspectRatio(
      aspectRatio: 1,
      child: RokBoardFrame(
          child: AnimatedBoardPieces(
          position: boardPosition(game),
          flipped: flipped,
          pieceBuilder: (square) => _piece(game.get(square)!),
          builder: (context, hidden) => GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 64,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 8),
                itemBuilder: (_, display) {
                  final index = flipped ? 63 - display : display;
                  final square = '${'abcdefgh'[index % 8]}${8 - index ~/ 8}';
                  final piece = game.get(square);
                  return GestureDetector(
                      onTap: () => tap(square),
                      child: ColoredBox(
                        color: selected == square || hint == square
                            ? boardSkin.selected
                            : boardSkin.base((index ~/ 8 + index % 8).isEven),
                        child: Stack(alignment: Alignment.center, children: [
                          if (piece != null && !hidden.contains(square))
                            _piece(piece),
                          if (targets.any((m) => m.toAlgebraic == square))
                            Icon(Icons.circle,
                                size: 10, color: boardSkin.legalDot),
                        ]),
                      ));
                },
              ))));

  @override
  void dispose() {
    timer?.cancel();
    elapsed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final row = attempt;
    final finished = row != null &&
        row['empty'] != true &&
        row['status'] != null &&
        row['status'] != 'active';
    return RokScaffold(
      backgroundColor: rokGraphite,
      appBar: AppBar(title: const LText('Günlük bulmaca')),
      body: !signedIn
          ? Center(
              child: FilledButton(
              onPressed: () async {
                await Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AuthScreen()));
                if (mounted && AppBackend.currentUser != null) {
                  setState(() {});
                  load();
                }
              },
              child: const LText('Günlük bulmaca için giriş yap'),
            ))
          : SafeArea(
              child: SingleChildScrollView(
                  child: Column(children: [
              Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.local_fire_department_rounded,
                            color: Color(0xffe0a050)),
                        const SizedBox(width: 6),
                        Flexible(
                          child: LText(
                              'Seri: ${row?['current_streak'] ?? 0} gün',
                              key: const ValueKey('daily-streak'),
                              style: const TextStyle(
                                  color: rokBone,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ])),
              if (row != null && row['empty'] != true) ...[
                const SizedBox(height: 10),
                // Clock on one side, level on the other, framing the board.
                Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (row['status'] == 'active')
                            ValueListenableBuilder<int>(
                                valueListenable: elapsed,
                                builder: (_, seconds, __) => RokStatChip(
                                    icon: Icons.timer_outlined,
                                    value:
                                        '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}'))
                          else
                            const SizedBox.shrink(),
                          RokStatChip(
                              icon: Icons.trending_up_rounded,
                              label: 'Seviye',
                              value: '${row['difficulty']}'),
                        ])),
                Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [TurnKing(game.turn, size: 54)])),
                Padding(
                    padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                    child: _board()),
              ],
              if (busy) const LinearProgressIndicator(),
              Padding(
                  padding: const EdgeInsets.all(16),
                  child: LText(
                      row?['empty'] == true
                          ? 'Bugün için bulmaca hazırlanıyor. Daha sonra tekrar gel.'
                          : message,
                      key: const ValueKey('daily-message'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: rokBone, fontSize: 14, height: 1.35))),
              if (row?['status'] == 'active')
                Wrap(spacing: 10, alignment: WrapAlignment.center, children: [
                  TextButton.icon(
                      onPressed: busy ? null : () => action('hint'),
                      icon: const Icon(Icons.lightbulb_outline_rounded,
                          size: 19),
                      label: const LText('İpucu')),
                  OutlinedButton.icon(
                      onPressed: busy ? null : _confirmReveal,
                      icon: const Icon(Icons.visibility_outlined, size: 19),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: rokBone,
                          backgroundColor: const Color(0x33000000),
                          side: const BorderSide(color: Color(0xff6d6356))),
                      label: const LText('Çözümü göster')),
                ])
              else if (finished)
                const LText('Yarın yeni bulmaca seni bekliyor.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: rokBone))
              else if (!busy)
                FilledButton(
                    onPressed: load, child: const LText('Tekrar dene')),
            ]))),
    );
  }
}

/// Home menu row with today's state and the current streak.
class DailyPuzzleMenuEntry extends StatefulWidget {
  const DailyPuzzleMenuEntry({super.key, required this.signedIn, this.request});
  final bool signedIn;
  final DailyPuzzleRequest? request;
  @override
  State<DailyPuzzleMenuEntry> createState() => _DailyPuzzleMenuEntryState();
}

class _DailyPuzzleMenuEntryState extends State<DailyPuzzleMenuEntry>
    with WidgetsBindingObserver {
  Map<String, dynamic>? _status;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void didUpdateWidget(DailyPuzzleMenuEntry oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.signedIn != widget.signedIn) {
      _status = null;
      _load();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The puzzle changes at Istanbul midnight, possibly while backgrounded.
    if (state == AppLifecycleState.resumed) _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _load() async {
    if (!widget.signedIn) return;
    try {
      final status = await _call(widget.request, 'daily_puzzle_status');
      if (mounted) setState(() => _status = status);
    } catch (_) {
      // Keep the menu usable while offline; the next visit retries.
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    final streak = (status?['current_streak'] as num?)?.toInt() ?? 0;
    final solved = status?['status'] == 'solved';
    final subtitle = status == null
        ? 'Her gün yeni bulmaca · Seri kur'
        : switch (status['status']) {
            'solved' => 'Bugün çözüldü',
            'revealed' || 'expired' => 'Bugün kaçırıldı',
            _ => 'Bugün çözülmedi',
          };
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const ValueKey('daily-puzzle'),
        onTap: () async {
          await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => DailyPuzzleScreen(request: widget.request)));
          _load();
        },
        child: SizedBox(
          height: 85,
          child: Row(
            children: [
              const SizedBox(width: 8),
              SizedBox(
                width: 45,
                child: Icon(
                    solved
                        ? Icons.event_available_outlined
                        : Icons.today_outlined,
                    color: rokBone,
                    size: 34),
              ),
              const SizedBox(width: 17),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const LText(
                      'Günlük bulmaca',
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                      style: TextStyle(
                        color: rokBone,
                        fontSize: 19,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    LText(
                      subtitle,
                      key: const ValueKey('daily-puzzle-status'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xffb9aea5),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (streak > 0) ...[
                const Icon(Icons.local_fire_department_rounded,
                    color: Color(0xffe0a050), size: 22),
                Text('$streak',
                    style: const TextStyle(
                        color: rokBone,
                        fontSize: 17,
                        fontWeight: FontWeight.w600)),
                const SizedBox(width: 4),
              ],
              const Icon(Icons.chevron_right_rounded, color: rokBone, size: 30),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}
