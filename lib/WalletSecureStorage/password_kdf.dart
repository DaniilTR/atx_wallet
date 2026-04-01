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

  /// Метод для генерации криптографического ключа (SecretKey)
  /// Используется для последующих операций шифрования
  static Future<SecretKey> deriveKey({
    required String password,
    required Uint8List salt,
    int iterations = defaultIterations,
    int bits = defaultBits,
  }) async {
    // Инициализация конфигурации PBKDF2 с HMAC-SHA256
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: iterations,
      bits: bits,
    );

    // Выполнение вычислений производного ключа
    return pbkdf2.deriveKey(
      secretKey: SecretKey(utf8Bytes(password)),
      nonce: salt,
    );
  }

  /// Метод для генерации верификатора пароля в виде набора байт
  /// Используется для проверки пароля при входе в систему
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
    // Извлечение сырых байт из объекта секретного ключа
    final bytes = await key.extractBytes();
    return Uint8List.fromList(bytes);
  }

  /// Сравнение двух массивов байт за константное время.
  /// Защищает систему от атак по побочным каналам (тайминг-атаки).
  static bool constantTimeEquals(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= (a[i] ^ b[i]);
    }
    return diff == 0;
  }
}
