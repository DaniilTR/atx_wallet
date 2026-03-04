import 'package:flutter/foundation.dart';

import 'auth_service.dart';

class AuthController extends ChangeNotifier {
  AuthController({AuthService? authService})
    : _auth = authService ?? AuthService();

  final AuthService _auth;

  AuthUser? _user;
  AuthUser? get currentUser => _user;
  bool get isAuthenticated => _user != null;

  Future<AuthUser> register({
    required String username,
    required String password,
    String? email,
  }) async {
    final user = await _auth.register(
      username: username,
      password: password,
      email: email,
    );
    _user = user;
    notifyListeners();
    return user;
  }

  Future<AuthUser> login({
    required String login,
    required String password,
  }) async {
    final user = await _auth.login(login: login, password: password);
    _user = user;
    notifyListeners();
    return user;
  }

  /// Локальный "логин" без пароля после успешной биометрии.
  Future<AuthUser?> loginWithBiometrics({required String username}) async {
    final user = await _auth.loginWithBiometrics(username);
    _user = user;
    notifyListeners();
    return user;
  }

  Future<AuthUser?> tryRestoreSession() async {
    if (_user != null) return _user;
    try {
      final restored = await _auth.restore();
      if (restored != null) {
        _user = restored;
        notifyListeners();
        return restored;
      }
    } catch (e) {
      debugPrint('Local session restore failed: $e');
    }
    return null;
  }

  Future<AuthUser> setPrefersDarkTheme(bool prefersDarkTheme) async {
    final updated = await _auth.setThemePreference(
      prefersDarkTheme: prefersDarkTheme,
    );
    _user = updated;
    notifyListeners();
    return updated;
  }

  /// Найти внутренний `id` пользователя по `username`.
  Future<String?> findUserIdByUsername(String username) async {
    return await _auth.findUserId(username);
  }

  /// Есть ли хоть один локальный пользователь.
  Future<bool> hasAnyUsers() async {
    return await _auth.hasAnyUsers();
  }

  Future<void> logout() async {
    await _auth.logout();
    _user = null;
    notifyListeners();
  }
}
