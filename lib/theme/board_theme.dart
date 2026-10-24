import 'package:chess/chess.dart' as c;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

/// Board skins and piece sets are chosen separately, so a player can keep the
/// wooden pieces on a marble board or put the glass pieces on any surface.
///
/// Every board screen reads its colours and its piece artwork from here; no
/// screen may hard-code a square colour or an image path any more.

/// How a piece set stores its artwork.
enum PieceArt {
  /// One silhouette per piece type, tinted per side with [BlendMode.modulate].
  silhouette,

  /// Finished artwork, one file per side and piece type, drawn untinted.
  painted,
}

const _pieceFileNames = {
  'p': 'pawn',
  'r': 'rook',
  'n': 'knight',
  'b': 'bishop',
  'q': 'queen',
  'k': 'king',
};

class PieceSet {
  const PieceSet({
    required this.id,
    required this.label,
    required this.directory,
    this.art = PieceArt.silhouette,
    this.whiteTint,
    this.blackTint,
    this.scale = 1,
    this.padding = 3,
  });

  final String id;

  /// English source text; screens pass it through `tr()`.
  final String label;
  final String directory;
  final PieceArt art;
  final Color? whiteTint, blackTint;

  /// Drawn larger than its square, for artwork with built-in margins.
  final double scale;
  final double padding;

  String assetFor(c.Piece piece) {
    final name = _pieceFileNames[piece.type.name];
    final white = piece.color == c.Color.WHITE;
    return art == PieceArt.silhouette
        ? '$directory/$name.png'
        : '$directory/${white ? 'w' : 'b'}_$name.png';
  }

  Color? tintFor(c.Piece piece) => art == PieceArt.silhouette
      ? (piece.color == c.Color.WHITE ? whiteTint : blackTint)
      : null;
}

const woodPieces = PieceSet(
  id: 'wood',
  label: 'Ahşap',
  directory: 'lib/images/wood',
  whiteTint: Color(0xfffff5df),
  blackTint: Color(0xff48291c),
);

/// Finished glass renders; see `assets/pieces/glass/README.md` for the files
/// this set expects. [isAvailable] hides it until the artwork is in the build.
const glassPieces = PieceSet(
  id: 'glass',
  label: 'Cam',
  directory: 'assets/pieces/glass',
  art: PieceArt.painted,
  padding: 2,
  // This set was drawn smaller than the seven that followed it: its king
  // fills 81% of the frame against their 88%, and it sits on a baseline at
  // y=467 against their 479. Scaling about the centre by 1.08 matches both —
  // 87% tall, baseline at 484 — and still clears the top of the frame.
  scale: 1.08,
);

/// Painted sets share one geometry: a 512px frame, the piece centred on a
/// baseline near y=479, the king filling about 88% of the height. They need
/// no scale correction, unlike the glass set.
const artDecoPieces = PieceSet(
    id: 'art_deco',
    label: 'Art Deco',
    directory: 'assets/pieces/art_deco',
    art: PieceArt.painted,
    padding: 2);

const iceLavaPieces = PieceSet(
    id: 'ice_lava',
    label: 'Buz ve Lav',
    directory: 'assets/pieces/ice_lava',
    art: PieceArt.painted,
    padding: 2);

const ivoryEbonyPieces = PieceSet(
    id: 'ivory_ebony',
    label: 'Fildişi ve Abanoz',
    directory: 'assets/pieces/ivory_ebony',
    art: PieceArt.painted,
    padding: 2);

const marbleBasaltPieces = PieceSet(
    id: 'marble_basalt',
    label: 'Mermer ve Bazalt',
    directory: 'assets/pieces/marble_basalt',
    art: PieceArt.painted,
    padding: 2);

const minimalMattePieces = PieceSet(
    id: 'minimal_matte',
    label: 'Sade Mat',
    directory: 'assets/pieces/minimal_matte',
    art: PieceArt.painted,
    padding: 2);

const porcelainObsidianPieces = PieceSet(
    id: 'porcelain_obsidian',
    label: 'Porselen ve Obsidyen',
    directory: 'assets/pieces/porcelain_obsidian',
    art: PieceArt.painted,
    padding: 2);

const silverBronzePieces = PieceSet(
    id: 'silver_bronze',
    label: 'Gümüş ve Bronz',
    directory: 'assets/pieces/silver_bronze',
    art: PieceArt.painted,
    padding: 2);

