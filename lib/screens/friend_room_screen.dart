import '../l10n/app_language.dart';
import '../widgets/rok_style.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../backend/game_repository.dart';
import '../online/time_control.dart';
import 'online_game_screen.dart';

class FriendRoomScreen extends StatefulWidget {
  const FriendRoomScreen({super.key});
  @override
  State<FriendRoomScreen> createState() => _FriendRoomScreenState();
}

class _FriendRoomScreenState extends State<FriendRoomScreen> {
  static const _bone = Color(0xfff3eee7);
  static const _mutedBone = Color(0xffb9aea5);
  static const _graphite = Color(0xff202120);
  static const _field = Color(0xff181918);
  static const _line = Color(0xff686966);

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
    } on PostgrestException catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = _databaseMessage(error);
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Sunucuya ulaşılamadı. Bağlantını kontrol et.';
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
    } on PostgrestException catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = _databaseMessage(error,
              fallback: 'Kod geçersiz veya odanın süresi dolmuş.');
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Sunucuya ulaşılamadı. Bağlantını kontrol et.';
        });
      }
    }
  }

  void _open(String id) {
    _poller?.cancel();
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => OnlineGameScreen(gameId: id)));
  }

  String _databaseMessage(PostgrestException error,
      {String fallback = 'Oda oluşturulamadı.'}) {
    if (error.code == 'PGRST202' ||
        error.code == '42883' ||
        error.message.contains('create_private_room') ||
        error.message.contains('join_private_room')) {
      return 'Davet odası veritabanı kurulumu eksik. Yeni Supabase migration dosyasını çalıştır.';
    }
    return fallback;
  }

  @override
  void dispose() {
    _poller?.cancel();
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RokScaffold(
        backgroundColor: const Color(0xff32180d),
        appBar: AppBar(
          title: const LText(
            'ARKADAŞLA OYNA',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          backgroundColor: _graphite,
          foregroundColor: _bone,
          surfaceTintColor: Colors.transparent,
        ),
        body: DecoratedBox(
          decoration: const BoxDecoration(
              image: DecorationImage(
                  image: AssetImage('lib/images/wood/background.png'),
                  fit: BoxFit.cover,
                  colorFilter:
                      ColorFilter.mode(Color(0x44000000), BlendMode.darken))),
          child: ListView(padding: const EdgeInsets.all(20), children: [
            _card(
                Icons.add_circle_outline_rounded,
                'ODA KUR',
                Column(children: [
                  DropdownButtonFormField<TimeControl>(
                      initialValue: _control,
                      dropdownColor: _graphite,
                      iconEnabledColor: _mutedBone,
                      style: const TextStyle(
                          color: _bone,
                          fontSize: 15,
                          fontWeight: FontWeight.w600),
                      decoration: _inputDecoration(
                        label: 'Oyun süresi',
                        icon: Icons.timer_outlined,
                      ),
                      items: TimeControl.presets
                          .map((x) => DropdownMenuItem(
                              value: x,
                              child: LText('${x.pool.label} · ${x.label}')))
                          .toList(),
                      onChanged: (x) => setState(() => _control = x!)),
                  const SizedBox(height: 16),
                  if (_createdCode == null)
                    FilledButton(
                        onPressed: _busy ? null : _create,
                        style: _primaryButtonStyle(),
                        child: const LText('DAVET KODU OLUŞTUR'))
                  else ...[
                    const LText('DAVET KODUN',
                        style: TextStyle(
                            color: _mutedBone,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2)),
                    const SizedBox(height: 8),
                    SelectableText(_createdCode!,
                        style: const TextStyle(
                            color: _bone,
                            fontSize: 34,
                            letterSpacing: 6,
                            fontWeight: FontWeight.w700)),
                    TextButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _createdCode!));
                        },
                        style:
                            TextButton.styleFrom(foregroundColor: _mutedBone),
                        icon: const Icon(Icons.copy_rounded),
                        label: const LText('Kodu kopyala')),
                    const LText(
                      'Arkadaşın katıldığında oyun otomatik açılır.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _mutedBone),
                    ),
                  ],
                ])),
            const SizedBox(height: 14),
            _card(
                Icons.key_rounded,
                'KODLA KATIL',
                Column(children: [
                  TextField(
                      controller: _code,
                      style: const TextStyle(
                          color: _bone,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2),
                      cursorColor: _bone,
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 6,
                      decoration: _inputDecoration(
                        label: '6 haneli davet kodu',
                        icon: Icons.key_rounded,
                      )),
                  FilledButton(
                      onPressed: _busy ? null : _join,
                      style: _primaryButtonStyle(),
                      child: const LText('ODAYA KATIL')),
                ])),
            if (_error != null)
              Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: LText(_error!,
                      style: const TextStyle(color: Color(0xffffd0c8)))),
          ]),
        ),
      );

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) =>
      InputDecoration(
        labelText: tr(context, label),
        labelStyle: const TextStyle(color: _mutedBone),
        prefixIcon: Icon(icon, color: _mutedBone),
        counterStyle: const TextStyle(color: _mutedBone),
        filled: true,
        fillColor: _field,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: const BorderSide(color: _line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: const BorderSide(color: _bone, width: 1.3),
        ),
      );

  ButtonStyle _primaryButtonStyle() => FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        backgroundColor: _bone,
        foregroundColor: _graphite,
        disabledBackgroundColor: const Color(0xff73716e),
        disabledForegroundColor: const Color(0xffc9c3bd),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          letterSpacing: .8,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
      );

  Widget _card(IconData icon, String title, Widget child) => Container(
        padding: const EdgeInsets.fromLTRB(18, 17, 18, 20),
        decoration: BoxDecoration(
          color: const Color(0xf2202120),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _line, width: .8),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 13,
              offset: Offset(0, 7),
            ),
          ],
        ),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Icon(icon, color: _bone, size: 23),
            const SizedBox(width: 10),
            LText(title,
                style: const TextStyle(
                    color: _bone,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2)),
          ]),
          const Divider(height: 29, color: _line),
          child
        ]),
      );
}
