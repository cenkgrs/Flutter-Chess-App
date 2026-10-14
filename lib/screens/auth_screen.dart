import '../l10n/app_language.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../backend/app_backend.dart';
import '../backend/auth_repository.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, this.startWithRegister = false});

  final bool startWithRegister;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _auth = AuthRepository();
  late bool _register = widget.startWithRegister;
  bool _busy = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (!AppBackend.isConfigured) {
      setState(() => _error = const BackendNotConfiguredException().toString());
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final response = _register
          ? await _auth.register(
              username: _username.text,
              email: _email.text,
              password: _password.text,
            )
          : await _auth.signIn(
              email: _email.text,
              password: _password.text,
            );
      if (!mounted) return;
      if (_register && response.session == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                LText('Doğrulama bağlantısını e-posta adresine gönderdik.'),
          ),
        );
      } else {
        Navigator.pop(context, true);
      }
    } on AuthException catch (error) {
      if (mounted) setState(() => _error = _friendlyMessage(error.message));
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Bağlantı kurulamadı. Tekrar deneyin.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _friendlyMessage(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('invalid login')) {
      return 'E-posta veya şifre hatalı.';
    }
    if (lower.contains('already registered')) {
      return 'Bu e-posta adresi zaten kayıtlı.';
    }
    if (lower.contains('password')) {
      return 'Şifre en az 8 karakter olmalı.';
    }
    return message;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: const Color(0xff32180d),
        body: Container(
          constraints: const BoxConstraints.expand(),
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('lib/images/wood/background.png'),
              fit: BoxFit.cover,
              colorFilter:
                  ColorFilter.mode(Color(0x40000000), BlendMode.darken),
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      key: const ValueKey('auth-back'),
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: const Color(0xfff3eee7),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Icon(Icons.castle_rounded,
                      color: Color(0xfff3eee7), size: 48),
                  const SizedBox(height: 12),
                  const LText(
                    'ROK',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xfff3eee7),
                      fontSize: 28,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 7,
                    ),
                  ),
                  const SizedBox(height: 44),
                  Container(
                    padding: const EdgeInsets.fromLTRB(22, 24, 22, 26),
                    decoration: BoxDecoration(
                      color: const Color(0xf2f3eee7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xff8d8179)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x66000000),
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          LText(
                            _register ? 'HESAP OLUŞTUR' : 'GİRİŞ YAP',
                            style: const TextStyle(
                              color: Color(0xff211712),
                              fontSize: 21,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 7),
                          LText(
                            _register
                                ? 'Ratingini oluştur, çevrimiçi oynamaya başla.'
                                : 'Ratingin ve oyunların kaldığı yerden devam etsin.',
                            style: const TextStyle(
                              color: Color(0xff6e625a),
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (_register) ...[
                            _field(
                              key: const ValueKey('username-field'),
                              controller: _username,
                              label: 'Kullanıcı adı',
                              icon: Icons.person_outline_rounded,
                              validator: (value) {
                                final name = value?.trim() ?? '';
                                if (name.length < 3 || name.length > 20) {
                                  return '3–20 karakter arasında olmalı.';
                                }
                                if (!RegExp(r'^[a-zA-Z0-9_]+$')
                                    .hasMatch(name)) {
                                  return 'Yalnızca harf, rakam ve alt çizgi kullanın.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                          ],
                          _field(
                            key: const ValueKey('email-field'),
                            controller: _email,
                            label: 'E-posta',
                            icon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) =>
                                RegExp(r'^\S+@\S+\.\S+$').hasMatch(value ?? '')
                                    ? null
                                    : 'Geçerli bir e-posta adresi girin.',
                          ),
                          const SizedBox(height: 14),
                          _field(
                            key: const ValueKey('password-field'),
                            controller: _password,
                            label: 'Şifre',
                            icon: Icons.lock_outline_rounded,
                            obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              icon: Icon(_obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined),
                            ),
                            validator: (value) => (value?.length ?? 0) >= 8
                                ? null
                                : 'Şifre en az 8 karakter olmalı.',
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 14),
                            LText(
                              _error!,
                              key: const ValueKey('auth-error'),
                              style: const TextStyle(
                                color: Color(0xff9b3028),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          const SizedBox(height: 22),
                          FilledButton(
                            key: const ValueKey('auth-submit'),
                            onPressed: _busy ? null : _submit,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(54),
                              backgroundColor: const Color(0xff202120),
                              foregroundColor: const Color(0xfff3eee7),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(9),
                              ),
                            ),
                            child: _busy
                                ? const SizedBox.square(
                                    dimension: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xfff3eee7),
                                    ),
                                  )
                                : LText(
                                    _register ? 'KAYIT OL' : 'GİRİŞ YAP',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 13),
                          TextButton(
                            key: const ValueKey('auth-mode-toggle'),
                            onPressed: _busy
                                ? null
                                : () => setState(() {
                                      _register = !_register;
                                      _error = null;
                                    }),
                            child: LText(
                              _register
                                  ? 'Zaten hesabın var mı? Giriş yap'
                                  : 'Hesabın yok mu? Kayıt ol',
                              style: const TextStyle(
                                color: Color(0xff3f352f),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _field({
    Key? key,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
  }) =>
      TextFormField(
        style: const TextStyle(color: Color(0xff211712)),
        cursorColor: const Color(0xff211712),
        key: key,
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: (value) {
          final error = validator(value);
          return error == null ? null : tr(context, error);
        },
        autocorrect: false,
        enableSuggestions: !obscureText,
        decoration: InputDecoration(
          labelStyle: const TextStyle(color: Color(0xff65584e)),
          floatingLabelStyle: const TextStyle(color: Color(0xff352a22)),
          hintStyle: const TextStyle(color: Color(0xff65584e)),
          prefixIconColor: const Color(0xff65584e),
          suffixIconColor: const Color(0xff65584e),
          errorStyle: const TextStyle(color: Color(0xff9b3028)),
          labelText: tr(context, label),
          prefixIcon: Icon(icon),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: const Color(0xfffaf7f2),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: Color(0xffc4bbb4)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: Color(0xffc4bbb4)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: Color(0xff202120), width: 1.5),
          ),
        ),
      );
}
