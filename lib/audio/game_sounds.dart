import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GameSounds extends ChangeNotifier {
  GameSounds._();

  static final instance = GameSounds._();
  static const _preferenceKey = 'game_sound_effects_enabled';
  static const _moveVariantCount = 5;

  final Random _random = Random();
  int _lastMoveVariant = 0;

  final AudioPlayer _movePlayer = AudioPlayer(playerId: 'rok-piece-move');
  final AudioPlayer _startPlayer = AudioPlayer(playerId: 'rok-game-start');
  final AudioPlayer _victoryPlayer = AudioPlayer(playerId: 'rok-victory');

  bool _enabled = true;
  bool get enabled => _enabled;

  Future<void> load() async {
    try {
      await AudioPlayer.global.setAudioContext(AudioContext(
        android: const AudioContextAndroid(
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.assistanceSonification,
          audioFocus: AndroidAudioFocus.none,
        ),
        iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
      ));
    } catch (_) {
      // A missing audio backend must not prevent the app from starting.
    }
    final preferences = await SharedPreferences.getInstance();
    _enabled = preferences.getBool(_preferenceKey) ?? true;
  }

  Future<void> setEnabled(bool value) async {
    if (_enabled == value) return;
    _enabled = value;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_preferenceKey, value);
  }

  void playMove({bool capture = false}) {
    if (capture) {
      _play(
        _movePlayer,
        'audio/piece_capture.wav',
        volume: 0.72,
        mode: PlayerMode.lowLatency,
      );
      return;
    }
    // Rotate through recorded variants, never repeating the previous one,
    // so consecutive moves do not sound mechanical.
    var variant = _random.nextInt(_moveVariantCount - 1) + 1;
    if (variant >= _lastMoveVariant) variant++;
    _lastMoveVariant = variant;
    _play(
      _movePlayer,
      'audio/piece_move_$variant.wav',
      volume: 0.72,
      mode: PlayerMode.lowLatency,
    );
  }

  void playStart() => _play(
        _startPlayer,
        'audio/game_start.wav',
        volume: 0.72,
      );

  void playVictory() => _play(
        _victoryPlayer,
        'audio/victory.wav',
        volume: 0.78,
      );

  Future<void> _play(
    AudioPlayer player,
    String asset, {
    required double volume,
    PlayerMode mode = PlayerMode.mediaPlayer,
  }) async {
    if (!_enabled) return;
    try {
      await player.stop();
      await player.play(AssetSource(asset), volume: volume, mode: mode);
    } catch (_) {
      // Sound effects must never interrupt gameplay.
    }
  }
}
