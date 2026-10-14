import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

bool adCooldownElapsed(DateTime now, DateTime last) =>
    now.difference(last) >= const Duration(minutes: 5);

class MatchAds {
  static final instance = MatchAds();
  final privacyRequired = ValueNotifier(false);
  InterstitialAd? _ad;
  DateTime? _loadedAt;
  DateTime _lastShown = DateTime.now();
  SharedPreferences? _prefs;
  bool _ready = false, _loading = false, _showing = false, _wanted = false;
  int _consentVersion = 0;
  final Set<String> _finished = {};
  bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  Future<void> initialize() async {
    if (!supported) return;
    try {
      _prefs = await SharedPreferences.getInstance();
      final previous = _prefs!.getInt('ad_last_shown');
      if (previous != null) {
        _lastShown = DateTime.fromMillisecondsSinceEpoch(previous);
      }
      ConsentInformation.instance
          .requestConsentInfoUpdate(ConsentRequestParameters(), () {
        ConsentForm.loadAndShowConsentFormIfRequired((_) => _enable());
      }, (_) => _enable());
    } catch (_) {/* Ads must never block gameplay. */}
  }

  Future<void> _enable() async {
    try {
      privacyRequired.value = await ConsentInformation.instance
              .getPrivacyOptionsRequirementStatus() ==
          PrivacyOptionsRequirementStatus.required;
      if (!await ConsentInformation.instance.canRequestAds()) return;
      await MobileAds.instance.initialize();
      _ready = true;
      if (_wanted) preload();
    } catch (_) {}
  }

  void privacyOptions() {
    if (!supported) return;
    _ad?.dispose();
    _ad = null;
    _ready = false;
    _consentVersion++;
    _loading = false;
    ConsentForm.showPrivacyOptionsForm((_) => _enable());
  }

  void preload() {
    _wanted = true;
    if (!_ready || _loading || _ad != null || _showing) return;
    _loading = true;
    final version = _consentVersion;
    final ios = defaultTargetPlatform == TargetPlatform.iOS;
    final live =
        ios && kReleaseMode && const bool.fromEnvironment('ROK_LIVE_ADS');
    final id = live
        ? 'ca-app-pub-3602909305932991/3343520571'
        : ios
            ? 'ca-app-pub-3940256099942544/4411468910'
            : 'ca-app-pub-3940256099942544/1033173712';
    InterstitialAd.load(
        adUnitId: id,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            if (version != _consentVersion || !_ready) {
              ad.dispose();
              return;
            }
            _loading = false;
            _ad = ad;
            _loadedAt = DateTime.now();
          },
          onAdFailedToLoad: (_) {
            if (version == _consentVersion) _loading = false;
          },
        ));
  }

  /// Called only at a completed game's explicit return-to-menu transition.
  Future<void> showIfReady(String match) async {
    if (!_finished.add(match) || _showing || !_ready) return;
    final now = DateTime.now();
    if (!adCooldownElapsed(now, _lastShown)) return;
    final ad = _ad;
    if (ad == null) return; // Never wait for a load at match end.
    _ad = null;
    if (_loadedAt == null ||
        now.difference(_loadedAt!) > const Duration(minutes: 55)) {
      ad.dispose();
      return;
    }
    _showing = true;
    final done = Completer<void>();
    void finish() {
      ad.dispose();
      _showing = false;
      if (!done.isCompleted) done.complete();
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) {
        _lastShown = DateTime.now();
        unawaited(
            _prefs?.setInt('ad_last_shown', _lastShown.millisecondsSinceEpoch));
      },
      onAdDismissedFullScreenContent: (_) => finish(),
      onAdFailedToShowFullScreenContent: (_, __) => finish(),
    );
    try {
      await ad.show();
      await done.future;
    } catch (_) {
      finish();
    }
  }
}
