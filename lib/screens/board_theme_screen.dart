import 'package:chess/chess.dart' as c;
import 'package:flutter/material.dart';

import '../l10n/app_language.dart';
import '../theme/board_theme.dart';
import '../widgets/rok_style.dart';

/// Board skin and piece set, each with a live preview of the real board.
class BoardThemeScreen extends StatelessWidget {
  const BoardThemeScreen({super.key});

  static const bone = Color(0xfff3eee7);
  static const mutedBone = Color(0xffb9b2a8);

  /// A short, recognisable fragment that shows both sides and five of the six
  /// piece shapes at a glance.
  static final _preview =
      c.Chess.fromFEN('4k3/pp3ppp/8/3n4/3B4/8/PP3PPP/2KR4 w - - 0 1');

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: BoardTheme.instance,
        builder: (context, _) => RokScaffold(
          appBar: AppBar(title: const LText('Tahta görünümü')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: _PreviewBoard(
                      skin: boardSkin, pieces: boardPieces, full: true),
                ),
              ),
              const SizedBox(height: 28),
              const _SectionTitle('TAHTA'),
              const SizedBox(height: 10),
              for (final skin in boardSkins) ...[
                _Option(
                  label: skin.label,
                  selected: skin.id == boardSkin.id,
                  onTap: () => BoardTheme.instance.selectSkin(skin.id),
                  preview: _PreviewBoard(skin: skin, pieces: boardPieces),
                ),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 18),
              const _SectionTitle('TAŞLAR'),
              const SizedBox(height: 10),
              for (final set in pieceSets)
                if (BoardTheme.isPieceSetAvailable(set)) ...[
                  _Option(
                    label: set.label,
                    selected: set.id == boardPieces.id,
                    onTap: () => BoardTheme.instance.selectPieceSet(set.id),
                    preview: _PreviewBoard(skin: boardSkin, pieces: set),
                  ),
                  const SizedBox(height: 10),
                ],
              if (pieceSets.any((set) => !BoardTheme.isPieceSetAvailable(set)))
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: LText('Yeni taş setleri sonraki güncellemelerde gelir.',
                      style: TextStyle(color: mutedBone, fontSize: 13)),
                ),
            ],
          ),
        ),
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => LText(text,
      style: const TextStyle(
          color: BoardThemeScreen.mutedBone,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.6));
}

class _Option extends StatelessWidget {
  const _Option({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.preview,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget preview;

  @override
  Widget build(BuildContext context) => Material(
        color: const Color(0xe6202120),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
              color: selected ? BoardThemeScreen.bone : const Color(0xff686966),
              width: selected ? 1.6 : .8),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(children: [
              SizedBox(width: 52, height: 52, child: preview),
              const SizedBox(width: 16),
              Expanded(
                child: LText(label,
                    style: const TextStyle(
                        color: BoardThemeScreen.bone,
                        fontWeight: FontWeight.w600,
                        fontSize: 17)),
              ),
              Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: selected
                      ? BoardThemeScreen.bone
                      : BoardThemeScreen.mutedBone),
            ]),
          ),
        ),
      );
}

/// The preview position in full, or a two-square swatch, drawn with the skin
/// and piece set being offered rather than the ones in use.
class _PreviewBoard extends StatelessWidget {
  const _PreviewBoard(
      {required this.skin, required this.pieces, this.full = false});

  final BoardSkin skin;
  final PieceSet pieces;
  final bool full;

  static final _swatch = [
    c.Piece(c.PieceType.QUEEN, c.Color.WHITE),
    c.Piece(c.PieceType.KNIGHT, c.Color.BLACK),
    c.Piece(c.PieceType.KNIGHT, c.Color.WHITE),
    c.Piece(c.PieceType.QUEEN, c.Color.BLACK),
  ];

  @override
  Widget build(BuildContext context) {
    final squares = full ? 8 : 2;
    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(full ? 10 : 6),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: squares * squares,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: squares),
          itemBuilder: (context, i) {
            final file = i % squares, rank = 8 - i ~/ squares;
            final piece = full
                ? BoardThemeScreen._preview.get('${'abcdefgh'[file]}$rank')
                : _swatch[i];
            return ColoredBox(
              color: skin.base((i ~/ squares + file).isEven),
              child: piece == null
                  ? null
                  // No scale override: a preview that ignored the set's own
                  // scale would show a different size than the real board.
                  : BoardPieceArt(piece, set: pieces, padding: full ? 2 : 1),
            );
          },
        ),
      ),
    );
  }
}
