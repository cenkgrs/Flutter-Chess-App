import 'dart:async';

import 'package:flutter/material.dart';

import '../backend/game_repository.dart';
import '../online/time_control.dart';
import 'online_game_screen.dart';

class MatchmakingScreen extends StatefulWidget {
  const MatchmakingScreen({super.key, required this.control});

  final TimeControl control;

  @override
  State<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends State<MatchmakingScreen> {
  final _games = GameRepository();
  Timer? _poller;
  String? _gameId;
  String? _error;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    try {
      final result = await _games.joinQueue(widget.control);
      if (!mounted) return;
      if (result.gameId != null) {
        _openGame(result.gameId!);
        return;
      }
      _poller = Timer.periodic(const Duration(seconds: 2), (_) => _poll());
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Eşleştirme servisine bağlanılamadı.');
      }
    }
  }

  Future<void> _poll() async {
    try {
      final gameId = await _games.findActiveGame();
      if (!mounted || gameId == null) return;
      _poller?.cancel();
      _openGame(gameId);
    } catch (_) {
      // Geçici bağlantı kesintilerinde kuyrukta kal ve yeniden dene.
    }
  }

  Future<void> _openGame(String gameId) async {
    if (!mounted || _gameId != null) return;
    setState(() => _gameId = gameId);
    await Navigator.pushReplacement<void, void>(
      context,
      MaterialPageRoute(builder: (_) => OnlineGameScreen(gameId: gameId)),
    );
  }

  Future<void> _leave() async {
    if (_leaving) return;
    setState(() => _leaving = true);
    _poller?.cancel();
    try {
      if (_gameId == null) await _games.leaveQueue();
    } finally {
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _poller?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _leave();
        },
        child: Scaffold(
          backgroundColor: const Color(0xff32180d),
          body: DecoratedBox(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('lib/images/wood/background.png'),
                fit: BoxFit.cover,
                colorFilter:
                    ColorFilter.mode(Color(0x40000000), BlendMode.darken),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: _leave,
                        icon: const Icon(Icons.close_rounded),
                        color: const Color(0xfff3eee7),
                      ),
                    ),
                    const Spacer(),
                    if (_error != null)
                      const Icon(Icons.cloud_off_outlined,
                          color: Color(0xfff3eee7), size: 64)
                    else if (_gameId != null)
                      const Icon(Icons.handshake_outlined,
                          color: Color(0xfff3eee7), size: 70)
                    else
                      const SizedBox.square(
                        dimension: 62,
                        child: CircularProgressIndicator(
                          color: Color(0xfff3eee7),
                          strokeWidth: 3,
                        ),
                      ),
                    const SizedBox(height: 30),
                    Text(
                      _error != null
                          ? 'BAĞLANTI KURULAMADI'
                          : _gameId != null
                              ? 'RAKİP BULUNDU'
                              : 'RAKİP ARANIYOR',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xfff3eee7),
                        fontSize: 23,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.8,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _error ??
                          '${widget.control.pool.label} · ${widget.control.label}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xffb9aea5),
                        fontSize: 17,
                      ),
                    ),
                    if (_gameId != null) ...[
                      const SizedBox(height: 18),
                      const Text(
                        'Çevrimiçi tahta bağlantısı hazırlanıyor.',
                        style: TextStyle(color: Color(0xffb9aea5)),
                      ),
                    ],
                    const Spacer(),
                    OutlinedButton(
                      onPressed: _leave,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        foregroundColor: const Color(0xfff3eee7),
                        side: const BorderSide(color: Color(0x99f3eee7)),
                      ),
                      child:
                          Text(_gameId == null ? 'ARAMAYI İPTAL ET' : 'KAPAT'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}
