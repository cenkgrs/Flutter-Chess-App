import '../screens/subscription_screen.dart';
import '../backend/subscriptions.dart';
import 'package:flutter/material.dart';

import '../backend/feature_limits.dart';
import '../l10n/app_language.dart';
import 'rok_style.dart';

/// Spends one of today's free uses of [feature] and returns whether the
/// caller may go ahead, explaining the refusal to the player if not.
///
Future<bool> claimDailyFeature(
  BuildContext context,
  DailyFeature feature, {
  DailyFeatureLimits? limits,
}) async {
  final allowance =
      await (limits ?? DailyFeatureLimits.instance).claim(feature);
  if (allowance.allowed) return true;
  if (!context.mounted) return false;

  return _offerSubscription(context, feature, allowance);
}

/// Check entry without consuming the allowance. The first assistant question
/// still spends it, so opening and leaving the board remains free.
Future<bool> checkDailyFeature(BuildContext context, DailyFeature feature,
    {DailyFeatureLimits? limits}) async {
  final status = await (limits ?? DailyFeatureLimits.instance).status();
  if (!context.mounted) return false;
  final allowance = status[feature];
  if (allowance == null || allowance.allowed) return true;
  return _offerSubscription(context, feature, allowance);
}

Future<bool> _offerSubscription(BuildContext context, DailyFeature feature,
    FeatureAllowance allowance) async {
  final upgrade = await showDialog<bool>(
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
                'Bugünlük ücretsiz asistanlı maç hakkını kullandın. Abonelikle sınırsız asistanlı maç oynayabilirsin.',
              DailyFeature.gameAnalysis =>
                'Bugünlük ücretsiz analiz hakkını kullandın. Abonelikle sınırsız maç analizi yapabilirsin.',
            },
            textAlign: TextAlign.center),
        const SizedBox(height: 10),
        LText(_resetLine(allowance.resetsAt),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xffb9aea5), fontSize: 14)),
      ]),
      actions: [
        FilledButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: const LText('Abonelik seçenekleri')),
        TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const LText('Tamam')),
      ],
    ),
  );
  if (upgrade == true && context.mounted) {
    await Navigator.push(
        context, MaterialPageRoute(builder: (_) => const SubscriptionScreen()));
    return SubscriptionStore.instance.refresh();
  }
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
