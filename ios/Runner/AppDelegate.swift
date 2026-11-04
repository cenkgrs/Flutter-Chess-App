import Flutter
import UIKit
import StoreKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var subscriptions: RokSubscriptions?
  private var review: RokReview?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "RokSubscriptions") {
      subscriptions = RokSubscriptions(messenger: registrar.messenger())
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "RokReview") {
      review = RokReview(messenger: registrar.messenger())
    }
  }
}

/// StoreKit 2 verifies Apple-signed transactions; Dart never supplies a paid flag.
@MainActor
private final class RokSubscriptions {
  private let ids: Set<String> = [
    "com.silveroaktech.rok.premium.monthly",
    "com.silveroaktech.rok.premium.yearly"
  ]
  private let channel: FlutterMethodChannel
  private var updates: Task<Void, Never>?

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: "rok/subscriptions", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return }
      Task { @MainActor in
        do {
          switch call.method {
          case "products":
            let products = try await Product.products(for: self.ids)
            result(products.sorted { $0.price < $1.price }.map {
              ["id": $0.id, "price": $0.displayPrice, "title": $0.displayName]
            })
          case "entitlement":
            result(await self.isActive())
          case "purchase":
            guard let id = call.arguments as? String, self.ids.contains(id),
                  let product = try await Product.products(for: [id]).first else {
              result(FlutterError(code: "unavailable", message: "Product unavailable", details: nil))
              return
            }
            switch try await product.purchase() {
            case .success(let verification):
              guard case .verified(let transaction) = verification else {
                result(FlutterError(code: "unverified", message: "Unverified transaction", details: nil))
                return
              }
              await transaction.finish()
              result("purchased")
            case .pending: result("pending")
            case .userCancelled: result("cancelled")
            @unknown default: result("cancelled")
            }
          case "restore":
            try await AppStore.sync()
            result(nil)
          default: result(FlutterMethodNotImplemented)
          }
        } catch {
          result(FlutterError(code: "store_error", message: error.localizedDescription, details: nil))
        }
      }
    }
    updates = Task { [weak self] in
      for await verification in Transaction.updates {
        guard let self = self else { return }
        if case .verified(let transaction) = verification, self.ids.contains(transaction.productID) {
          await transaction.finish()
          self.channel.invokeMethod("changed", arguments: nil)
        }
      }
    }
  }

  private func isActive() async -> Bool {
    for await verification in Transaction.currentEntitlements {
      if case .verified(let transaction) = verification,
         ids.contains(transaction.productID), transaction.revocationDate == nil,
         !transaction.isUpgraded,
         let expiry = transaction.expirationDate, expiry > Date() {
        return true
      }
    }
    return false
  }

  deinit { updates?.cancel() }
}

/// The rating prompt. iOS decides whether the sheet is actually shown and
/// limits how often; the app only says when the moment is a good one.
@MainActor
private final class RokReview {
  private let channel: FlutterMethodChannel

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: "rok/review", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      guard call.method == "request" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let scene = UIApplication.shared.connectedScenes
        .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else {
        result(false)
        return
      }
      if #available(iOS 16.0, *) {
        AppStore.requestReview(in: scene)
      } else {
        SKStoreReviewController.requestReview(in: scene)
      }
      result(true)
    }
  }
}
