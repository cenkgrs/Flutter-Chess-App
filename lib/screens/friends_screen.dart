import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../backend/friend_repository.dart';
import '../online/time_control.dart';
import 'online_game_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key, this.repository});
  final FriendRepository? repository;
  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  late final _repo = widget.repository ?? FriendRepository();
  final _query = TextEditingController();
  List<Map<String, dynamic>> _friends = [], _results = [];
  List<Map<String, dynamic>> _invitations = [];
  Timer? _timer;
  bool _loading = true, _busy = false, _searching = false;
  String? _error, _searchError;
  int _generation = 0;
  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!_busy &&
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        _load();
      }
    });
  }

  Future<void> _load() async {
    try {
      final rows = await _repo.list();
      final invitations = await _repo.invitations();
      if (mounted) {
        setState(() {
          _friends = rows;
          _invitations = invitations;
          _loading = false;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Arkadaş listesi yüklenemedi. Yenilemeyi dene.';
        });
      }
    }
  }

  Future<void> _search() async {
    final query = _query.text.trim();
    final generation = ++_generation;
    if (query.length < 3) {
      setState(() {
        _searchError = 'En az 3 karakter yaz.';
        _results = [];
      });
      return;
    }
    setState(() {
      _searching = true;
      _searchError = null;
    });
    try {
      final rows = await _repo.search(query);
      if (mounted && generation == _generation) {
        setState(() {
          _results = rows;
          _searchError = rows.isEmpty ? 'Oyuncu bulunamadı.' : null;
        });
      }
    } catch (_) {
      if (mounted && generation == _generation) {
        setState(() => _searchError = 'Arama yapılamadı. Tekrar dene.');
      }
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _searching = false);
      }
    }
  }

  Future<void> _act(String id, String action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _repo.action(id, action);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(action == 'send'
                ? 'Arkadaşlık isteği gönderildi.'
                : action == 'accept'
                    ? 'Arkadaşlık isteği kabul edildi.'
                    : 'İstek kaldırıldı.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('İşlem tamamlanamadı. Tekrar dene.')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _person(Map<String, dynamic> person) {
    final link = _friends.where((f) => f['id'] == person['id']).firstOrNull;
    final accepted = link?['status'] == 'accepted';
    final incoming = link?['incoming'] == true;
    Widget button(String label, String action) => TextButton(
        onPressed: _busy ? null : () => _act(person['id'] as String, action),
        child: Text(label));
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.person_outline),
                  const SizedBox(width: 10),
                  Expanded(child: Text(person['username'] as String)),
                  if (accepted) const Icon(Icons.check_circle_outline)
                ]),
                if (!accepted)
                  Wrap(
                      children: link == null
                          ? [button('İstek gönder', 'send')]
                          : incoming
                              ? [
                                  button('Kabul et', 'accept'),
                                  button('Reddet', 'decline')
                                ]
                              : [button('İsteği geri çek', 'cancel')]),
                if (accepted)
                  TextButton.icon(
                      onPressed:
                          _busy ? null : () => _invite(person['id'] as String),
                      icon: const Icon(Icons.sports_esports_outlined),
                      label: const Text('Oyuna davet et')),
              ],
            )));
  }

  Future<void> _invite(String id) async {
    final control = await showModalBottomSheet<TimeControl>(
        context: context,
        builder: (context) => SafeArea(
                child: ListView(children: [
              const ListTile(title: Text('Oyun süresi seç')),
              for (final c in TimeControl.presets)
                ListTile(
                    title: Text('${c.pool.label} · ${c.label}'),
                    onTap: () => Navigator.pop(context, c)),
            ])));
    if (control == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await _repo.invite(id, control);
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Davet gönderilemedi. Tekrar dene.')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _respond(Map<String, dynamic> invite, bool accept) async {
    setState(() => _busy = true);
    try {
      final game = await _repo.respond(invite['id'] as String, accept);
      if (!mounted) return;
      if (game != null) {
        await Navigator.push(context,
            MaterialPageRoute(builder: (_) => OnlineGameScreen(gameId: game)));
      }
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Davet açılamadı. Süresi dolmuş olabilir veya oyunculardan biri maçta.')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Theme(
        data: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: const Color(0xff202120),
            colorScheme: const ColorScheme.dark(
                primary: Color(0xfff3eee7), surface: Color(0xff2b2c2b)),
            appBarTheme: const AppBarTheme(backgroundColor: Color(0xff202120))),
        child: Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              foregroundColor: const Color(0xfff3eee7),
              systemOverlayStyle: SystemUiOverlayStyle.light
                  .copyWith(statusBarColor: Colors.transparent),
              title: const Text('ARKADAŞLAR',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.8)),
              actions: [
                IconButton(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Yenile')
              ]),
          body: DecoratedBox(
              decoration: const BoxDecoration(
                  image: DecorationImage(
                image: AssetImage('lib/images/wood/background.png'),
                fit: BoxFit.cover,
                colorFilter:
                    ColorFilter.mode(Color(0x40000000), BlendMode.darken),
              )),
              child: SafeArea(
                  child: Padding(
                      padding: const EdgeInsets.only(top: kToolbarHeight),
                      child: RefreshIndicator(
                          onRefresh: _load,
                          child: ListView(
                              padding: const EdgeInsets.all(20),
                              children: [
                                for (final invite in _invitations)
                                  Card(
                                      child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                    '${invite['username']} · ${invite['minutes']}+${invite['increment']}'),
                                                if (invite['status'] ==
                                                    'accepted')
                                                  TextButton(
                                                      onPressed: () => Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                              builder: (_) => OnlineGameScreen(
                                                                  gameId: invite[
                                                                          'game_id']
                                                                      as String))),
                                                      child: const Text(
                                                          'Maça katıl'))
                                                else if (invite['incoming'] ==
                                                    true)
                                                  Wrap(children: [
                                                    TextButton(
                                                        onPressed: _busy
                                                            ? null
                                                            : () => _respond(
                                                                invite, true),
                                                        child: const Text(
                                                            'Daveti kabul et')),
                                                    TextButton(
                                                        onPressed: _busy
                                                            ? null
                                                            : () => _respond(
                                                                invite, false),
                                                        child: const Text(
                                                            'Daveti reddet')),
                                                  ])
                                                else
                                                  const Text(
                                                      'Davet gönderildi · 5 dakika geçerli'),
                                              ]))),
                                TextField(
                                    controller: _query,
                                    maxLength: 20,
                                    onSubmitted: (_) => _search(),
                                    decoration: InputDecoration(
                                        labelText: 'Kullanıcı adı ara',
                                        hintText: 'En az 3 karakter',
                                        suffixIcon: IconButton(
                                            onPressed:
                                                _searching ? null : _search,
                                            tooltip: 'Ara',
                                            icon: const Icon(Icons.search)))),
                                if (_searching) const LinearProgressIndicator(),
                                if (_searchError != null) Text(_searchError!),
                                ..._results.map(_person),
                                const SizedBox(height: 24),
                                if (_loading)
                                  const Center(
                                      child: CircularProgressIndicator()),
                                if (_error != null) Text(_error!),
                                for (final section in [
                                  ('GELEN İSTEKLER', 'incoming'),
                                  ('ARKADAŞLARIM', 'accepted'),
                                  ('GÖNDERİLEN İSTEKLER', 'outgoing')
                                ]) ...[
                                  Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      child: Text(section.$1,
                                          style: const TextStyle(
                                              letterSpacing: 1.5))),
                                  ..._friends
                                      .where((f) => section.$2 == 'accepted'
                                          ? f['status'] == 'accepted'
                                          : f['status'] == 'pending' &&
                                              f['incoming'] ==
                                                  (section.$2 == 'incoming'))
                                      .map(_person),
                                ],
                                if (!_loading &&
                                    _error == null &&
                                    _friends.isEmpty)
                                  const Text(
                                      'Henüz arkadaşın veya bekleyen isteğin yok.'),
                              ]))))),
        ),
      );
}

/// Lightweight in-app notification. No device push service is required.
class FriendRequestLabel extends StatefulWidget {
  const FriendRequestLabel({super.key});
  @override
  State<FriendRequestLabel> createState() => _FriendRequestLabelState();
}

class _FriendRequestLabelState extends State<FriendRequestLabel> {
  Timer? _timer;
  int _count = 0;
  int _invites = 0;
  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _refresh());
  }

  Future<void> _refresh() async {
    if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
      return;
    }
    try {
      final rows = await FriendRepository().list();
      final invitations = await FriendRepository().invitations();
      if (mounted) {
        setState(() {
          _invites = invitations
              .where((r) => r['incoming'] == true && r['status'] == 'pending')
              .length;
          _count = rows
              .where((r) => r['status'] == 'pending' && r['incoming'] == true)
              .length;
        });
      }
    } catch (_) {
      /* Keep the menu usable during temporary connection failures. */
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Text(
      _invites > 0
          ? 'Arkadaşlar · $_invites maç daveti'
          : _count > 0
              ? 'Arkadaşlar · $_count yeni istek'
              : 'Arkadaşlar',
      style: const TextStyle(color: Color(0xfff3eee7)));
}
