# Languages and board interaction

## Ads

The first release ships without ads. The Google Mobile Ads SDK was removed
because ROK links Stockfish and is therefore distributed under
GPL-3.0-or-later: the proprietary SDK cannot be shipped inside a GPL work,
since its source cannot be offered with the binary and its terms add
restrictions GPL-3 forbids. Switching ads off at runtime does not help —
the violation is in distributing the linked library, not in showing an ad.

Ads can return once the engine no longer ships inside the binary. With
Stockfish behind an API, the app itself carries no GPL code and the SDK
becomes a normal dependency again.

## Languages

Turkish, English, German and Russian; device locale by default, unsupported device languages fall back to English. Profile → Language overrides it locally and persists across restarts. Usernames, emails and PGN/SAN are not translated. Translation sources are in `lib/l10n/`; add new UI copy there.

## Board

- Queue one premove while the opponent thinks; validate against the resulting position and discard illegal moves. Automatic promotion is a queen. Snackbar action cancels the queue.
- Pencil enables touch annotations; drag to draw an arrow, tap a square for a circle. Repeat a mark to remove it, or use clear. Mouse right-drag works without enabling drawing mode. Drawing mode blocks piece moves intentionally.
- Assistant advice stays below the board and can scroll on short displays.

## Generated piece assets

Built-in ImageGen used with transparent backgrounds, preserving the ivory carved-wood style:

- `lib/images/wood/queen.png`: broad five-point crown, compact base, clearly different from rook and king.
- `lib/images/wood/king.png`: preserve rounded crown and cross; clean stray light pixels on the left silhouette.

The generated assets are used directly; no manual raster post-processing.
