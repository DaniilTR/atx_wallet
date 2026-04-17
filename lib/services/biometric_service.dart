// lib/services/biometric_service.dart
// Сервис биометрической аутентификации (Face ID / Touch ID / Fingerprint)
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService {
  BiometricService() : _auth = LocalAuthentication();

  final LocalAuthentication _auth;
  static const _prefKey = 'biometric_enabled';

  /// Проверяет, поддерживает ли устройство биометрию и есть ли
  /// зарегистрированные биометрические данные.
  Future<bool> isAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      if (!canCheck) return false;
      final deviceSupported = await _auth.isDeviceSupported();
      if (!deviceSupported) return false;
      final biometrics = await _auth.getAvailableBiometrics();
      return biometrics.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Возвращает список доступных типов биометрии.
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  /// Запускает биометрическую аутентификацию. Возвращает true при успехе.
  Future<bool> authenticate({String reason = 'Подтвердите личность'}) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } on PlatformException {
      return false;
    }
  }

  /// Читает из SharedPreferences, включена ли биометрия пользователем.
  Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKey) ?? false;
  }

  /// Сохраняет в SharedPreferences состояние флага биометрии.
  Future<void> setBiometricEnabled({required bool enabled}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, enabled);
  }
}
