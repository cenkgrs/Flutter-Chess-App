import 'package:flutter/material.dart';

import '../backend/app_backend.dart';
import '../backend/friend_repository.dart';
import '../l10n/app_language.dart';
import '../online/time_control.dart';
import 'home_menu_screen.dart' show TimeControlOptions;
import '../widgets/rok_style.dart';

/// The top of each rating pool, and a way to play the people on it.
///
/// A pool is its own board: an Elo earned at bullet says nothing about
/// classical, and one mixed table would flatter whoever plays fastest.
/// Challenging still runs through friendship — a name on a public board
/// is not consent to be invited by a stranger.
class ChessLeaderboardScreen extends StatefulWidget {
  const ChessLeaderboardScreen({super.key, this.loader, this.repository});

  final Future<Map<String, dynamic>> Function(String pool)? loader;
  final FriendRepository? repository;

  @override
  State<ChessLeaderboardScreen> createState() => _ChessLeaderboardScreenState();
}

const _bone = Color(0xfff3eee7);
const _muted = Color(0xffb9aea5);

class _ChessLeaderboardScreenState extends State<ChessLeaderboardScreen> {
  late final _repo = widget.repository ?? FriendRepository();
  SpeedPool _pool = SpeedPool.blitz;
  late Future<Map<String, dynamic>> _data;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _data = _load();
  }

  Future<Map<String, dynamic>> _load() async => widget.loader != null
      ? await widget.loader!(_pool.databaseName)
      : Map<String, dynamic>.from(await AppBackend.client.rpc(
          'chess_leaderboard',
          params: {'p_pool': _pool.databaseName}) as Map);

  Future<void> _refresh() async {
    setState(() => _data = _load());
    try {
      await _data;
    } catch (_) {/* FutureBuilder displays the error. */}
  }

  void _choose(SpeedPool pool) {
    if (pool == _pool) return;
    setState(() {
      _pool = pool;
      _data = _load();
    });
  }

  Future<void> _addFriend(Map row) async {
    setState(() => _busy = true);
    try {
      await _repo.action(row['user_id'] as String, 'send');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: LText('Arkadaşlık isteği gönderildi.')));
      await _refresh();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: LText('İstek gönderilemedi. Tekrar dene.')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _challenge(Map row) async {
    final control = await showModalBottomSheet<TimeControl>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (sheet) => RokSheet(
              icon: Icons.timer_outlined,
              title: 'SÜRE SEÇ',
              note: '${row['username']}',
              // Every clock, not just this board's: the board is where you
              // found the player, not a promise about what you may play.
              child: TimeControlOptions(
                  onSelected: (control) => Navigator.pop(sheet, control)),
            ));
    if (control == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await _repo.invite(row['user_id'] as String, control);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: LText('Davet gönderildi.')));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: LText('Davet gönderilemedi. Tekrar dene.')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _action(Map row) => switch (row['friendship']) {
        'self' => const SizedBox.shrink(),
        'accepted' => _RowButton(
            key: ValueKey('challenge-${row['user_id']}'),
            icon: Icons.sports_esports_outlined,
            label: 'Davet et',
            filled: true,
            onPressed: _busy ? null : () => _challenge(row),
          ),
        'pending' => const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: LText('Beklemede',
                style: TextStyle(color: _muted, fontSize: 12.5)),
          ),
        _ => _RowButton(
            key: ValueKey('befriend-${row['user_id']}'),
            icon: Icons.person_add_alt_1_outlined,
            label: 'Arkadaş ekle',
            onPressed: _busy ? null : () => _addFriend(row),
          ),
      };

  /// A row carried the board's only real content and looked like a stock
  /// list tile over flat grey. It is a card of the same wood as the rest of
  /// the app now: the place reads as a medal, the rating as the chip it is
  /// everywhere else, and your own row is the one lit in brass.
  Widget _entry(Map row, {bool own = false}) {
    final place = row['place'] as int? ?? 0;
    final medal = switch (place) {
      1 => const Color(0xffe2b75f),
      2 => const Color(0xffcdc7bd),
      3 => const Color(0xffc08457),
      _ => _muted,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: own ? const Color(0x77332113) : const Color(0x55241a12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: own ? const Color(0xffd9b77e) : const Color(0xff6d6356),
            width: own ? 1.4 : 1),
      ),
      child: Row(children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0x44000000),
            border: Border.all(color: medal.withValues(alpha: 0.7)),
          ),
          child: Text('$place',
              style: TextStyle(
                  color: medal, fontSize: 15, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Flexible(
                    child: Text('${row['username']}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: _bone,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                  ),
                  if (own) ...[
                    const SizedBox(width: 7),
                    const LText('SEN',
                        style: TextStyle(
                            color: Color(0xffd9b77e),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.4)),
                  ],
                ]),
                const SizedBox(height: 3),
                LText('${row['games_played']} oyun',
                    style: const TextStyle(color: _muted, fontSize: 12.5)),
              ]),
        ),
        const SizedBox(width: 8),
        RokStatChip(
            icon: Icons.military_tech_outlined, value: '${row['rating']}'),
        if (!own) ...[
          const SizedBox(width: 6),
          _action(row),
        ],
      ]),
    );
  }

  @override
  Widget build(BuildContext context) => RokScaffold(
        appBar: AppBar(
            title: const LText('Oyuncu sıralaması'),
            actions: [
              IconButton(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh),
                  tooltip: tr(context, 'Yenile'))
            ]),
        body: Column(children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Row(
                children: SpeedPool.values
                    .map((pool) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            key: ValueKey('pool-${pool.databaseName}'),
                            label: LText(pool.label),
                            selected: pool == _pool,
                            onSelected: (_) => _choose(pool),
                          ),
                        ))
                    .toList()),
          ),
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _data,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(
                      child:
                          CircularProgressIndicator(color: _bone));
                }
                if (snapshot.hasError) {
                  return Center(
                      child: TextButton(
                          onPressed: _refresh,
                          child: const LText('Sıralama yüklenemedi. Tekrar dene',
                              style: TextStyle(color: _bone))));
                }
                final rows = snapshot.data!['leaders'] as List? ?? const [];
                final me = snapshot.data!['me'] as Map?;
                return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      children: [
                        LText('${_pool.label} · İLK 100',
                            style: const TextStyle(
                                color: _muted,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.6)),
                        const SizedBox(height: 16),
                        if (me != null)
                          _entry(me, own: true)
                        else
                          const LText(
                              'Bu sürede dereceli bir maç oyna, sıralamaya katıl.',
                              style: TextStyle(color: _bone)),
                        const Divider(height: 28, color: Color(0x44d8cec5)),
                        if (rows.isEmpty)
                          const LText('Henüz sıralamada oyuncu yok.',
                              style: TextStyle(color: Color(0xfff3eee7))),
                        // Your own standing is the card at the top; the
                        // board would otherwise print you twice.
                        for (final row in rows)
                          if ((row as Map)['friendship'] != 'self')
                            _entry(row),
                      ],
                    ));
              },
            ),
          ),
        ]),
      );
}

/// The one control a row carries, small enough to sit beside a rating.
class _RowButton extends StatelessWidget {
  const _RowButton(
      {super.key,
      required this.icon,
      required this.label,
      required this.onPressed,
      this.filled = false});

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tr(context, label),
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon, size: 19),
          visualDensity: VisualDensity.compact,
          style: IconButton.styleFrom(
            foregroundColor: filled ? const Color(0xff241a12) : _bone,
            backgroundColor:
                filled ? const Color(0xffd9b77e) : const Color(0x33000000),
            side: BorderSide(
                color: filled
                    ? const Color(0xffd9b77e)
                    : const Color(0xff6d6356)),
          ),
        ),
      );
}
