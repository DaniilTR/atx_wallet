// lib/services/auth_controller.dart
// Контроллер аутентификации, выбирающий между удалённым и локальным хранилищем
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api_client.dart';
import 'auth_repository.dart';
import 'auth_service.dart';
import 'auth_user.dart';
import 'config.dart';

class AuthController {
  AuthController()
    : _repo = AuthRepository(ApiClient(), const FlutterSecureStorage()),
      _memory = AuthService();

  final AuthRepository _repo;
  final AuthService _memory;

  AuthUser? _user;
  AuthUser? get currentUser => _user;
  String? get currentUsername => _user?.username;
  bool get isAuthenticated => _user != null;

  Future<AuthUser> register({
    required String username,
    required String password,
    String? email,
  }) async {
    if (kUseRemoteAuth) {
      try {
        final user = await _repo.register(
          username: username,
          password: password,
          email: email,
        );
        _user = user;
        return user;
      } catch (e) {
        // если сервер недоступен — фолбэк
        debugPrint('Remote register failed: $e');
      }
    }
    final user = await _memory.register(
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
    if (kUseRemoteAuth) {
      try {
        final user = await _repo.login(login: login, password: password);
        _user = user;
        return user;
      } catch (e) {
        debugPrint('Remote login failed: $e');
      }
    }
    final user = await _memory.login(login: login, password: password);
    _user = user;
    return user;
  }

  Future<void> logout() async {
    if (kUseRemoteAuth) {
      try {
        await _repo.logout();
      } catch (_) {}
    }
    await _memory.logout();
    _user = null;
  }
}
