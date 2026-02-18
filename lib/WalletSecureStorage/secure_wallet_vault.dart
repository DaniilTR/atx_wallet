import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';

import 'password_kdf.dart';
import 'random_bytes.dart';
import 'wallet_bundle_storage.dart';
import 'wallet_vault_models.dart';

class SecureWalletVault {
  SecureWalletVault({WalletBundleStorage? storage})
    : _storage = storage ?? WalletBundleStorage();

  final WalletBundleStorage _storage;

  // Web хранение допускаем только в debug/profile и/или при явном DEV_WALLET_STORAGE.
  // (Реально secure на Web не гарантируется.)
  static void assertWebPolicy({required bool devAllowed}) {
    if (!kIsWeb) return;
    if (devAllowed) return;
    if (kDebugMode) return;
    throw UnsupportedError('Secure vault on Web is DEV-only');
  }

  Future<bool> exists(String userId) async {
    final b = await _storage.readBundle(userId);
    return b != null && b.wallets.isNotEmpty;
  }

  Future<WalletVaultBundle?> loadBundle(String userId) =>
      _storage.readBundle(userId);

  Future<void> saveBundle(String userId, WalletVaultBundle bundle) =>
      _storage.writeBundle(userId, bundle);

  Future<void> delete(String userId) => _storage.deleteBundle(userId);

  Future<WalletVaultBundle> createEmptyBundle({
    required String password,
    required Uint8List salt,
    int iterations = PasswordKdf.defaultIterations,
  }) async {
    // Просто проверяем, что kdf работает — сам ключ не сохраняем.
    await PasswordKdf.deriveKey(
      password: password,
      salt: salt,
      iterations: iterations,
    );

    return WalletVaultBundle(
      version: WalletBundleStorage.schemaVersion,
      createdAtIso: DateTime.now().toUtc().toIso8601String(),
      kdf: WalletVaultKdf(
        alg: PasswordKdf.alg,
        iterations: iterations,
        saltB64: base64Encode(salt),
        bits: PasswordKdf.defaultBits,
      ),
      activeWalletId: '',
      wallets: const <WalletVaultEntry>[],
    );
  }

  Future<SecretKey> deriveBundleKey({
    required WalletVaultBundle bundle,
    required String password,
  }) async {
    final salt = base64Decode(bundle.kdf.saltB64);
    return PasswordKdf.deriveKey(
      password: password,
      salt: Uint8List.fromList(salt),
      iterations: bundle.kdf.iterations,
      bits: bundle.kdf.bits,
    );
  }

  Future<WalletVaultEntry> encryptMnemonic({
    required SecretKey key,
    required String userId,
    required String walletId,
    required String name,
    required String addressHex,
    required String mnemonic,
  }) async {
    final cipher = AesGcm.with256bits();
    final nonce = await secureRandomBytes(12);

    // AAD: минимальная привязка (без "секретов").
    final aad = utf8.encode('atx_wallet|vault_v1|$userId|$walletId|seed');

    final box = await cipher.encrypt(
      utf8.encode(mnemonic),
      secretKey: key,
      nonce: nonce,
      aad: aad,
    );

    return WalletVaultEntry(
      walletId: walletId,
      name: name,
      userId: userId,
      addressHex: addressHex,
      cipherAlg: 'aes-256-gcm',
      nonceB64: base64Encode(box.nonce),
      macB64: base64Encode(box.mac.bytes),
      ciphertextB64: base64Encode(box.cipherText),
    );
  }

  Future<String> decryptMnemonic({
    required SecretKey key,
    required WalletVaultEntry entry,
  }) async {
    final cipher = AesGcm.with256bits();
    final nonce = base64Decode(entry.nonceB64);
    final macBytes = base64Decode(entry.macB64);
    final cipherText = base64Decode(entry.ciphertextB64);

    final aad = utf8.encode(
      'atx_wallet|vault_v1|${entry.userId}|${entry.walletId}|seed',
    );

    final box = SecretBox(
      Uint8List.fromList(cipherText),
      nonce: Uint8List.fromList(nonce),
      mac: Mac(Uint8List.fromList(macBytes)),
    );

    final clear = await cipher.decrypt(box, secretKey: key, aad: aad);

    return utf8.decode(clear);
  }
}
