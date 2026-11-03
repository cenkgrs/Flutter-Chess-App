import 'package:chess_puzzle_app/backend/subscriptions.dart';
import 'package:chess_puzzle_app/screens/subscription_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('rok/subscriptions-test');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('paid access comes from native verification and disappears on expiry',
      () async {
    var verified = true;
    messenger.setMockMethodCallHandler(channel, (call) async => verified);
    final store = SubscriptionStore(channel: channel);
    expect(await store.refresh(), isTrue);
    verified = false;
    expect(await store.refresh(), isFalse);
    expect(store.active, isFalse);
  });

  test('verification failure never grants a subscription', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(code: 'offline');
    });
    final store = SubscriptionStore(channel: channel);
    expect(await store.refresh(), isFalse);
  });

  test('cancelled purchase and restore use verified entitlement', () async {
    var active = false;
    final calls = <String>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      if (call.method == 'entitlement') return active;
      if (call.method == 'purchase') return 'cancelled';
      if (call.method == 'restore') active = true;
      return null;
    });
    final store = SubscriptionStore(channel: channel);
    await store.purchase(SubscriptionStore.productIds.first);
    expect(store.active, isFalse);
    expect(store.busy, isFalse);
    await store.restore();
    expect(store.active, isTrue);
    expect(calls, ['purchase', 'entitlement', 'restore', 'entitlement']);
  });

  testWidgets('missing products do not present a fake purchase or price',
      (tester) async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'entitlement') return false;
      if (call.method == 'products') return [];
      return null;
    });
    final store = SubscriptionStore(channel: channel);
    await tester
        .pumpWidget(MaterialApp(home: SubscriptionScreen(store: store)));
    await tester.pumpAndSettle();
    // The store failure is stated before any pitch, without scrolling.
    expect(find.text('Abonelikler şu anda satışa açık değil.'), findsOneWidget);
    // Nothing is offered for sale, and no price is invented.
    expect(find.byType(FilledButton), findsNothing);
    // The page says so where the plans would have been, rather than ending
    // in the empty space they left behind.
    final soon = find.text('Abonelik yakında');
    await tester.scrollUntilVisible(soon, 200,
        scrollable: find.byType(Scrollable).first);
    expect(soon, findsOneWidget);

    // Restore stays reachable; the paywall is a scrolling page.
    final restore = find.text('Satın alımları geri yükle');
    await tester.scrollUntilVisible(restore, 200,
        scrollable: find.byType(Scrollable).first);
    expect(restore, findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
