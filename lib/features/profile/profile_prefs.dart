import 'package:shared_preferences/shared_preferences.dart';

class ProfilePrefs {
  static const _displayNameKey = 'profile_display_name_v1';

  static String? _displayName;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_displayNameKey)?.trim();
    _displayName = (saved == null || saved.isEmpty) ? null : saved;
  }

  static String? get displayName => _displayName;

  static Future<void> setDisplayName(String? value) async {
    final prefs = await SharedPreferences.getInstance();
    final next = value?.trim();
    if (next == null || next.isEmpty) {
      _displayName = null;
      await prefs.remove(_displayNameKey);
      return;
    }
    _displayName = next;
    await prefs.setString(_displayNameKey, next);
  }
}
