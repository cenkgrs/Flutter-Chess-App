import 'package:flutter/material.dart';

import '../backend/app_backend.dart';
import '../backend/friend_repository.dart';
import '../l10n/app_language.dart';
import '../online/time_control.dart';
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
        builder: (sheet) => SafeArea(
                child: ListView(children: [
              ListTile(title: LText('${row['username']} · Oyun süresi seç')),
              for (final c in TimeControl.presets.where((c) => c.pool == _pool))
                ListTile(
                    title: LText('${c.pool.label} · ${c.label}'),
                    onTap: () => Navigator.pop(sheet, c)),
            ])));
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
        'accepted' => TextButton(
            key: ValueKey('challenge-${row['user_id']}'),
            onPressed: _busy ? null : () => _challenge(row),
            child: const LText('Davet et'),
          ),
        'pending' => const LText('Beklemede',
            style: TextStyle(color: Color(0xffb9aea5))),
        _ => TextButton(
            key: ValueKey('befriend-${row['user_id']}'),
            onPressed: _busy ? null : () => _addFriend(row),
            child: const LText('Arkadaş ekle'),
          ),
      };

  Widget _entry(Map row, {bool own = false}) => Card(
        color: own ? const Color(0xff454645) : const Color(0xff2b2c2b),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: ListTile(
          textColor: const Color(0xfff3eee7),
          leading: LText('#${row['place']}',
              style: const TextStyle(fontSize: 20, color: Color(0xfff3eee7))),
          title: LText('${row['username']}${own ? ' · Sen' : ''}',
              maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: LText('${row['rating']} · ${row['games_played']} oyun',
              style: const TextStyle(color: Color(0xffb9aea5))),
          trailing: own ? null : _action(row),
        ),
      );

  @override
  Widget build(BuildContext context) => RokScaffold(
        backgroundColor: const Color(0xff202120),
        appBar: AppBar(
            title: const LText('Oyuncu sıralaması'),
            backgroundColor: const Color(0xff202120),
            foregroundColor: const Color(0xfff3eee7),
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
                          CircularProgressIndicator(color: Color(0xfff3eee7)));
                }
                if (snapshot.hasError) {
                  return Center(
                      child: TextButton(
                          onPressed: _refresh,
                          child: const LText('Sıralama yüklenemedi. Tekrar dene',
                              style: TextStyle(color: Color(0xfff3eee7)))));
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
                                color: Color(0xffb9aea5), letterSpacing: 1.5)),
                        const SizedBox(height: 16),
                        if (me != null)
                          _entry(me, own: true)
                        else
                          const LText(
                              'Bu sürede dereceli bir maç oyna, sıralamaya katıl.',
                              style: TextStyle(color: Color(0xfff3eee7))),
                        const Divider(height: 32, color: Color(0xff454645)),
                        if (rows.isEmpty)
                          const LText('Henüz sıralamada oyuncu yok.',
                              style: TextStyle(color: Color(0xfff3eee7))),
                        for (final row in rows) _entry(row as Map),
                      ],
                    ));
              },
            ),
          ),
        ]),
      );
}
