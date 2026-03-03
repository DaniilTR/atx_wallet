import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Хелпер для хранения флагов биометрии (включено/выключено) по userId и username.
class BiometricPrefs {
  static const _storage = FlutterSecureStorage();

  static String _key(String id) => 'biometric_enabled_$id';

  static const _lastKey = 'biometric_last_user';

  /// Проверить, включена ли биометрия для userId или username
  static Future<bool> isEnabled(String id) async {
    final v = await _storage.read(key: _key(id));
    return v == 'true';
  }

  /// Установить флаг биометрии для userId или username
  static Future<void> setEnabled(String id, bool enabled) async {
    await _storage.write(key: _key(id), value: enabled ? 'true' : 'false');
  }

  /// Удалить флаг биометрии
  static Future<void> clear(String id) async {
    await _storage.delete(key: _key(id));
  }

  /// Пометить последний userId (или username), для которого включали биометрию
  static Future<void> setLastUser(String id) async {
    await _storage.write(key: _lastKey, value: id);
  }

  static Future<String?> getLastUser() async {
    return await _storage.read(key: _lastKey);
  }

  static Future<void> clearLastUser() async {
    await _storage.delete(key: _lastKey);
  }
}
