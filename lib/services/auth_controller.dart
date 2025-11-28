import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_client.dart';
import 'auth_repository.dart';
import 'auth_service.dart';
import 'config.dart';

class AuthController {
  AuthController()
      : _repo = AuthRepository(ApiClient(), const FlutterSecureStorage()),
        _memory = AuthService();

  final AuthRepository _repo;
  final AuthService _memory;

  String? _username;
  String? get currentUsername => _username;
  bool get isAuthenticated => _username != null;

  Future<void> register({required String username, required String password, String? email}) async {
    if (kUseRemoteAuth) {
      try {
        await _repo.register(username: username, password: password, email: email);
        _username = username;
        return;
      } catch (e) {
        // если сервер недоступен — фолбэк
        debugPrint('Remote register failed: $e');
      }
    }
    await _memory.register(username: username, password: password, email: email);
    _username = username;
  }

  Future<void> login({required String login, required String password}) async {
    if (kUseRemoteAuth) {
      try {
        await _repo.login(login: login, password: password);
        _username = login;
        return;
      } catch (e) {
        debugPrint('Remote login failed: $e');
      }
    }
    await _memory.login(login: login, password: password);
    _username = login;
  }

  Future<void> logout() async {
    if (kUseRemoteAuth) {
      try {
        await _repo.logout();
      } catch (_) {}
    }
    await _memory.logout();
    _username = null;
  }
}
