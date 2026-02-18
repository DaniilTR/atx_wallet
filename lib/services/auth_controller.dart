import 'package:flutter/foundation.dart';

import 'auth_service.dart';
import 'auth_user.dart';

class AuthController {
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
    return user;
  }

  Future<AuthUser> login({
    required String login,
    required String password,
  }) async {
    final user = await _auth.login(login: login, password: password);
    _user = user;
    return user;
  }

  Future<AuthUser?> tryRestoreSession() async {
    if (_user != null) return _user;
    try {
      final restored = await _auth.restore();
      if (restored != null) {
        _user = restored;
        return restored;
      }
    } catch (e) {
      debugPrint('Local session restore failed: $e');
    }
    return null;
  }

  Future<void> logout() async {
    await _auth.logout();
    _user = null;
  }
}
