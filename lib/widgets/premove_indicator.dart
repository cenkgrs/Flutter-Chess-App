import 'package:flutter/material.dart';
import '../l10n/app_language.dart';
import '../prototype/premove.dart';
import '../theme/board_theme.dart';

/// Lives in the board header: queue status and cancellation never cover play.
class PremoveIndicator extends StatelessWidget {
  const PremoveIndicator(
      {super.key, required this.move, required this.onCancel});
  final Premove move;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) => Semantics(
      liveRegion: true,
      child: InputChip(
          key: const ValueKey('premove-indicator'),
          avatar: Icon(Icons.double_arrow_rounded,
              color: boardSkin.premove, size: 18),
          label: LText('Ön hamle: ${move.from} → ${move.to}',
              style: const TextStyle(
                  color: Color(0xfff3eee7),
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
          onDeleted: onCancel,
          deleteIcon: const Icon(Icons.close_rounded, size: 18),
          deleteIconColor: const Color(0xfff3eee7),
          deleteButtonTooltipMessage: tr(context, 'İptal'),
          backgroundColor: Color.alphaBlend(
              boardSkin.premove.withValues(alpha: .16),
              const Color(0xff202120)),
          side: BorderSide(color: boardSkin.premove.withValues(alpha: .65)),
          shape: const StadiumBorder(),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact));
}
