import 'dart:async';
import 'package:chess/chess.dart' as c;
import 'package:flutter/material.dart';
import '../backend/app_backend.dart';
import 'auth_screen.dart';

class PuzzleScreen extends StatefulWidget {
  const PuzzleScreen({super.key});
  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen> {
  Map<String, dynamic>? attempt;
  c.Chess game = c.Chess();
  bool busy = false, flipped = false;
  String? selected, hint;
  String message = '';
  List<c.Move> targets = [];
  final elapsed = ValueNotifier<int>(0);
  Timer? timer;

  @override
  void initState() {
    super.initState();
    if (AppBackend.currentUser != null) load();
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
      final row = Map<String, dynamic>.from(
          await AppBackend.client.rpc('start_puzzle') as Map);
      if (!mounted) return;
      setState(() {
        attempt = row;
        selected = hint = null;
        targets = [];
        elapsed.value = 0;
        if (row['empty'] != true) {
          game = c.Chess.fromFEN(row['fen'] as String);
          flipped = game.turn == c.Color.BLACK;
          message = '${flipped ? 'Siyah' : 'Beyaz'} oynar · Matı bul';
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() => message =
            'Bulmacalar yüklenemedi. Bağlantını kontrol edip tekrar dene.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> action(String kind, [String? move]) async {
    if (busy || attempt == null) return;
    setState(() => busy = true);
    try {
      final response = Map<String, dynamic>.from(
          await AppBackend.client.rpc('puzzle_action', params: {
        'p_attempt_id': attempt!['attempt_id'],
        'p_action': kind,
        'p_move': move,
        'p_step': attempt!['step'],
      }) as Map);
      if (!mounted) return;
      setState(() {
        attempt = {...attempt!, ...response};
        selected = null;
        targets = [];
        if (response['fen'] is String) {
          game = c.Chess.fromFEN(response['fen'] as String);
        }
        if (response['resynced'] == true) {
          message = 'Konum güncellendi. Buradan devam et.';
        } else if (kind == 'hint' && response['status'] == 'active') {
          hint = response['hint'] as String?;
          message = 'İşaretli taşla oyna · Yardımlı çözüm puan kazandırmaz';
        } else if (response['correct'] == false) {
          message = 'Bu çözüm değil. Tekrar dene; yanlış deneme puanı azaltır.';
        } else if (response['status'] == 'solved') {
          message =
              'Çözüldü! +${response['awarded_points']} puan · Rating ${response['rating_delta']}';
        } else if (kind == 'skip') {
          message = 'Bulmaca geçildi · Rating ${response['rating_delta']}';
        } else if (kind == 'reveal') {
          final replay = c.Chess.fromFEN(response['initial_fen'] as String);
          for (final uci in (response['solution'] as List)) {
            replay.move({
              'from': uci.substring(0, 2),
              'to': uci.substring(2, 4),
              if (uci.length > 4) 'promotion': uci.substring(4)
            });
          }
          message = 'Çözüm: ${replay.getHistory().join(' ')} · Puan verilmedi';
        } else {
          hint = null;
          message = 'Doğru! Rakip yanıtladı, devamını bul.';
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() => message = 'İşlem doğrulanamadı. Tekrar dene.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
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
                title: const Text('Terfi'),
                children: ['q', 'r', 'b', 'n']
                    .map((p) => SimpleDialogOption(
                          onPressed: () => Navigator.pop(ctx, p),
                          child: Text({
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
      await action('move',
          '${move.fromAlgebraic}${move.toAlgebraic}${move.promotion?.name ?? ''}');
    } else {
      setState(() {
        selected = game.get(square)?.color == game.turn ? square : null;
        targets =
            selected == null ? [] : game.generate_moves({'square': selected});
      });
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    elapsed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xff202120),
        appBar: AppBar(
            title: const Text('Bulmacalar'),
            backgroundColor: const Color(0xff202120),
            foregroundColor: Colors.white),
        body: AppBackend.currentUser == null
            ? Center(
                child: FilledButton(
                onPressed: () async {
                  await Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const AuthScreen()));
                  if (mounted && AppBackend.currentUser != null) load();
                },
                child: const Text('Bulmacalar için giriş yap'),
              ))
            : SafeArea(
                child: SingleChildScrollView(
                    child: Column(children: [
                Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Seviyen: ${attempt?['rating'] ?? 1200}  ·  Puan: ${attempt?['points'] ?? 0}',
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    )),
                if (attempt != null && attempt!['empty'] != true) ...[
                  Text('Bulmaca zorluğu: ${attempt!['difficulty']}',
                      style: const TextStyle(color: Colors.white70)),
                  ValueListenableBuilder<int>(
                      valueListenable: elapsed,
                      builder: (_, seconds, __) => Text(
                          '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}',
                          style: const TextStyle(color: Colors.white70))),
                  Padding(
                      padding: const EdgeInsets.all(12),
                      child: AspectRatio(
                          aspectRatio: 1,
                          child: GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: 64,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 8),
                            itemBuilder: (_, display) {
                              final index = flipped ? 63 - display : display;
                              final square =
                                  '${'abcdefgh'[index % 8]}${8 - index ~/ 8}';
                              final piece = game.get(square);
                              return GestureDetector(
                                  onTap: () => tap(square),
                                  child: ColoredBox(
                                    color: selected == square || hint == square
                                        ? const Color(0xffb89454)
                                        : (index ~/ 8 + index % 8).isEven
                                            ? const Color(0xffd9b77e)
                                            : const Color(0xff85552f),
                                    child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          if (piece != null)
                                            Padding(
                                                padding:
                                                    const EdgeInsets.all(3),
                                                child: Image.asset(
                                                    'lib/images/wood/${{
                                                      'p': 'pawn',
                                                      'r': 'rook',
                                                      'n': 'knight',
                                                      'b': 'bishop',
                                                      'q': 'queen',
                                                      'k': 'king'
                                                    }[piece.type.name]}.png',
                                                    color: piece.color ==
                                                            c.Color.WHITE
                                                        ? const Color(
                                                            0xfffff5df)
                                                        : const Color(
                                                            0xff48291c),
                                                    colorBlendMode:
                                                        BlendMode.modulate)),
                                          if (targets.any(
                                              (m) => m.toAlgebraic == square))
                                            const Icon(Icons.circle,
                                                size: 10,
                                                color: Colors.black38),
                                        ]),
                                  ));
                            },
                          ))),
                ],
                if (busy) const LinearProgressIndicator(),
                Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                        attempt?['empty'] == true
                            ? 'Bu seviyede yeni bulmaca havuzu hazırlanıyor. Daha sonra tekrar gel.'
                            : message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white))),
                if (attempt?['status'] == 'active')
                  Wrap(spacing: 8, children: [
                    TextButton(
                        onPressed: busy ? null : () => action('hint'),
                        child: const Text('İpucu')),
                    TextButton(
                        onPressed: busy ? null : () => action('reveal'),
                        child: const Text('Çözümü göster')),
                    TextButton(
                        onPressed: busy ? null : () => action('skip'),
                        child: const Text('Geç')),
                  ])
                else
                  FilledButton(
                      onPressed: busy ? null : load,
                      child: const Text('Sonraki bulmaca')),
                const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                        'Zorluk + hız bonusu · İpucu puan kazandırmaz\nYanlış denemeler puanı azaltır.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white54))),
              ]))),
      );
}
