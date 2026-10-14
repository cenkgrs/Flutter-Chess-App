import '../widgets/rok_style.dart';
import 'package:chess/chess.dart' as c;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../backend/app_backend.dart';
import '../backend/game_repository.dart';
import '../online/game_result.dart';
import 'friends_screen.dart';
import '../prototype/play_screen.dart';
import '../prototype/stockfish_engine.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const bone = Color(0xfff3eee7);
  static const mutedBone = Color(0xffb9aea5);

  @override
  Widget build(BuildContext context) {
    final user = AppBackend.currentUser;
    final username = user?.userMetadata?['username']?.toString().trim();
    final displayName =
        username == null || username.isEmpty ? 'ROK Oyuncusu' : username;

    return RokScaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('PROFİLİM',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 1.8)),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light
            .copyWith(statusBarColor: Colors.transparent),
        foregroundColor: bone,
      ),
      backgroundColor: const Color(0xff3b1e0f),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('lib/images/wood/background.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Color(0x4d000000),
              BlendMode.darken,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: kToolbarHeight),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xe6202120),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xff686966)),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 31,
                        backgroundColor: Color(0xff4b391f),
                        foregroundColor: bone,
                        child: Icon(Icons.person_outline_rounded, size: 34),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: bone,
                                    fontSize: 21,
                                    fontWeight: FontWeight.w700)),
                            if (user?.email != null) ...[
                              const SizedBox(height: 5),
                              Text(user!.email!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: mutedBone, fontSize: 14)),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                const Text('HESAP',
                    style: TextStyle(
                        color: mutedBone,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.6)),
                const SizedBox(height: 10),
                _ProfileLink(
                  icon: Icons.history_rounded,
                  title: 'Son Maçlar',
                  subtitle: 'Maç geçmişini ve hamlelerini incele',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const RecentGamesScreen()),
                  ),
                ),
                const SizedBox(height: 12),
                _ProfileLink(
                  icon: Icons.people_outline_rounded,
                  title: 'Arkadaşlar',
                  subtitle: 'Arkadaşlarını, istekleri ve davetleri yönet',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FriendsScreen()),
                  ),
                ),
                const SizedBox(height: 12),
                _ProfileLink(
                  icon: Icons.description_outlined,
                  title: 'Açık kaynak lisansları',
                  subtitle: 'Stockfish ve kullanılan kütüphaneler',
                  onTap: () =>
                      showLicensePage(context: context, applicationName: 'ROK'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileLink extends StatelessWidget {
  const _ProfileLink({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: const Color(0xe6202120),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xff686966), width: .8),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: onTap,
          minVerticalPadding: 16,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          leading: Icon(icon, color: ProfileScreen.bone, size: 28),
          title: Text(title,
              style: const TextStyle(
                  color: ProfileScreen.bone,
                  fontWeight: FontWeight.w600,
                  fontSize: 17)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(subtitle,
                style: const TextStyle(
                    color: ProfileScreen.mutedBone, height: 1.35)),
          ),
          trailing: const Icon(Icons.chevron_right_rounded,
              color: ProfileScreen.mutedBone),
        ),
      );
}

class RecentGamesScreen extends StatelessWidget {
  const RecentGamesScreen({super.key});

  @override
  Widget build(BuildContext context) => RokScaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
            title: const Text('SON MAÇLAR',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.8)),
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            systemOverlayStyle: SystemUiOverlayStyle.light
                .copyWith(statusBarColor: Colors.transparent),
            foregroundColor: const Color(0xfff3eee7)),
        backgroundColor: const Color(0xff3b1e0f),
        body: DecoratedBox(
            decoration: const BoxDecoration(
                image: DecorationImage(
                    image: AssetImage('lib/images/wood/background.png'),
                    fit: BoxFit.cover,
                    colorFilter:
                        ColorFilter.mode(Color(0x40000000), BlendMode.darken))),
            child: SafeArea(
                child: Padding(
                    padding: const EdgeInsets.only(top: kToolbarHeight),
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: GameRepository().recentGames(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return const Center(
                              child: Text('Maç geçmişi yüklenemedi.',
                                  style: TextStyle(color: Color(0xfff3eee7))));
                        }
                        if (!snapshot.hasData) {
                          return const Center(
                              child: CircularProgressIndicator(
                                  color: Color(0xfff3eee7)));
                        }
                        if (snapshot.data!.isEmpty) {
                          return const Center(
                              child: Text('Henüz tamamlanmış maç yok.',
                                  style: TextStyle(color: Color(0xfff3eee7))));
                        }
                        return ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: snapshot.data!.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final game = snapshot.data![index];
                              final outcome = gameOutcomeFor(
                                  game, AppBackend.currentUser!.id);
                              final reason =
                                  resultReasonLabel(game['result_reason']);
                              final opponent = game[
                                  game['white_id'] == AppBackend.currentUser!.id
                                      ? 'black_profile'
                                      : 'white_profile'] as Map?;
                              return Card(
                                  margin: EdgeInsets.zero,
                                  color: const Color(0xf2202120),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      side: const BorderSide(
                                          color: Color(0xff686966), width: .8)),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    textColor: const Color(0xfff3eee7),
                                    iconColor: const Color(0xfff3eee7),
                                    leading: _OutcomeIcon(outcome: outcome),
                                    title: Text(
                                        opponent?['username']?.toString() ??
                                            'Oyuncu',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600)),
                                    subtitle: Text(
                                        [
                                          '${game['pool'].toString().toUpperCase()} · ${game['initial_minutes']}+${game['increment_seconds']}',
                                          outcomeLabel(outcome),
                                          if (reason.isNotEmpty) reason,
                                        ].join(' · '),
                                        style: const TextStyle(
                                            color: Color(0xffb9aea5),
                                            height: 1.6)),
                                    trailing: const Icon(Icons.chevron_right),
                                    onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                GameReviewScreen(game: game))),
                                  ));
                            });
                      },
                    )))),
      );
}

