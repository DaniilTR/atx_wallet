import 'package:flutter/foundation.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScreenshotProtectionService {
  static const String _homeProtectionKey = 'home_screenshot_protection_enabled';

  static bool get _isMobile {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  static Future<bool> isHomeProtectionEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_homeProtectionKey) ?? true;
  }

  static Future<void> setHomeProtectionEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_homeProtectionKey, enabled);
  }

  static Future<void> protectSettingsScreen() async {
    if (!_isMobile) return;
    await ScreenProtector.preventScreenshotOn();
  }

  static Future<void> applyHomeProtection() async {
    if (!_isMobile) return;
    final enabled = await isHomeProtectionEnabled();
    if (enabled) {
      await ScreenProtector.preventScreenshotOn();
    } else {
      await ScreenProtector.preventScreenshotOff();
    }
  }

  static Future<void> restoreHomeProtection() async {
    await applyHomeProtection();
  }
}