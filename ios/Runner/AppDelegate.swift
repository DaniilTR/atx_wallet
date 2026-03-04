import Flutter
import UIKit
import LocalAuthentication
import Security

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let biometricChannelName = "com.atx/biometric"
  private let keychainService = "com.atx.biometric"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: biometricChannelName,
        binaryMessenger: controller.binaryMessenger
      )

      channel.setMethodCallHandler { [weak self] call, result in
        guard let self else {
          result(FlutterError(code: "internal", message: "App delegate deallocated", details: nil))
          return
        }

        switch call.method {
        case "isAvailable":
          result(self.isBiometricAvailable())

        case "enableFaceAuth":
          guard
            let args = call.arguments as? [String: Any],
            let userId = args["userId"] as? String,
            let vaultKeyB64 = args["vaultKeyB64"] as? String,
            !userId.isEmpty,
            !vaultKeyB64.isEmpty
          else {
            result(FlutterError(code: "enable_error", message: "Missing userId or vaultKeyB64", details: nil))
            return
          }

          self.enableFaceAuth(userId: userId, vaultKeyB64: vaultKeyB64, result: result)

        case "authenticate":
          guard
            let args = call.arguments as? [String: Any],
            let userId = args["userId"] as? String,
            !userId.isEmpty
          else {
            result(FlutterError(code: "no_wrapped_dek", message: "No wrapped DEK for user", details: nil))
            return
          }

          self.authenticate(userId: userId, result: result)

        case "disableFaceAuth":
          guard
            let args = call.arguments as? [String: Any],
            let userId = args["userId"] as? String,
            !userId.isEmpty
          else {
            result(FlutterError(code: "disable_error", message: "Missing userId", details: nil))
            return
          }

          self.disableFaceAuth(userId: userId, result: result)

        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func keychainAccount(for userId: String) -> String {
    "secret_cipher_\(userId)"
  }

  private func isBiometricAvailable() -> Bool {
    let context = LAContext()
    var error: NSError?
    return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
  }

  private func enableFaceAuth(userId: String, vaultKeyB64: String, result: @escaping FlutterResult) {
    let context = LAContext()
    context.localizedCancelTitle = "Отмена"

    context.evaluatePolicy(
      .deviceOwnerAuthenticationWithBiometrics,
      localizedReason: "Подтвердите личность для включения быстрого входа"
    ) { [weak self] success, error in
      guard let self else {
        DispatchQueue.main.async {
          result(FlutterError(code: "enable_error", message: "Internal state error", details: nil))
        }
        return
      }

      guard success else {
        if self.isUserCancellation(error) {
          DispatchQueue.main.async { result(nil) }
          return
        }
        DispatchQueue.main.async {
          result(FlutterError(code: "auth_error", message: error?.localizedDescription ?? "Authentication failed", details: nil))
        }
        return
      }

      guard let secretData = vaultKeyB64.data(using: .utf8) else {
        DispatchQueue.main.async {
          result(FlutterError(code: "enable_error", message: "Invalid vaultKeyB64", details: nil))
        }
        return
      }

      var acError: Unmanaged<CFError>?
      guard let access = SecAccessControlCreateWithFlags(
        nil,
        kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        .biometryCurrentSet,
        &acError
      ) else {
        DispatchQueue.main.async {
          result(FlutterError(code: "enable_error", message: "Failed to create access control", details: acError?.takeRetainedValue().localizedDescription))
        }
        return
      }

      let account = self.keychainAccount(for: userId)

      let deleteQuery: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: self.keychainService,
        kSecAttrAccount as String: account,
      ]
      SecItemDelete(deleteQuery as CFDictionary)

      let addQuery: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: self.keychainService,
        kSecAttrAccount as String: account,
        kSecValueData as String: secretData,
        kSecAttrAccessControl as String: access,
      ]

      let status = SecItemAdd(addQuery as CFDictionary, nil)
      guard status == errSecSuccess else {
        DispatchQueue.main.async {
          result(FlutterError(code: "enable_error", message: "Failed to store biometric secret", details: status))
        }
        return
      }

      DispatchQueue.main.async {
        result(["enabled": true])
      }
    }
  }

  private func authenticate(userId: String, result: @escaping FlutterResult) {
    let context = LAContext()
    context.localizedCancelTitle = "Отмена"

    let account = keychainAccount(for: userId)
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: keychainService,
      kSecAttrAccount as String: account,
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne,
      kSecUseAuthenticationContext as String: context,
      kSecUseOperationPrompt as String: "Подтвердите личность",
    ]

    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)

    if status == errSecSuccess {
      guard
        let data = item as? Data,
        let vaultKeyB64 = String(data: data, encoding: .utf8),
        !vaultKeyB64.isEmpty
      else {
        result(FlutterError(code: "authenticate_error", message: "Biometric secret is corrupted", details: nil))
        return
      }

      result([
        "vaultKeyB64": vaultKeyB64,
        "fallback": false,
      ])
      return
    }

    if status == errSecItemNotFound {
      result(FlutterError(code: "no_wrapped_dek", message: "No wrapped DEK for user", details: nil))
      return
    }

    if status == errSecUserCanceled || status == errSecAuthFailed {
      result(nil)
      return
    }

    result(FlutterError(code: "authenticate_error", message: "Authentication error", details: status))
  }

  private func disableFaceAuth(userId: String, result: FlutterResult) {
    let account = keychainAccount(for: userId)
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: keychainService,
      kSecAttrAccount as String: account,
    ]

    let status = SecItemDelete(query as CFDictionary)
    if status == errSecSuccess || status == errSecItemNotFound {
      result(true)
      return
    }

    result(FlutterError(code: "disable_error", message: "Failed to disable biometric auth", details: status))
  }

  private func isUserCancellation(_ error: Error?) -> Bool {
    guard let laError = error as? LAError else { return false }
    return laError.code == .userCancel ||
      laError.code == .appCancel ||
      laError.code == .systemCancel ||
      laError.code == .userFallback
  }
}
