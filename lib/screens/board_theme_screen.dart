import 'package:chess/chess.dart' as c;
import 'package:flutter/material.dart';

import '../l10n/app_language.dart';
import '../theme/board_theme.dart';
import '../widgets/board_surface.dart';
import '../widgets/rok_style.dart';
import 'subscription_screen.dart';

/// Board skin and piece set, each with a live preview of the real board.
class BoardThemeScreen extends StatefulWidget {
  const BoardThemeScreen({super.key});
  static const bone = Color(0xfff3eee7);
  static const mutedBone = Color(0xffb9b2a8);
  static final _preview =
      c.Chess.fromFEN('4k3/pp3ppp/8/3n4/3B4/8/PP3PPP/2KR4 w - - 0 1');

  @override
  State<BoardThemeScreen> createState() => _BoardThemeScreenState();
}

class _BoardThemeScreenState extends State<BoardThemeScreen> {
  bool _pieces = false;
  final _scroll = ScrollController();

  /// What a locked theme is being tried as. Looking costs nothing, so a
  /// tap puts it on the board above without saving it anywhere; the
  /// selection stays where it was until Premium makes it a choice.
  BoardSkin? _trySkin;
  PieceSet? _trySet;

  void _try({BoardSkin? skin, PieceSet? set}) => setState(() {
        if (skin != null) _trySkin = skin;
        if (set != null) _trySet = set;
      });

  Future<void> _openPremium() async {
    await Navigator.push<void>(context,
        MaterialPageRoute(builder: (_) => const SubscriptionScreen()));
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: BoardTheme.instance,
      builder: (context, _) => RokScaffold(
          appBar: AppBar(title: const LText('Tahta görünümü')),
          body: SafeArea(child: LayoutBuilder(builder: (context, bounds) {
            final size = (bounds.maxHeight * .43)
                .clamp(100.0, 300.0)
                .clamp(0.0, bounds.maxWidth - 36);
            return Column(children: [
              Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
                  child: Center(
                      child: SizedBox(
                          key: const ValueKey('theme-fixed-preview'),
                          width: size,
                          height: size,
                          child: _PreviewBoard(
                              skin: _trySkin ?? boardSkin,
                              pieces: _trySet ?? boardPieces,
                              full: true)))),
              if (_trySkin != null || _trySet != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 4),
                  child: Row(children: [
                    const Icon(Icons.lock_outline_rounded,
                        color: Color(0xffe2b75f), size: 18),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: LText('Deniyorsun. Kullanmak için Premium gerek.',
                          style: TextStyle(
                              color: BoardThemeScreen.mutedBone,
                              fontSize: 13)),
                    ),
                    TextButton(
                        key: const ValueKey('theme-unlock'),
                        onPressed: _openPremium,
                        child: const LText('Premium')),
                  ]),
                ),
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(
                            value: false,
                            label: LText('Tahta'),
                            icon: Icon(Icons.grid_view_rounded)),
                        ButtonSegment(
                            value: true,
                            label: LText('Taşlar'),
                            icon: Icon(Icons.extension_outlined)),
                      ],
                      selected: {
                        _pieces
                      },
                      onSelectionChanged: (value) {
                        setState(() => _pieces = value.single);
                        if (_scroll.hasClients) _scroll.jumpTo(0);
                      })),
              const SizedBox(height: 12),
              Expanded(
                  child: ListView(
                      key:
                          ValueKey(_pieces ? 'piece-options' : 'board-options'),
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                      children: [
                    if (!_pieces)
                      for (final skin in boardSkins) ...[
                        _Option(
                            key: ValueKey('skin-${skin.id}'),
                            label: skin.label,
                            selected: skin.id == boardSkin.id,
                            locked: BoardTheme.isLocked(skin.premium),
                            onTap: () => BoardTheme.isLocked(skin.premium)
                                ? _try(skin: skin)
                                : setState(() {
                                    _trySkin = null;
                                    BoardTheme.instance.selectSkin(skin.id);
                                  }),
                            preview: _PreviewBoard(
                                skin: skin, pieces: _trySet ?? boardPieces)),
                        const SizedBox(height: 10),
                      ]
                    else
                      for (final set in pieceSets)
                        if (BoardTheme.isPieceSetAvailable(set)) ...[
                          _Option(
                              key: ValueKey('set-${set.id}'),
                              label: set.label,
                              selected: set.id == boardPieces.id,
                              locked: BoardTheme.isLocked(set.premium),
                              onTap: () => BoardTheme.isLocked(set.premium)
                                  ? _try(set: set)
                                  : setState(() {
                                      _trySet = null;
                                      BoardTheme.instance
                                          .selectPieceSet(set.id);
                                    }),
                              preview: _PreviewBoard(
                                  skin: _trySkin ?? boardSkin, pieces: set)),
                          const SizedBox(height: 10),
                        ],
                  ])),
            ]);
          }))));
}

class _Option extends StatelessWidget {
  const _Option({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.preview,
    this.locked = false,
  });

  final String label;
  final bool selected;
  final bool locked;
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
              if (locked)
                const Icon(Icons.lock_outline_rounded,
                    color: Color(0xffe2b75f))
              else
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
            final light = (i ~/ squares + file).isEven;
            // The preview shows the material too; a flat swatch sold the
            // skin short and did not match what the board would look like.
            return BoardSquareSurface(
              skin: skin,
              isLight: light,
              pieceIsLight:
                  piece == null ? null : piece.color == c.Color.WHITE,
              seed: i + (light ? 100 : 200),
              child: piece == null
                  ? const SizedBox.expand()
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
