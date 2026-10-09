import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../backend/game_repository.dart';
import '../online/time_control.dart';
import 'online_game_screen.dart';

class FriendRoomScreen extends StatefulWidget {
  const FriendRoomScreen({super.key});
  @override
  State<FriendRoomScreen> createState() => _FriendRoomScreenState();
}

class _FriendRoomScreenState extends State<FriendRoomScreen> {
  final _repo = GameRepository();
  final _code = TextEditingController();
  TimeControl _control =
      TimeControl.presets.firstWhere((x) => x.label == '10+0');
  String? _createdCode;
  String? _error;
  bool _busy = false;
  Timer? _poller;

  Future<void> _create() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final code = await _repo.createPrivateRoom(_control);
      if (!mounted) return;
      setState(() {
        _createdCode = code;
        _busy = false;
      });
      _poller = Timer.periodic(const Duration(seconds: 2), (_) async {
        final game = await _repo.findPrivateGame(code);
        if (game != null && mounted) _open(game);
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Oda oluşturulamadı.';
        });
      }
    }
  }

  Future<void> _join() async {
    if (_code.text.trim().length != 6) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      _open(await _repo.joinPrivateRoom(_code.text));
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Kod geçersiz veya odanın süresi dolmuş.';
        });
      }
    }
  }

  void _open(String id) {
    _poller?.cancel();
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => OnlineGameScreen(gameId: id)));
  }

  @override
  void dispose() {
    _poller?.cancel();
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xff32180d),
        appBar: AppBar(
            title: const Text('Arkadaşla oyna'),
            backgroundColor: const Color(0xff202120),
            foregroundColor: const Color(0xfff3eee7)),
        body: DecoratedBox(
          decoration: const BoxDecoration(
              image: DecorationImage(
                  image: AssetImage('lib/images/wood/background.png'),
                  fit: BoxFit.cover,
                  colorFilter:
                      ColorFilter.mode(Color(0x44000000), BlendMode.darken))),
          child: ListView(padding: const EdgeInsets.all(22), children: [
            _card(
                'ODA KUR',
                Column(children: [
                  DropdownButtonFormField<TimeControl>(
                      initialValue: _control,
                      decoration: const InputDecoration(labelText: 'Süre'),
                      items: TimeControl.presets
                          .map((x) => DropdownMenuItem(
                              value: x,
                              child: Text('${x.pool.label} · ${x.label}')))
                          .toList(),
                      onChanged: (x) => setState(() => _control = x!)),
                  const SizedBox(height: 16),
                  if (_createdCode == null)
                    FilledButton(
                        onPressed: _busy ? null : _create,
                        child: const Text('DAVET KODU OLUŞTUR'))
                  else ...[
                    const Text('DAVET KODUN',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    SelectableText(_createdCode!,
                        style: const TextStyle(
                            fontSize: 34,
                            letterSpacing: 6,
                            fontWeight: FontWeight.w700)),
                    TextButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _createdCode!));
                        },
                        icon: const Icon(Icons.copy),
                        label: const Text('Kodu kopyala')),
                    const Text('Arkadaşın katıldığında oyun otomatik açılır.'),
                  ],
                ])),
            const SizedBox(height: 18),
            _card(
                'KODLA KATIL',
                Column(children: [
                  TextField(
                      controller: _code,
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 6,
                      decoration: const InputDecoration(
                          labelText: '6 haneli davet kodu',
                          prefixIcon: Icon(Icons.key))),
                  FilledButton(
                      onPressed: _busy ? null : _join,
                      child: const Text('ODAYA KATIL')),
                ])),
            if (_error != null)
              Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Text(_error!,
                      style: const TextStyle(color: Color(0xffffd0c8)))),
          ]),
        ),
      );

  Widget _card(String title, Widget child) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: const Color(0xf2f3eee7),
            borderRadius: BorderRadius.circular(15)),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2)),
          const SizedBox(height: 18),
          child
        ]),
      );
}
