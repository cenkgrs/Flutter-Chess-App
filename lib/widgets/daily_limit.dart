import 'package:flutter/material.dart';

import '../backend/app_backend.dart';
import '../backend/feature_limits.dart';
import '../l10n/app_language.dart';
import '../screens/auth_screen.dart';
import 'rok_style.dart';

/// Spends one of today's free uses of [feature], asking the player to sign
/// in first if they have not. Returns whether the caller may go ahead.
///
/// Signing in is required because the count is kept per account on the
/// server; there is nothing to count for a guest.
Future<bool> claimDailyFeature(
  BuildContext context,
  DailyFeature feature, {
  DailyFeatureLimits? limits,
}) async {
  // Tests inject `limits` and have no session; the sign-in step is the one
  // part of this flow they cannot exercise.
  if (limits == null && AppBackend.currentUser == null) {
    await Navigator.push<void>(
        context, MaterialPageRoute(builder: (_) => const AuthScreen()));
    if (!context.mounted || AppBackend.currentUser == null) return false;
  }

  final allowance =
      await (limits ?? DailyFeatureLimits.instance).claim(feature);
  if (allowance.allowed) return true;
  if (!context.mounted) return false;

  await showDialog<void>(
    context: context,
    builder: (dialog) => RokDialog(
      icon: const Icon(Icons.hourglass_bottom_rounded),
      title: LText(switch (feature) {
        DailyFeature.assistantGame => 'Bugünlük asistan hakkın doldu',
        DailyFeature.gameAnalysis => 'Bugünlük analiz hakkın doldu',
      }),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        LText(
            switch (feature) {
              DailyFeature.assistantGame =>
                'Ücretsiz hesapta günde bir maç asistanla oynanır.',
              DailyFeature.gameAnalysis =>
                'Ücretsiz hesapta günde bir maç analiz edilir.',
            },
            textAlign: TextAlign.center),
        const SizedBox(height: 10),
        LText(_resetLine(allowance.resetsAt),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xffb9aea5), fontSize: 14)),
      ]),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(dialog),
            child: const LText('Tamam')),
      ],
    ),
  );
  return false;
}

String _resetLine(DateTime? resetsAt) {
  if (resetsAt == null) return 'Hakkın gece yarısı yenilenir.';
  final minutes = resetsAt.difference(DateTime.now()).inMinutes;
  if (minutes < 60) return 'Hakkın birazdan yenilenir.';
  // Rounded up: the allowance returns at a fixed moment, so reporting the
  // whole hours already elapsed would name a time that has not arrived.
  return 'Hakkın ${(minutes / 60).ceil()} saat sonra yenilenir.';
}
