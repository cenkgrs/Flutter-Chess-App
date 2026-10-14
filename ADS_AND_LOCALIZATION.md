# Ads, languages and board interaction

## Ads

- `MatchAds` preloads when an offline or online chess match opens; late consent completion also triggers the pending preload.
- Only a ready interstitial can show on an explicit completed-game return to menu. A missing/expired ad is skipped, never awaited at match end.
- Five minutes minimum between actual impressions, persisted on device. First launch also has a five-minute grace period. Clock rollback suppresses ads.
- Android uses Google's test app/unit IDs. iOS has the supplied app ID; its unit remains a test unit unless **both** release mode and `ROK_LIVE_ADS=true` are set.
- UMP consent is requested on startup. Required privacy-options entry is in Profile. No ATT request or IDFA permission has been added.

### Before any store release

1. Resolve **Stockfish GPLv3 distribution and compatibility with the proprietary Google Mobile Ads SDK**. Adding a source notice alone does not establish compatibility; review the combined distribution or change the engine/ads architecture. Do not treat this build as legally cleared for distribution.
2. Configure AdMob iOS consent/privacy messages, privacy policy, store disclosures and app-ads.txt. Decide the tracking/ATT strategy before enabling tracking.
3. Run CocoaPods and a real iOS build on macOS; validate consent, denied permission, ready/missing ads and dismissal on a physical iPhone. Linux testing cannot establish iOS readiness. Review Google's current SKAdNetwork configuration for the release SDK.
4. Only then enable the supplied live iOS unit. Never click live ads during testing.

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
