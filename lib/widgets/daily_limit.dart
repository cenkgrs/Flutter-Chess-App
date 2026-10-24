import 'package:flutter/material.dart';

import '../backend/feature_limits.dart';
import '../l10n/app_language.dart';
import 'rok_style.dart';

/// Spends one of today's free uses of [feature] and returns whether the
/// caller may go ahead, explaining the refusal to the player if not.
///
/// Guests are let through without being counted; [DailyFeatureLimits.claim]
/// decides that, so this function has no session logic of its own.
Future<bool> claimDailyFeature(
  BuildContext context,
  DailyFeature feature, {
  DailyFeatureLimits? limits,
}) async {
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
