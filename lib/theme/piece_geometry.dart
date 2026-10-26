import 'dart:ui';

/// Visible artwork bounds, excluding the transparent margins of each PNG.
const paintedPieceBounds = <String, Rect>{
  'assets/pieces/art_deco/b_bishop.png':
      Rect.fromLTRB(0.316406, 0.179688, 0.683594, 0.939453),
  'assets/pieces/art_deco/b_king.png':
      Rect.fromLTRB(0.302734, 0.060547, 0.691406, 0.939453),
  'assets/pieces/art_deco/b_knight.png':
      Rect.fromLTRB(0.289062, 0.220703, 0.708984, 0.939453),
  'assets/pieces/art_deco/b_pawn.png':
      Rect.fromLTRB(0.330078, 0.408203, 0.671875, 0.939453),
  'assets/pieces/art_deco/b_queen.png':
      Rect.fromLTRB(0.302734, 0.154297, 0.693359, 0.939453),
  'assets/pieces/art_deco/b_rook.png':
      Rect.fromLTRB(0.304688, 0.281250, 0.695312, 0.939453),
  'assets/pieces/art_deco/w_bishop.png':
      Rect.fromLTRB(0.316406, 0.187500, 0.681641, 0.939453),
  'assets/pieces/art_deco/w_king.png':
      Rect.fromLTRB(0.304688, 0.066406, 0.691406, 0.939453),
  'assets/pieces/art_deco/w_knight.png':
      Rect.fromLTRB(0.292969, 0.236328, 0.707031, 0.941406),
  'assets/pieces/art_deco/w_pawn.png':
      Rect.fromLTRB(0.330078, 0.414062, 0.669922, 0.941406),
  'assets/pieces/art_deco/w_queen.png':
      Rect.fromLTRB(0.304688, 0.160156, 0.693359, 0.939453),
  'assets/pieces/art_deco/w_rook.png':
      Rect.fromLTRB(0.304688, 0.292969, 0.693359, 0.939453),
  'assets/pieces/glass/b_bishop.png':
      Rect.fromLTRB(0.337891, 0.218750, 0.644531, 0.914062),
  'assets/pieces/glass/b_king.png':
      Rect.fromLTRB(0.333984, 0.091797, 0.679688, 0.916016),
  'assets/pieces/glass/b_knight.png':
      Rect.fromLTRB(0.314453, 0.345703, 0.656250, 0.916016),
  'assets/pieces/glass/b_pawn.png':
      Rect.fromLTRB(0.345703, 0.468750, 0.634766, 0.916016),
  'assets/pieces/glass/b_queen.png':
      Rect.fromLTRB(0.326172, 0.203125, 0.656250, 0.916016),
  'assets/pieces/glass/b_rook.png':
      Rect.fromLTRB(0.324219, 0.357422, 0.646484, 0.916016),
  'assets/pieces/glass/w_bishop.png':
      Rect.fromLTRB(0.339844, 0.226562, 0.642578, 0.912109),
  'assets/pieces/glass/w_king.png':
      Rect.fromLTRB(0.335938, 0.095703, 0.677734, 0.914062),
  'assets/pieces/glass/w_knight.png':
      Rect.fromLTRB(0.322266, 0.347656, 0.652344, 0.914062),
  'assets/pieces/glass/w_pawn.png':
      Rect.fromLTRB(0.347656, 0.474609, 0.632812, 0.912109),
  'assets/pieces/glass/w_queen.png':
      Rect.fromLTRB(0.328125, 0.212891, 0.654297, 0.914062),
  'assets/pieces/glass/w_rook.png':
      Rect.fromLTRB(0.328125, 0.365234, 0.644531, 0.914062),
  'assets/pieces/ice_lava/b_bishop.png':
      Rect.fromLTRB(0.322266, 0.134766, 0.673828, 0.939453),
  'assets/pieces/ice_lava/b_king.png':
      Rect.fromLTRB(0.298828, 0.056641, 0.699219, 0.939453),
  'assets/pieces/ice_lava/b_knight.png':
      Rect.fromLTRB(0.277344, 0.207031, 0.720703, 0.941406),
  'assets/pieces/ice_lava/b_pawn.png':
      Rect.fromLTRB(0.339844, 0.378906, 0.658203, 0.939453),
  'assets/pieces/ice_lava/b_queen.png':
      Rect.fromLTRB(0.302734, 0.119141, 0.695312, 0.939453),
  'assets/pieces/ice_lava/b_rook.png':
      Rect.fromLTRB(0.298828, 0.238281, 0.701172, 0.939453),
  'assets/pieces/ice_lava/w_bishop.png':
      Rect.fromLTRB(0.326172, 0.152344, 0.671875, 0.939453),
  'assets/pieces/ice_lava/w_king.png':
      Rect.fromLTRB(0.300781, 0.062500, 0.699219, 0.939453),
  'assets/pieces/ice_lava/w_knight.png':
      Rect.fromLTRB(0.277344, 0.222656, 0.720703, 0.939453),
  'assets/pieces/ice_lava/w_pawn.png':
      Rect.fromLTRB(0.341797, 0.400391, 0.658203, 0.939453),
  'assets/pieces/ice_lava/w_queen.png':
      Rect.fromLTRB(0.304688, 0.140625, 0.695312, 0.939453),
  'assets/pieces/ice_lava/w_rook.png':
      Rect.fromLTRB(0.300781, 0.273438, 0.699219, 0.939453),
  'assets/pieces/ivory_ebony/b_bishop.png':
      Rect.fromLTRB(0.318359, 0.199219, 0.681641, 0.939453),
  'assets/pieces/ivory_ebony/b_king.png':
      Rect.fromLTRB(0.294922, 0.091797, 0.705078, 0.939453),
  'assets/pieces/ivory_ebony/b_knight.png':
      Rect.fromLTRB(0.298828, 0.267578, 0.701172, 0.939453),
  'assets/pieces/ivory_ebony/b_pawn.png':
      Rect.fromLTRB(0.332031, 0.410156, 0.666016, 0.939453),
  'assets/pieces/ivory_ebony/b_queen.png':
      Rect.fromLTRB(0.304688, 0.173828, 0.693359, 0.939453),
  'assets/pieces/ivory_ebony/b_rook.png':
      Rect.fromLTRB(0.304688, 0.302734, 0.693359, 0.939453),
  'assets/pieces/ivory_ebony/w_bishop.png':
      Rect.fromLTRB(0.326172, 0.201172, 0.673828, 0.943359),
  'assets/pieces/ivory_ebony/w_king.png':
      Rect.fromLTRB(0.300781, 0.060547, 0.697266, 0.943359),
  'assets/pieces/ivory_ebony/w_knight.png':
      Rect.fromLTRB(0.300781, 0.275391, 0.699219, 0.943359),
  'assets/pieces/ivory_ebony/w_pawn.png':
      Rect.fromLTRB(0.335938, 0.419922, 0.662109, 0.943359),
  'assets/pieces/ivory_ebony/w_queen.png':
      Rect.fromLTRB(0.312500, 0.169922, 0.685547, 0.943359),
  'assets/pieces/ivory_ebony/w_rook.png':
      Rect.fromLTRB(0.312500, 0.312500, 0.685547, 0.943359),
  'assets/pieces/marble_basalt/b_bishop.png':
      Rect.fromLTRB(0.324219, 0.220703, 0.675781, 0.939453),
  'assets/pieces/marble_basalt/b_king.png':
      Rect.fromLTRB(0.308594, 0.087891, 0.691406, 0.939453),
  'assets/pieces/marble_basalt/b_knight.png':
      Rect.fromLTRB(0.308594, 0.283203, 0.689453, 0.939453),
  'assets/pieces/marble_basalt/b_pawn.png':
      Rect.fromLTRB(0.341797, 0.441406, 0.658203, 0.939453),
  'assets/pieces/marble_basalt/b_queen.png':
      Rect.fromLTRB(0.308594, 0.160156, 0.693359, 0.939453),
  'assets/pieces/marble_basalt/b_rook.png':
      Rect.fromLTRB(0.316406, 0.304688, 0.683594, 0.939453),
  'assets/pieces/marble_basalt/w_bishop.png':
      Rect.fromLTRB(0.324219, 0.220703, 0.675781, 0.943359),
  'assets/pieces/marble_basalt/w_king.png':
      Rect.fromLTRB(0.308594, 0.058594, 0.691406, 0.943359),
  'assets/pieces/marble_basalt/w_knight.png':
      Rect.fromLTRB(0.308594, 0.287109, 0.691406, 0.943359),
  'assets/pieces/marble_basalt/w_pawn.png':
      Rect.fromLTRB(0.341797, 0.447266, 0.658203, 0.943359),
  'assets/pieces/marble_basalt/w_queen.png':
      Rect.fromLTRB(0.308594, 0.148438, 0.691406, 0.943359),
  'assets/pieces/marble_basalt/w_rook.png':
      Rect.fromLTRB(0.316406, 0.316406, 0.681641, 0.943359),
  'assets/pieces/minimal_matte/b_bishop.png':
      Rect.fromLTRB(0.318359, 0.195312, 0.679688, 0.939453),
  'assets/pieces/minimal_matte/b_king.png':
      Rect.fromLTRB(0.306641, 0.082031, 0.693359, 0.939453),
  'assets/pieces/minimal_matte/b_knight.png':
      Rect.fromLTRB(0.312500, 0.300781, 0.685547, 0.939453),
  'assets/pieces/minimal_matte/b_pawn.png':
      Rect.fromLTRB(0.339844, 0.443359, 0.660156, 0.939453),
  'assets/pieces/minimal_matte/b_queen.png':
      Rect.fromLTRB(0.310547, 0.203125, 0.689453, 0.939453),
  'assets/pieces/minimal_matte/b_rook.png':
      Rect.fromLTRB(0.308594, 0.326172, 0.689453, 0.939453),
  'assets/pieces/minimal_matte/w_bishop.png':
      Rect.fromLTRB(0.320312, 0.185547, 0.677734, 0.939453),
  'assets/pieces/minimal_matte/w_king.png':
      Rect.fromLTRB(0.312500, 0.060547, 0.687500, 0.941406),
  'assets/pieces/minimal_matte/w_knight.png':
      Rect.fromLTRB(0.314453, 0.292969, 0.681641, 0.939453),
  'assets/pieces/minimal_matte/w_pawn.png':
      Rect.fromLTRB(0.341797, 0.447266, 0.656250, 0.941406),
  'assets/pieces/minimal_matte/w_queen.png':
      Rect.fromLTRB(0.310547, 0.185547, 0.687500, 0.939453),
  'assets/pieces/minimal_matte/w_rook.png':
      Rect.fromLTRB(0.310547, 0.316406, 0.689453, 0.941406),
  'assets/pieces/porcelain_obsidian/b_bishop.png':
      Rect.fromLTRB(0.330078, 0.246094, 0.667969, 0.939453),
  'assets/pieces/porcelain_obsidian/b_king.png':
      Rect.fromLTRB(0.310547, 0.083984, 0.689453, 0.939453),
  'assets/pieces/porcelain_obsidian/b_knight.png':
      Rect.fromLTRB(0.294922, 0.275391, 0.701172, 0.939453),
  'assets/pieces/porcelain_obsidian/b_pawn.png':
      Rect.fromLTRB(0.343750, 0.429688, 0.654297, 0.939453),
  'assets/pieces/porcelain_obsidian/b_queen.png':
      Rect.fromLTRB(0.314453, 0.177734, 0.683594, 0.939453),
  'assets/pieces/porcelain_obsidian/b_rook.png':
      Rect.fromLTRB(0.314453, 0.324219, 0.685547, 0.939453),
  'assets/pieces/porcelain_obsidian/w_bishop.png':
      Rect.fromLTRB(0.330078, 0.248047, 0.667969, 0.939453),
  'assets/pieces/porcelain_obsidian/w_king.png':
      Rect.fromLTRB(0.310547, 0.060547, 0.687500, 0.941406),
  'assets/pieces/porcelain_obsidian/w_knight.png':
      Rect.fromLTRB(0.296875, 0.279297, 0.701172, 0.939453),
  'assets/pieces/porcelain_obsidian/w_pawn.png':
      Rect.fromLTRB(0.343750, 0.431641, 0.654297, 0.939453),
  'assets/pieces/porcelain_obsidian/w_queen.png':
      Rect.fromLTRB(0.314453, 0.171875, 0.685547, 0.939453),
  'assets/pieces/porcelain_obsidian/w_rook.png':
      Rect.fromLTRB(0.314453, 0.328125, 0.683594, 0.939453),
  'assets/pieces/silver_bronze/b_bishop.png':
      Rect.fromLTRB(0.314453, 0.175781, 0.681641, 0.939453),
  'assets/pieces/silver_bronze/b_king.png':
      Rect.fromLTRB(0.302734, 0.076172, 0.697266, 0.939453),
  'assets/pieces/silver_bronze/b_knight.png':
      Rect.fromLTRB(0.275391, 0.236328, 0.724609, 0.939453),
  'assets/pieces/silver_bronze/b_pawn.png':
      Rect.fromLTRB(0.324219, 0.402344, 0.671875, 0.939453),
  'assets/pieces/silver_bronze/b_queen.png':
      Rect.fromLTRB(0.296875, 0.150391, 0.701172, 0.939453),
  'assets/pieces/silver_bronze/b_rook.png':
      Rect.fromLTRB(0.296875, 0.255859, 0.703125, 0.939453),
  'assets/pieces/silver_bronze/w_bishop.png':
      Rect.fromLTRB(0.316406, 0.199219, 0.681641, 0.939453),
  'assets/pieces/silver_bronze/w_king.png':
      Rect.fromLTRB(0.302734, 0.060547, 0.697266, 0.939453),
  'assets/pieces/silver_bronze/w_knight.png':
      Rect.fromLTRB(0.277344, 0.244141, 0.720703, 0.939453),
  'assets/pieces/silver_bronze/w_pawn.png':
      Rect.fromLTRB(0.326172, 0.408203, 0.673828, 0.941406),
  'assets/pieces/silver_bronze/w_queen.png':
      Rect.fromLTRB(0.298828, 0.167969, 0.699219, 0.939453),
  'assets/pieces/silver_bronze/w_rook.png':
      Rect.fromLTRB(0.296875, 0.265625, 0.701172, 0.939453),
};