const pieceSets = [
  woodPieces,
  glassPieces,
  ivoryEbonyPieces,
  marbleBasaltPieces,
  porcelainObsidianPieces,
  silverBronzePieces,
  artDecoPieces,
  minimalMattePieces,
  iceLavaPieces,
];

class BoardSkin {
  const BoardSkin({
    required this.id,
    required this.label,
    required this.light,
    required this.dark,
    required this.selected,
    required this.selectedOverlay,
    required this.checkOverlay,
    required this.premove,
    required this.premoveOverlay,
    required this.lastMove,
    required this.legalDot,
    required this.legalRing,
    required this.coordOnLight,
    required this.coordOnDark,
    this.grain = false,
  });

  final String id;

  /// English source text; screens pass it through `tr()`.
  final String label;

  /// The two square colours.
  final Color light, dark;

  /// Opaque fill for the selected square, used by screens that replace the
  /// square colour outright.
  final Color selected;

  /// Translucent wash for the selected square, used by screens that layer.
  final Color selectedOverlay;
  final Color checkOverlay;

  /// Opaque fill and translucent wash for the two squares of a premove.
  final Color premove, premoveOverlay;

  /// Translucent wash over the two squares of the most recent move.
  final Color lastMove;

  /// Dot on an empty legal square, ring around a piece that can be captured.
  final Color legalDot, legalRing;
  final Color coordOnLight, coordOnDark;

  /// Paints the procedural wood grain the offline board uses.
  final bool grain;

  Color base(bool isLight) => isLight ? light : dark;
  Color coordOn(bool isLight) => isLight ? coordOnLight : coordOnDark;
}

const woodSkin = BoardSkin(
  id: 'wood',
  label: 'Ahşap',
  light: Color(0xffd9b77e),
  dark: Color(0xff85552f),
  selected: Color(0xffb89454),
  selectedOverlay: Color(0x99d39a35),
  checkOverlay: Color(0x99a73e32),
  premove: Color(0xff7985a2),
  premoveOverlay: Color(0x996b83ba),
  lastMove: Color(0x667a743e),
  legalDot: Color(0x88412a18),
  legalRing: Color(0xaae2b75f),
  coordOnLight: Color(0xff684426),
  coordOnDark: Color(0xffe3c691),
  grain: true,
);

const marbleSkin = BoardSkin(
  id: 'marble',
  label: 'Mermer',
  light: Color(0xffeae6dc),
  dark: Color(0xff7d9a74),
  selected: Color(0xffc3cf86),
  selectedOverlay: Color(0x99d6e07f),
  checkOverlay: Color(0x99c7483f),
  premove: Color(0xff8e9fc4),
  premoveOverlay: Color(0x997f93c6),
  lastMove: Color(0x66cfd36a),
  legalDot: Color(0x773d4a36),
  legalRing: Color(0xaaf0e9a4),
  coordOnLight: Color(0xff5c6b56),
  coordOnDark: Color(0xffeef2e6),
);

const slateSkin = BoardSkin(
  id: 'slate',
  label: 'Arduvaz',
  light: Color(0xff8f9bab),
  dark: Color(0xff46505f),
  selected: Color(0xff6f8bb0),
  selectedOverlay: Color(0x998fb4e0),
  checkOverlay: Color(0x99b04a46),
  premove: Color(0xff6a7fa8),
  premoveOverlay: Color(0x997b92bd),
  lastMove: Color(0x66b4c27a),
  legalDot: Color(0x88222b36),
  legalRing: Color(0xaacfe0f2),
  coordOnLight: Color(0xff323b47),
  coordOnDark: Color(0xffd3dcea),
);

/// Cool, low-contrast surface meant to sit under the glass pieces.
const iceSkin = BoardSkin(
  id: 'ice',
  label: 'Buz',
  light: Color(0xffdfe9f0),
  dark: Color(0xff7fa3b8),
  selected: Color(0xffa8cfe4),
  selectedOverlay: Color(0x99a9d9f2),
  checkOverlay: Color(0x99c05a58),
  premove: Color(0xff93b0d6),
  premoveOverlay: Color(0x998fb2de),
  lastMove: Color(0x66a6d1c4),
  legalDot: Color(0x773a5668),
  legalRing: Color(0xaaeaf6ff),
  coordOnLight: Color(0xff4a6878),
  coordOnDark: Color(0xffeef7ff),
);