class _OutcomeIcon extends StatelessWidget {
  const _OutcomeIcon({required this.outcome});

  final PlayerGameOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final (icon, foreground, background) = switch (outcome) {
      PlayerGameOutcome.win => (
          Icons.emoji_events_rounded,
          const Color(0xfff4d28d),
          const Color(0xff4b391f),
        ),
      PlayerGameOutcome.loss => (
          Icons.close_rounded,
          const Color(0xffffc4b8),
          const Color(0xff4b2723),
        ),
      PlayerGameOutcome.draw => (
          Icons.balance_rounded,
          const Color(0xffdedbd6),
          const Color(0xff343536),
        ),
      _ => (
          Icons.horizontal_rule_rounded,
          const Color(0xffdedbd6),
          const Color(0xff343536),
        ),
    };
    return CircleAvatar(
      backgroundColor: background,
      foregroundColor: foreground,
      child: Icon(icon),
    );
  }
}

class GameReviewScreen extends StatefulWidget {
  const GameReviewScreen(
      {super.key, required this.game, this.localMoves, this.initialFen});
  final Map<String, dynamic> game;
  final List<Map<String, dynamic>>? localMoves;
  final String? initialFen;
  @override
  State<GameReviewScreen> createState() => _GameReviewScreenState();
}

class _GameReviewScreenState extends State<GameReviewScreen> {
  List<Map<String, dynamic>>? _moves;
  int _index = 0;
  bool _analyzing = false;
  String? _error;
  final Map<int, String> _qualities = {};
  int _analysisGeneration = 0;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final moves = widget.localMoves ??
          await GameRepository().gameMoves(widget.game['id'] as String);
      if (mounted) {
        setState(() {
          _moves = moves;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Maç yüklenemedi. Tekrar dene.');
    }
  }

  c.Chess get _start => widget.initialFen == null
      ? c.Chess()
      : c.Chess.fromFEN(widget.initialFen!);

  Future<void> _analyze() async {
    final ticket = ++_analysisGeneration;
    setState(() {
      _analyzing = true;
      _error = null;
      _qualities.clear();
    });
    var position = _start;
    try {
      var before = await DeviceEngine.instance.evaluate(position.fen);
      for (var i = 0; i < _moves!.length; i++) {
        if (!mounted || ticket != _analysisGeneration) return;
        final san = _moves![i]['san'] as String;
        if (!position.move(san)) throw StateError('Eksik hamle geçmişi');
        final played = position.history.last.move;
        final uci =
            '${played.fromAlgebraic}${played.toAlgebraic}${played.promotion?.name ?? ''}';
        final after = position.game_over
            ? EngineEvaluation(null, 0, position.in_checkmate ? -1 : null)
            : await DeviceEngine.instance.evaluate(position.fen);
        if (!mounted || ticket != _analysisGeneration) return;
        if ((before.cp == null && before.mate == null) ||
            (after.cp == null && after.mate == null)) {
          throw StateError('Motor değerlendirmesi alınamadı');
        }
        final loss = (before.score + after.score).clamp(0, 200000);
        setState(
            () => _qualities[i] = moveQuality(loss, best: before.move == uci));
        before = after;
      }
    } catch (_) {
      if (mounted && ticket == _analysisGeneration) {
        setState(() => _error = 'Analiz tamamlanamadı. Tekrar deneyebilirsin.');
      }
    } finally {
      if (mounted && ticket == _analysisGeneration) {
        setState(() => _analyzing = false);
      }
    }
  }

  @override
  void dispose() {
    _analysisGeneration++;
    super.dispose();
  }

  c.Chess get _position => _index == 0
      ? _start
      : c.Chess.fromFEN(_moves![_index - 1]['fen_after'] as String);

  @override
  Widget build(BuildContext context) => RokScaffold(
        appBar: AppBar(
            title: const Text('Maç inceleme'),
            backgroundColor: const Color(0xff202120),
            foregroundColor: const Color(0xfff3eee7)),
        backgroundColor: const Color(0xff3b1e0f),
        body: _moves == null && _error != null
            ? Center(child: TextButton(onPressed: _load, child: Text(_error!)))
            : _moves == null
                ? const Center(child: CircularProgressIndicator())
                : Column(children: [
                    Flexible(
                        child: AspectRatio(
                            aspectRatio: 1,
                            child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: GridView.builder(
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: 64,
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 8),
                                    itemBuilder: (context, i) {
                                      final file = i % 8, rank = 8 - i ~/ 8;
                                      final piece = _position
                                          .get('${'abcdefgh'[file]}$rank');
                                      return ColoredBox(
                                          color: (i ~/ 8 + file).isEven
                                              ? const Color(0xffd9b77e)
                                              : const Color(0xff85552f),
                                          child: piece == null
                                              ? const SizedBox()
                                              : Image.asset(
                                                  'lib/images/wood/${const {
                                                    'p': 'pawn',
                                                    'r': 'rook',
                                                    'n': 'knight',
                                                    'b': 'bishop',
                                                    'q': 'queen',
                                                    'k': 'king'
                                                  }[piece.type.name]}.png',
                                                  color: piece.color ==
                                                          c.Color.WHITE
                                                      ? const Color(0xfffff5df)
                                                      : const Color(0xff48291c),
                                                  colorBlendMode:
                                                      BlendMode.modulate));
                                    })))),
                    Text(
                        _index == 0
                            ? 'Başlangıç konumu'
                            : '$_index. ${_moves![_index - 1]['san']}',
                        style: const TextStyle(
                            color: Color(0xfff3eee7), fontSize: 17)),
                    const SizedBox(height: 12),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      IconButton(
                          onPressed: _index == 0
                              ? null
                              : () => setState(() => _index = 0),
                          icon: const Icon(Icons.first_page),
                          color: Colors.white),
                      IconButton(
                          onPressed: _index == 0
                              ? null
                              : () => setState(() => _index--),
                          icon: const Icon(Icons.chevron_left),
                          color: Colors.white),
                      Text('$_index / ${_moves!.length}',
                          style: const TextStyle(color: Colors.white)),
                      IconButton(
                          onPressed: _index == _moves!.length
                              ? null
                              : () => setState(() => _index++),
                          icon: const Icon(Icons.chevron_right),
                          color: Colors.white),
                      IconButton(
                          onPressed: _index == _moves!.length
                              ? null
                              : () => setState(() => _index = _moves!.length),
                          icon: const Icon(Icons.last_page),
                          color: Colors.white),
                    ]),
                    Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        children: [
                          FilledButton.icon(
                              onPressed: _analyzing || _moves!.isEmpty
                                  ? null
                                  : _analyze,
                              icon: const Icon(Icons.analytics_outlined),
                              label: Text(_analyzing
                                  ? 'Analiz ${_qualities.length}/${_moves!.length}'
                                  : 'Motor analizi')),
                          TextButton(
                              onPressed: _analyzing || _position.game_over
                                  ? null
                                  : () {
                                      PlayScreen.launch(context,
                                          fen: _position.fen);
                                    },
                              child:
                                  const Text('Buradan bilgisayarla devam et')),
                        ]),
                    if (_analyzing) const LinearProgressIndicator(),
                    if (_error != null) Text(_error!),
                    if (_qualities.isNotEmpty)
                      Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                              ['Beyaz', 'Siyah'].asMap().entries.map((side) {
                                final firstWhite = _start.turn == c.Color.WHITE;
                                final labels = _qualities.entries
                                    .where((e) =>
                                        (e.key + (firstWhite ? 0 : 1)) % 2 ==
                                        side.key)
                                    .map((e) => e.value)
                                    .toList();
                                return '${side.value}: ${[
                                  'En iyi',
                                  'İyi',
                                  'İsabetsizlik',
                                  'Hata',
                                  'Büyük hata'
                                ].map((q) => '$q ${labels.where((v) => v == q).length}').join(' · ')}';
                              }).join('\n'),
                              style: const TextStyle(fontSize: 11))),
                    const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                            'Kısa motor analizi tahminidir. “En iyi” motorun ilk tercihidir; parlak hamle/feda tespiti değildir.',
                            style: TextStyle(fontSize: 10))),
                    Expanded(
                        child: ListView.builder(
                            itemCount: _moves!.length,
                            itemBuilder: (_, i) => ListTile(
                                selected: _index == i + 1,
                                title: Text('${i + 1}. ${_moves![i]['san']}',
                                    style:
                                        const TextStyle(color: Colors.white)),
                                trailing: Text(_qualities[i] ?? ''),
                                onTap: () => setState(() => _index = i + 1)))),
                  ]),
      );
}
