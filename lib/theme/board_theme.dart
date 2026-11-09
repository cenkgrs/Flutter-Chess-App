import '../backend/analytics.dart';
import 'piece_geometry.dart';
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
);

/// Painted artwork uses per-file bounds and a common frame for each piece
/// type, so both colours and all materials have the same on-board weight.
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

/// What a square is made of. The painter in `widgets/board_surface.dart`
/// draws each one; a skin that wants none asks for [flat].
enum SurfaceTexture { flat, wood, marble, slate, frost, basalt, ember, deco, paper, metal }

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
    this.texture = SurfaceTexture.flat,
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

  /// The material the squares are painted as.
  final SurfaceTexture texture;

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
  texture: SurfaceTexture.wood,
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
  texture: SurfaceTexture.marble,
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
  texture: SurfaceTexture.slate,
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
  texture: SurfaceTexture.frost,
);

/// Black stone under the porcelain and glass sets, where a light board
/// washed the pieces out.
const obsidianSkin = BoardSkin(
  id: 'obsidian',
  label: 'Obsidyen',
  light: Color(0xff5a5a65),
  dark: Color(0xff1e1e24),
  selected: Color(0xff5d6b7d),
  selectedOverlay: Color(0x997d93ab),
  checkOverlay: Color(0x99a3413c),
  premove: Color(0xff57628a),
  premoveOverlay: Color(0x99707cab),
  lastMove: Color(0x66808a06),
  legalDot: Color(0x99e6e9ef),
  legalRing: Color(0xaad7dde8),
  coordOnLight: Color(0xffd3d6de),
  coordOnDark: Color(0xff8e919b),
  texture: SurfaceTexture.basalt,
);

/// Cooled crust with the heat still in the cracks, for the ice and lava set.
const lavaSkin = BoardSkin(
  id: 'lava',
  label: 'Lav',
  light: Color(0xff6b4a40),
  dark: Color(0xff271a18),
  selected: Color(0xff8c4a2a),
  selectedOverlay: Color(0x99c9602a),
  checkOverlay: Color(0x99bb3b2f),
  premove: Color(0xff6b5a86),
  premoveOverlay: Color(0x99806ea3),
  lastMove: Color(0x66d98033),
  legalDot: Color(0x99ffd9a8),
  legalRing: Color(0xaaffb765),
  coordOnLight: Color(0xffe9c6ab),
  coordOnDark: Color(0xffa07f6f),
  texture: SurfaceTexture.ember,
);

/// Black and gold with the inlaid line the period put on everything.
const decoSkin = BoardSkin(
  id: 'deco',
  label: 'Art Deco',
  light: Color(0xffe8dcc4),
  dark: Color(0xff2f2a26),
  selected: Color(0xffc9a24a),
  selectedOverlay: Color(0x99d9b45c),
  checkOverlay: Color(0x99a4453a),
  premove: Color(0xff7b7f9c),
  premoveOverlay: Color(0x99888cab),
  lastMove: Color(0x66c7a24e),
  legalDot: Color(0x88534a3c),
  legalRing: Color(0xaae8c477),
  coordOnLight: Color(0xff6b5f45),
  coordOnDark: Color(0xffd9c79c),
  texture: SurfaceTexture.deco,
);

/// The board as a diagram on paper, for the matte set and for study.
const paperSkin = BoardSkin(
  id: 'paper',
  label: 'Kağıt',
  light: Color(0xfff2ece0),
  dark: Color(0xffc7bda8),
  selected: Color(0xffd8cf9a),
  selectedOverlay: Color(0x99dcd292),
  checkOverlay: Color(0x99c5736a),
  premove: Color(0xffa9b3c6),
  premoveOverlay: Color(0x99a3aec4),
  lastMove: Color(0x66cfc98a),
  legalDot: Color(0x77615a4c),
  legalRing: Color(0xaa9a9280),
  coordOnLight: Color(0xff7b7363),
  coordOnDark: Color(0xff574f42),
  texture: SurfaceTexture.paper,
);

/// Brushed plate with a milled edge, under the silver and bronze set.
const metalSkin = BoardSkin(
  id: 'metal',
  label: 'Dövme Metal',
  light: Color(0xffb6b2ab),
  dark: Color(0xff6d6a60),
  selected: Color(0xff9d8a5e),
  selectedOverlay: Color(0x99c2a263),
  checkOverlay: Color(0x99a84b42),
  premove: Color(0xff7e879b),
  premoveOverlay: Color(0x998d96ab),
  lastMove: Color(0x66b8a263),
  legalDot: Color(0x88333028),
  legalRing: Color(0xaaeadfc0),
  coordOnLight: Color(0xff4e4b44),
  coordOnDark: Color(0xffd6d1c6),
  texture: SurfaceTexture.metal,
);

