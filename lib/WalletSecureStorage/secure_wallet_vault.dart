// lib/WalletSecureStorage/secure_wallet_vault.dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';

import 'password_kdf.dart';
import 'random_bytes.dart';
import 'wallet_bundle_storage.dart';
import 'wallet_vault_models.dart';

/// Класс SecureWalletVault управляет зашифрованным хранилищем кошельков.
/// Реализует высокоуровневые операции: создание бандла, шифрование и дешифрование данных.
class SecureWalletVault {
  SecureWalletVault({WalletBundleStorage? storage})
    : _storage = storage ?? WalletBundleStorage();

  /// Политика безопасности для Flutter Web.
  ///
  /// В Web окружении нельзя считать хранение сид-фраз/ключей безопасным.
  /// Поэтому по умолчанию операции secure-vault запрещены.
  ///
  /// Разрешение через [devAllowed] оставлено только для dev-режима/локальной
  /// отладки (например, чтобы не блокировать разработку).
  static void assertWebPolicy({required bool devAllowed}) {
    if (!kIsWeb) return;
    if (devAllowed) return;
    throw UnsupportedError(
      'Secure-кошелёк недоступен в Web версии приложения.',
    );
  }

  final WalletBundleStorage _storage;

  // Проверка наличия и валидности существующего хранилища
  Future<bool> exists(String userId) async {
    final b = await _storage.readBundle(userId);
    return b != null && b.wallets.isNotEmpty;
  }

  /// Инициализация нового пустого хранилища с параметрами KDF.
  Future<WalletVaultBundle> createEmptyBundle({
    required String password,
    required Uint8List salt,
    int iterations = PasswordKdf.defaultIterations,
  }) async {
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

  /// Восстановление ключа шифрования на основе пароля и параметров из хранилища.
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

  /// Шифрование мнемонической фразы с использованием AES-256-GCM.
  /// Включает генерацию уникального nonce и привязку к контексту через AAD.
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

  /// Расшифрование мнемонической фразы.
  /// Включает проверку целостности (MAC) и соответствия контекста (AAD).
  Future<String> decryptMnemonic({
    required SecretKey key,
    required WalletVaultEntry entry,
  }) async {
    final cipher = AesGcm.with256bits();

    // Восстановление компонентов SecretBox из Base64
    final nonce = base64Decode(entry.nonceB64);
    final macBytes = base64Decode(entry.macB64);
    final cipherText = base64Decode(entry.ciphertextB64);

    // Воссоздание контекста AAD для проверки подлинности
    final aad = utf8.encode(
      'atx_wallet|vault_v1|${entry.userId}|${entry.walletId}|seed',
    );

    final box = SecretBox(
      Uint8List.fromList(cipherText),
      nonce: Uint8List.fromList(nonce),
      mac: Mac(Uint8List.fromList(macBytes)),
    );

    // Если данные были изменены, метод decrypt выбросит исключение
    final clear = await cipher.decrypt(box, secretKey: key, aad: aad);

    return utf8.decode(clear);
  }

  // Методы взаимодействия с хранилищем (CRUD)
  Future<WalletVaultBundle?> loadBundle(String userId) =>
      _storage.readBundle(userId);
  Future<void> saveBundle(String userId, WalletVaultBundle bundle) =>
      _storage.writeBundle(userId, bundle);
  Future<void> delete(String userId) => _storage.deleteBundle(userId);
}