const boardSkins = [woodSkin, marbleSkin, slateSkin, iceSkin];

/// The player's board skin and piece set, kept on the device.
class BoardTheme extends ChangeNotifier {
  BoardTheme._();

  static final instance = BoardTheme._();

  static const _skinKey = 'board_skin';
  static const _pieceSetKey = 'board_piece_set';

  BoardSkin _skin = woodSkin;
  PieceSet _pieces = woodPieces;

  BoardSkin get skin => _skin;
  PieceSet get pieces => _pieces;

  /// Piece sets whose artwork is bundled in this build.
  static Set<String> _availablePieceSets = {woodPieces.id};

  static bool isPieceSetAvailable(PieceSet set) =>
      _availablePieceSets.contains(set.id);

  Future<void> load() async {
    _availablePieceSets = await _bundledPieceSets();
    final preferences = await SharedPreferences.getInstance();
    final skinId = preferences.getString(_skinKey);
    final pieceSetId = preferences.getString(_pieceSetKey);
    _skin = boardSkins.firstWhere((s) => s.id == skinId,
        orElse: () => woodSkin);
    final saved =
        pieceSets.firstWhere((p) => p.id == pieceSetId, orElse: () => woodPieces);
    _pieces = isPieceSetAvailable(saved) ? saved : woodPieces;
  }

  /// A piece set ships as a folder of assets; a set whose artwork has not been
  /// added yet must not be offered, or its board would render empty squares.
  static Future<Set<String>> _bundledPieceSets() async {
    final available = <String>{};
    for (final set in pieceSets) {
      try {
        await rootBundle.load(
            set.assetFor(c.Piece(c.PieceType.KING, c.Color.WHITE)));
        available.add(set.id);
      } catch (_) {
        // Artwork not bundled; the set stays hidden.
      }
    }
    return available.isEmpty ? {woodPieces.id} : available;
  }

  Future<void> selectSkin(String id) async {
    final next = boardSkins.firstWhere((s) => s.id == id, orElse: () => woodSkin);
    if (next.id == _skin.id) return;
    _skin = next;
    notifyListeners();
    await (await SharedPreferences.getInstance()).setString(_skinKey, next.id);
  }

  Future<void> selectPieceSet(String id) async {
    final next =
        pieceSets.firstWhere((p) => p.id == id, orElse: () => woodPieces);
    if (next.id == _pieces.id || !isPieceSetAvailable(next)) return;
    _pieces = next;
    notifyListeners();
    await (await SharedPreferences.getInstance())
        .setString(_pieceSetKey, next.id);
  }
}

/// Shorthand for the live skin; every board screen rebuilds on a theme change
/// because [MyApp] listens to [BoardTheme.instance].
BoardSkin get boardSkin => BoardTheme.instance.skin;
PieceSet get boardPieces => BoardTheme.instance.pieces;

/// Draws one piece in the player's current piece set.
class BoardPiece extends StatelessWidget {
  const BoardPiece(this.piece, {super.key, this.padding, this.scale});

  final c.Piece piece;

  /// Override the set's own padding and scale, for the few boards that draw
  /// their pieces tighter or larger than the rest.
  final double? padding, scale;

  @override
  Widget build(BuildContext context) => BoardPieceArt(piece,
      set: boardPieces, padding: padding, scale: scale);
}

/// Draws one piece in a named set, for previews of a set that is not in use.
class BoardPieceArt extends StatelessWidget {
  const BoardPieceArt(this.piece,
      {super.key, required this.set, this.padding, this.scale});

  final c.Piece piece;
  final PieceSet set;
  final double? padding, scale;

  @override
  Widget build(BuildContext context) {
    Widget image = set.art == PieceArt.silhouette
        ? Image.asset(set.assetFor(piece),
            color: set.tintFor(piece),
            colorBlendMode: BlendMode.modulate,
            fit: BoxFit.contain)
        : Image.asset(set.assetFor(piece), fit: BoxFit.contain);
    final zoom = scale ?? set.scale;
    if (zoom != 1) {
      image = ClipRect(child: Transform.scale(scale: zoom, child: image));
    }
    return Padding(padding: EdgeInsets.all(padding ?? set.padding), child: image);
  }
}
