import '../l10n/app_language.dart';
import '../widgets/rok_style.dart';
import 'dart:async';
import 'package:chess/chess.dart' as c;
import 'package:flutter/material.dart';
import '../backend/app_backend.dart';
import 'auth_screen.dart';

class PuzzleDuelScreen extends StatefulWidget {
  const PuzzleDuelScreen({super.key, this.request, this.gameId});
  final String? gameId;
  final Future<Map<String, dynamic>> Function(String, Map<String, dynamic>)?
      request;
  @override
  State<PuzzleDuelScreen> createState() => _PuzzleDuelScreenState();
}

class _PuzzleDuelScreenState extends State<PuzzleDuelScreen> {
  Timer? _timer;
  Map<String, dynamic>? _state;
  String? _id, _selected, _error;
  bool _busy = false, _searching = false;
  int? _rating;
  Map<String, dynamic>? _rematch;
  Future<Map<String, dynamic>> _rpc(String name,
          [Map<String, dynamic> params = const {}]) async =>
      widget.request != null
          ? await widget.request!(name, params)
          : Map<String, dynamic>.from(
              await AppBackend.client.rpc(name, params: params) as Map);

  Future<void> _profile() async {
    if (AppBackend.currentUser == null && widget.request == null) return;
    try {
      final row = await _rpc('duel_profile');
      if (!mounted) return;
      setState(() {
        _rating = (row['rating'] as num).toInt();
        _id = row['game_id'] as String?;
      });
      if (_id != null) await _sync();
    } catch (_) {
      if (mounted) setState(() => _error = 'Rekabetçi profil yüklenemedi.');
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.gameId != null) {
      _id = widget.gameId;
      _sync();
    } else {
      _profile();
    }
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (_state?['status'] == 'finished' &&
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        _checkRematch();
      }
      if ((_searching || (_id != null && _state?['status'] != 'finished')) &&
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        _sync();
      }
    });
  }

  Future<void> _checkRematch({bool request = false}) async {
    if (_busy || _id == null) return;
    _busy = true;
    try {
      final row = await _rpc(
          request ? 'duel_rematch' : 'duel_rematch_status', {'p_match': _id});
      if (!mounted) return;
      final next = row['game_id'] as String?;
      setState(() {
        _rematch = row;
        if (next != null) {
          _id = next;
          _state = null;
          _selected = null;
          _rematch = null;
        }
      });
      if (next != null) {
        _busy = false;
        await _sync();
      }
    } catch (_) {
      if (mounted && request) {
        setState(() => _error = 'Rövanş gönderilemedi. Tekrar dene.');
      }
    } finally {
      _busy = false;
    }
  }

  Widget _resultDetails(Map<String, dynamic> s) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Card(
            color: rokGraphite,
            child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(children: [
                  Icon(
                      s['score'] == s['opponent_score']
                          ? Icons.balance_rounded
                          : (s['score'] as num) > (s['opponent_score'] as num)
                              ? Icons.emoji_events_rounded
                              : Icons.flag_outlined,
                      color: rokBone,
                      size: 48),
                  const SizedBox(height: 12),
                  LText(
                      s['score'] == s['opponent_score']
                          ? 'Berabere!'
                          : (s['score'] as num) > (s['opponent_score'] as num)
                              ? 'Kazandın!'
                              : 'Rakibin kazandı',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: rokBone,
                          fontSize: 28,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  LText(
                      'Sen ${s['score']} — ${s['opponent_score']} ${s['opponent']}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: rokBone, fontSize: 20)),
                  const Divider(height: 28, color: Color(0xff686966)),
                  LText(
                      'Rating değişimi: ${s['delta']} · Yeni rating: ${(s['rating'] as num) + (s['delta'] as num)}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: rokBone)),
                  if (s['opponent_delta'] != null)
                    LText(
                        'Rakip rating: ${s['opponent_rating']} → ${(s['opponent_rating'] as num) + (s['opponent_delta'] as num)}',
                        style: const TextStyle(color: rokBone)),
                ]))),
        FilledButton.icon(
            onPressed: _rematch?['status'] == 'pending' &&
                    _rematch?['incoming'] != true
                ? null
                : () => _checkRematch(request: true),
            icon: const Icon(Icons.replay),
            label: LText(_rematch?['incoming'] == true
                ? 'RÖVANŞI KABUL ET'
                : _rematch?['status'] == 'pending'
                    ? 'RAKİBİN YANITI BEKLENİYOR'
                    : 'RÖVANŞ')),
        TextButton(onPressed: _leave, child: const LText('MENÜYE DÖN')),
        const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: LText('TUR ÖZETİ',
                style: TextStyle(color: rokBone, letterSpacing: 1.5))),
        for (final row in (s['history'] as List? ?? []))
          Card(
              color: rokGraphite,
              child: ListTile(
                leading: LText('${row['turn']}',
                    style: const TextStyle(color: rokBone, fontSize: 20)),
                title: LText(
                    ((row['turn'] as int).isOdd == (s['is_a'] == true))
                        ? 'Sen'
                        : s['opponent'].toString(),
                    style: const TextStyle(color: rokBone)),
                subtitle: LText(
                    '${row['seconds'] ?? '—'} sn · ${row['mistakes'] ?? '—'} hata · ${row['reason'] == 'timeout' ? 'Süre doldu' : row['reason'] == 'skip' ? 'Geçildi' : 'Çözüldü'}',
                    style: const TextStyle(color: Color(0xffb9aea5))),
                trailing: LText('${row['points']} puan',
                    style: const TextStyle(color: rokBone)),
              )),
      ]);

  Future<void> _start() async {
    if (AppBackend.currentUser == null && widget.request == null) {
      await Navigator.push(
          context, MaterialPageRoute(builder: (_) => const AuthScreen()));
      if (!mounted || AppBackend.currentUser == null) return;
    }
    setState(() {
      _searching = true;
      _error = null;
    });
    await _sync();
  }

  Future<void> _sync() async {
    if (_busy) return;
    _busy = true;
    try {
      if (_id == null) {
        final result = await _rpc('duel_matchmaking');
        if (!mounted) return;
        _id = result['game_id'] as String?;
        _rating = (result['rating'] as num?)?.toInt() ?? _rating;
      }
      if (_id != null) {
        final result = await _rpc('duel_state', {'p_id': _id});
        if (!mounted) return;
        if (_state?['turn'] != result['turn'] ||
            _state?['step'] != result['step']) {
          _selected = null;
        }
        _state = result;
        _searching = false;
      }
      if (mounted) setState(() => _error = null);
    } catch (_) {
      if (mounted) {
        setState(() => _error =
            'Bağlantı kurulamadı. Havuz ve migration kurulumunu kontrol et; yeniden denenecek.');
      }
    } finally {
      _busy = false;
    }
  }

  Future<void> _move(String action, [String? move]) async {
    if (_busy || _state == null) return;
    setState(() => _busy = true);
    try {
      final result = await _rpc('duel_action', {
        'p_id': _id,
        'p_turn': _state!['turn'],
        'p_step': _state!['step'],
        'p_action': action,
        'p_move': move,
      });
      if (mounted) {
        setState(() {
          _state = result;
          _selected = null;
          _error = result['wrong'] == true
              ? 'Yanlış hamle · Puan katsayısı azaldı.'
              : null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Hamle doğrulanamadı. Yeniden dene.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _tap(String square, c.Chess board) async {
    if (_busy) return;
    final moves = _selected == null
        ? <c.Move>[]
        : board
            .generate_moves({'square': _selected})
            .where((m) => m.toAlgebraic == square)
            .toList();
    if (moves.isEmpty) {
      setState(() =>
          _selected = board.get(square)?.color == board.turn ? square : null);
      return;
    }
    var move = moves.first;
    if (move.promotion != null) {
      final piece = await showDialog<String>(
          context: context,
          builder: (context) => SimpleDialog(
              title: const LText('Terfi'),
              children: ['q', 'r', 'b', 'n']
                  .map((p) => SimpleDialogOption(
                      onPressed: () => Navigator.pop(context, p),
                      child: LText({
                        'q': 'Vezir',
                        'r': 'Kale',
                        'b': 'Fil',
                        'n': 'At'
                      }[p]!)))
                  .toList()));
      if (!mounted || piece == null) return;
      move = moves.firstWhere((m) => m.promotion?.name == piece);
    }
    await _move('move',
        '${move.fromAlgebraic}${move.toAlgebraic}${move.promotion?.name ?? ''}');
  }

  Future<void> _leave() async {
    if (_busy) return;
    if (_id == null && _searching) {
      try {
        await _rpc('duel_matchmaking', {'p_cancel': true});
      } catch (_) {
        if (mounted) {
          setState(() => _error = 'Çıkış doğrulanamadı. Tekrar dene.');
        }
        return;
      }
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget _lobby() => RokScaffold(
        backgroundColor: const Color(0xff32180d),
        body: DecoratedBox(
          decoration: const BoxDecoration(
              image: DecorationImage(
                  image: AssetImage('lib/images/wood/background.png'),
                  fit: BoxFit.cover,
                  colorFilter:
                      ColorFilter.mode(Color(0x40000000), BlendMode.darken))),
          child: SafeArea(
              child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints:
                              BoxConstraints(minHeight: constraints.maxHeight),
                          child: IntrinsicHeight(
                              child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(children: [
                                    Align(
                                        alignment: Alignment.centerLeft,
                                        child: IconButton(
                                            onPressed: _leave,
                                            tooltip: tr(context, 'Kapat'),
                                            icon:
                                                const Icon(Icons.close_rounded),
                                            color: const Color(0xfff3eee7))),
                                    const Spacer(),
                                    const SizedBox(height: 24),
                                    if (_error != null)
                                      const Icon(Icons.cloud_off_outlined,
                                          color: Color(0xfff3eee7), size: 64)
                                    else if (_searching)
                                      const SizedBox.square(
                                          dimension: 62,
                                          child: CircularProgressIndicator(
                                              color: Color(0xfff3eee7),
                                              strokeWidth: 3))
                                    else
                                      const Icon(Icons.bolt_outlined,
                                          color: Color(0xfff3eee7), size: 64),
                                    const SizedBox(height: 30),
                                    LText(
                                        _error != null
                                            ? 'BAĞLANTI KURULAMADI'
                                            : _searching
                                                ? 'RAKİP ARANIYOR'
                                                : 'BULMACA DÜELLOSU',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            color: Color(0xfff3eee7),
                                            fontSize: 23,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 1.8)),
                                    const SizedBox(height: 10),
                                    LText(
                                        _error ??
                                            'Kişi başı 10 bulmaca · 20 tur',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            color: Color(0xffb9aea5),
                                            fontSize: 17)),
                                    const SizedBox(height: 24),
                                    LText('Rekabetçi rating: ${_rating ?? '—'}',
                                        style: const TextStyle(
                                            color: Color(0xfff3eee7),
                                            height: 1.7)),
                                    const SizedBox(height: 8),
                                    const LText(
                                        'Tur başına 30 saniye\nHız puan kazandırır, yanlışlar puanı azaltır.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            color: Color(0xffb9aea5),
                                            height: 1.7)),
                                    const SizedBox(height: 24),
                                    const Spacer(),
                                    OutlinedButton(
                                        onPressed: _searching ? _leave : _start,
                                        style: OutlinedButton.styleFrom(
                                            minimumSize:
                                                const Size.fromHeight(52),
                                            foregroundColor:
                                                const Color(0xfff3eee7),
                                            side: const BorderSide(
                                                color: Color(0x99f3eee7))),
                                        child: LText(_searching
                                            ? 'ARAMAYI İPTAL ET'
                                            : 'RAKİP ARA')),
                                  ]))),
                        ),
                      ))),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final s = _state;
    final finished = s?['status'] == 'finished';
    final board =
        s?['fen'] is String ? c.Chess.fromFEN(s!['fen'] as String) : null;
    return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _leave();
        },
        child: s == null
            ? _lobby()
            : RokScaffold(
                backgroundColor: const Color(0xff202120),
                appBar: AppBar(
                    title: const LText('Bulmaca Düellosu'),
                    backgroundColor: const Color(0xff202120),
                    foregroundColor: Colors.white,
                    leading: IconButton(
                        onPressed: _leave, icon: const Icon(Icons.arrow_back)),
                    actions: [
                      Padding(
                          padding: const EdgeInsets.all(12),
                          child: LText('${s['score']} : ${s['opponent_score']}',
                              style: const TextStyle(fontSize: 20)))
                    ]),
                body: SafeArea(
                    child:
                        ListView(padding: const EdgeInsets.all(16), children: [
                  ...[
                    LText('Rakip: ${s['opponent']}',
                        style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 12),
                    if (finished) ...[
                      _resultDetails(s),
                    ] else ...[
                      LText('Tur ${s['turn']}/20 · ${s['seconds_left']} sn',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 20)),
                      LText(
                          s['my_turn'] == true
                              ? 'Sıra sende · Hata: ${s['mistakes']}'
                              : 'Rakibin bulmacayı çözüyor…',
                          style: const TextStyle(color: Colors.white70)),
                      if (board != null)
                        AspectRatio(
                            aspectRatio: 1,
                            child: GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: 64,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 8),
                                itemBuilder: (_, display) {
                                  final i = board.turn == c.Color.BLACK
                                      ? 63 - display
                                      : display;
                                  final square =
                                      '${'abcdefgh'[i % 8]}${8 - i ~/ 8}';
                                  final piece = board.get(square);
                                  return GestureDetector(
                                      onTap: () => _tap(square, board),
                                      child: ColoredBox(
                                          color: _selected == square
                                              ? const Color(0xffb89454)
                                              : (i ~/ 8 + i % 8).isEven
                                                  ? const Color(0xffd9b77e)
                                                  : const Color(0xff85552f),
                                          child: piece == null
                                              ? const SizedBox()
                                              : Padding(
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
                                                      colorBlendMode: BlendMode
                                                          .modulate))));
                                })),
                      if (s['my_turn'] == true)
                        TextButton(
                            onPressed: _busy ? null : () => _move('skip'),
                            child: const LText('Bu turu geç (0 puan)')),
                      const LText(
                          'Çıkarsan süre işlemeye devam eder. Bu ekrandan maça geri dönebilirsin.',
                          style: TextStyle(color: Colors.white54)),
                    ],
                  ],
                  if (_error != null)
                    LText(_error!,
                        style: const TextStyle(color: Colors.orangeAccent)),
                ])),
              ));
  }
}
