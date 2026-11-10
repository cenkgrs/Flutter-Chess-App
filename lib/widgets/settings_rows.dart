import 'package:flutter/material.dart';

import '../l10n/app_language.dart';

/// The two rows a page of choices is made of. They began inside the profile
/// page and are shared now that the choices themselves live in their own
/// page: a setting should look the same wherever it is reached from.
const _bone = Color(0xfff3eee7);
const _mutedBone = Color(0xffb9b2a8);
const _surface = Color(0xe6202120);
const _border = Color(0xff686966);

ShapeBorder _shape() => RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: _border, width: .8),
    );

TextStyle get _titleStyle => const TextStyle(
    color: _bone, fontWeight: FontWeight.w600, fontSize: 17);

Widget _subtitle(String text) => Padding(
      padding: const EdgeInsets.only(top: 4),
      child: LText(text,
          style: const TextStyle(color: _mutedBone, height: 1.35)),
    );

class SettingsLink extends StatelessWidget {
  const SettingsLink({
    super.key,
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
        color: _surface,
        shape: _shape(),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: onTap,
          minVerticalPadding: 16,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          leading: Icon(icon, color: _bone, size: 28),
          title: LText(title, style: _titleStyle),
          subtitle: _subtitle(subtitle),
          trailing:
              const Icon(Icons.chevron_right_rounded, color: _mutedBone),
        ),
      );
}

class SettingsSwitch extends StatelessWidget {
  const SettingsSwitch({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Material(
        color: _surface,
        shape: _shape(),
        clipBehavior: Clip.antiAlias,
        child: SwitchListTile.adaptive(
          value: value,
          onChanged: onChanged,
          secondary: Icon(icon, color: _bone, size: 28),
          title: LText(title, style: _titleStyle),
          subtitle: _subtitle(subtitle),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        ),
      );
}

/// The small grey heading a group of rows sits under.
class SettingsHeading extends StatelessWidget {
  const SettingsHeading(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => LText(text,
      style: const TextStyle(
          color: _mutedBone,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.6));
}
