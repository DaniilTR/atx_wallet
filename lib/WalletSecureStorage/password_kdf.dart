// lib/WalletSecureStorage/password_kdf.dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

class PasswordKdf {
  static const String alg = 'pbkdf2-hmac-sha256';
  static const int defaultIterations = 210000;
  static const int defaultSaltBytes = 16;
  static const int defaultBits = 256;

  static Uint8List utf8Bytes(String password) =>
      Uint8List.fromList(utf8.encode(password));

  static Future<SecretKey> deriveKey({
    required String password,
    required Uint8List salt,
    int iterations = defaultIterations,
    int bits = defaultBits,
  }) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: iterations,
      bits: bits,
    );
    return pbkdf2.deriveKey(
      secretKey: SecretKey(utf8Bytes(password)),
      nonce: salt,
    );
  }

  static Future<Uint8List> deriveVerifier({
    required String password,
    required Uint8List salt,
    int iterations = defaultIterations,
  }) async {
    final key = await deriveKey(
      password: password,
      salt: salt,
      iterations: iterations,
      bits: 256,
    );
    final bytes = await key.extractBytes();
    return Uint8List.fromList(bytes);
  }

  static bool constantTimeEquals(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= (a[i] ^ b[i]);
    }
    return diff == 0;
  }
}
