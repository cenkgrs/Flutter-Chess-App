import 'analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// StoreKit verifies Apple-signed entitlements on iOS. No local paid flag.
class SubscriptionStore extends ChangeNotifier {
  SubscriptionStore({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('rok/subscriptions') {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'changed') await refresh();
    });
  }

  static final instance = SubscriptionStore();
  static const productIds = [
    'com.silveroaktech.rok.premium.monthly',
    'com.silveroaktech.rok.premium.yearly',
  ];
  final MethodChannel _channel;
  bool active = false;
  bool busy = false;
  String? error;
  List<Map<String, dynamic>> products = [];

  Future<bool> refresh() async {
    try {
      active =
          await _channel.invokeMethod<bool>('entitlement', productIds) ?? false;
    } on MissingPluginException {
      active = false;
    } on PlatformException {
      // A failed check must never create paid access.
      active = false;
    }
    notifyListeners();
    return active;
  }

  Future<void> load() async {
    if (busy) return;
    busy = true;
    error = null;
    notifyListeners();
    try {
      await refresh();
      final rows =
          await _channel.invokeListMethod<dynamic>('products', productIds);
      products =
          (rows ?? []).map((r) => Map<String, dynamic>.from(r as Map)).toList();
      if (products.isEmpty) error = 'Abonelikler şu anda satışa açık değil.';
    } catch (_) {
      products = [];
      error = 'Mağazaya bağlanılamadı. Tekrar dene.';
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> purchase(String id) async {
    if (busy || !productIds.contains(id)) return;
    busy = true;
    error = null;
    notifyListeners();
    try {
      final result = await _channel.invokeMethod<String>('purchase', id);
      if (result == 'pending') error = 'Satın alma onayı bekleniyor.';
      await refresh();
      // Only a verified entitlement counts as a start.
      if (active) {
        AnalyticsService.instance
            .log(AnalyticsEvent.subscriptionStarted, metadata: {'product': id});
      }
    } catch (_) {
      error = 'Satın alma tamamlanamadı. Tekrar dene.';
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> restore() async {
    if (busy) return;
    busy = true;
    error = null;
    notifyListeners();
    try {
      await _channel.invokeMethod<void>('restore');
      if (!await refresh()) {
        error = 'Etkin abonelik bulunamadı.';
      } else {
        AnalyticsService.instance.log(AnalyticsEvent.subscriptionRestored);
      }
    } catch (_) {
      error = 'Satın alımlar geri yüklenemedi. Tekrar dene.';
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}
