import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'wallet_vault_models.dart';

class WalletBundleStorage {
  WalletBundleStorage({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock,
            ),
          );

  static const int schemaVersion = 1;
  static const String _keyPrefix = 'wallet_vault_bundle_v1__';

  final FlutterSecureStorage _storage;

  String _keyForUser(String userId) => '$_keyPrefix$userId';

  Future<WalletVaultBundle?> readBundle(String userId) async {
    final raw = await _storage.read(key: _keyForUser(userId));
    if (raw == null || raw.isEmpty) return null;
    try {
      return WalletVaultBundle.fromJsonString(raw);
    } catch (e) {
      debugPrint('Failed to parse vault bundle: $e');
      return null;
    }
  }

  Future<void> writeBundle(String userId, WalletVaultBundle bundle) {
    return _storage.write(
      key: _keyForUser(userId),
      value: bundle.toJsonString(),
    );
  }

  Future<void> deleteBundle(String userId) {
    return _storage.delete(key: _keyForUser(userId));
  }
}