const boardSkins = [
  woodSkin,
  marbleSkin,
  slateSkin,
  iceSkin,
  obsidianSkin,
  lavaSkin,
  decoSkin,
  paperSkin,
  metalSkin,
];

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
    _skin =
        boardSkins.firstWhere((s) => s.id == skinId, orElse: () => woodSkin);
    final saved = pieceSets.firstWhere((p) => p.id == pieceSetId,
        orElse: () => woodPieces);
    _pieces = isPieceSetAvailable(saved) ? saved : woodPieces;
  }

  /// A piece set ships as a folder of assets; a set whose artwork has not been
  /// added yet must not be offered, or its board would render empty squares.
  static Future<Set<String>> _bundledPieceSets() async {
    final available = <String>{};
    for (final set in pieceSets) {
      try {
        await rootBundle
            .load(set.assetFor(c.Piece(c.PieceType.KING, c.Color.WHITE)));
        available.add(set.id);
      } catch (_) {
        // Artwork not bundled; the set stays hidden.
      }
    }
    return available.isEmpty ? {woodPieces.id} : available;
  }

  Future<void> selectSkin(String id) async {
    final next =
        boardSkins.firstWhere((s) => s.id == id, orElse: () => woodSkin);
    if (next.id == _skin.id) return;
    _skin = next;
    AnalyticsService.instance
        .log(AnalyticsEvent.themeChanged, metadata: {'skin': next.id});
    notifyListeners();
    await (await SharedPreferences.getInstance()).setString(_skinKey, next.id);
  }

  Future<void> selectPieceSet(String id) async {
    final next =
        pieceSets.firstWhere((p) => p.id == id, orElse: () => woodPieces);
    if (next.id == _pieces.id || !isPieceSetAvailable(next)) return;
    _pieces = next;
    AnalyticsService.instance
        .log(AnalyticsEvent.pieceSetChanged, metadata: {'set': next.id});
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
  Widget build(BuildContext context) =>
      BoardPieceArt(piece, set: boardPieces, padding: padding, scale: scale);
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
    final asset = set.assetFor(piece);
    Widget image;
    if (set.art == PieceArt.painted && paintedPieceBounds.containsKey(asset)) {
      image = LayoutBuilder(builder: (context, constraints) {
        final source = paintedPieceBounds[asset]!;
        final destination = paintedPieceFrame(piece.type);
        final sx = destination.width / source.width;
        final sy = destination.height / source.height;
        return ClipRect(
            child: Transform.translate(
                offset: Offset(
                    (destination.left - source.left * sx) *
                        constraints.maxWidth,
                    (destination.top - source.top * sy) *
                        constraints.maxHeight),
                child: Transform.scale(
                    alignment: Alignment.topLeft,
                    scaleX: sx,
                    scaleY: sy,
                    child: SizedBox.expand(
                        child: Image.asset(asset,
                            fit: BoxFit.fill,
                            filterQuality: FilterQuality.high)))));
      });
    } else {
      image = Image.asset(asset,
          color: set.tintFor(piece),
          colorBlendMode:
              set.art == PieceArt.silhouette ? BlendMode.modulate : null,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high);
      // The classic pawn was almost as tall as its bishop. Keep its feet
      // anchored while reducing it by the requested ten percent.
      if (set.id == woodPieces.id && piece.type == c.PieceType.PAWN) {
        image = Transform.scale(
            scale: .9, alignment: Alignment.bottomCenter, child: image);
      }
      final zoom = scale ?? set.scale;
      if (zoom != 1) {
        image = ClipRect(child: Transform.scale(scale: zoom, child: image));
      }
    }
    return Padding(
        padding: EdgeInsets.all(padding ?? set.padding), child: image);
  }
}

/// Board-friendly proportions. A common footprint makes the photographic
/// sets legible at phone-sized squares instead of retaining product-shot air.
Rect paintedPieceFrame(c.PieceType type) {
  final (width, height) = switch (type) {
    c.PieceType.PAWN => (.50, .68),
    c.PieceType.KNIGHT => (.58, .82),
    c.PieceType.BISHOP => (.50, .84),
    c.PieceType.ROOK => (.56, .77),
    c.PieceType.QUEEN => (.56, .90),
    c.PieceType.KING => (.56, .94),
    _ => (.56, .90),
  };
  return Rect.fromLTWH((1 - width) / 2, .97 - height, width, height);
}
