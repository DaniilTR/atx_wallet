import 'package:flutter/services.dart';

/// Безопасная обёртка для работы с биометрией и DEK через MethodChannel.
class BiometricFace {
  static const MethodChannel _channel = MethodChannel('com.atx/biometric');

  /// Проверить доступность биометрии на устройстве
  static Future<bool> isAvailable() async {
    final result = await _channel.invokeMethod<bool>('isAvailable');
    return result ?? false;
  }

  /// Включить биометрию.
  ///
  /// Важно: мы НЕ передаём и НЕ сохраняем реальный пароль пользователя.
  /// Вместо этого передаём локальный ключ разблокировки vault (base64), который
  /// хранится на устройстве только в зашифрованном виде и доступен только после
  /// успешной биометрии.
  static Future<Map<String, dynamic>?> enableFaceAuth({
    required String userId,
    required String vaultKeyB64,
  }) async {
    final res = await _channel.invokeMethod<Map>('enableFaceAuth', {
      'userId': userId,
      'vaultKeyB64': vaultKeyB64,
    });
    if (res == null) return null;
    return Map<String, dynamic>.from(res);
  }

  /// Аутентификация: показать prompt.
  /// Возвращаемое значение может быть:
  /// - `Map` с полем `secret` (String) при успехе расшифровки, либо
  /// - `null` при отмене/ошибке.
  ///
  /// Важно: нативный код не возвращает raw ключи/IV (DEK/KEK) в Dart.
  static Future<dynamic> authenticate({String? userId}) async {
    final args = userId == null ? null : {'userId': userId};
    final result = await _channel.invokeMethod<dynamic>('authenticate', args);
    return result;
  }

  /// Отключить биометрию: удалить wrappedDEK и ключи
  static Future<void> disableFaceAuth({required String userId}) async {
    await _channel.invokeMethod('disableFaceAuth', {
      'userId': userId,
    });
  }
}
