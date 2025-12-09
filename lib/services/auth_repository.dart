// lib/services/auth_repository.dart
// Удалённый репозиторий аутентификации (через API)
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api_client.dart';
import 'auth_user.dart';

class AuthRepository {
  AuthRepository(this._api, this._storage);
  final ApiClient _api;
  final FlutterSecureStorage _storage;

  static const _tokenKey = 'auth_token';
  static const _usernameKey = 'user_username';
  static const _userIdKey = 'user_id';
  static const _userEmailKey = 'user_email';

  Future<AuthUser> register({
    required String username,
    required String password,
    String? email,
  }) async {
    final res = await _api.postJson('/api/auth/register', {
      'username': username,
      if (email != null) 'email': email,
      'password': password,
    });
    final token = res['token'] as String?;
    if (token == null) throw Exception('Token not received');
    final String responseUsername =
        (res['user']?['username'] as String?) ??
        (res['username'] as String?) ??
        username;

    final String resolvedUserId =
        (res['userId'] as String?) ??
        (res['user']?['id'] as String?) ??
        responseUsername;
    final responseEmail = res['user']?['email'] as String? ?? email;
    await _persistSession(
      token: token,
      username: responseUsername,
      userId: resolvedUserId,
      email: responseEmail,
    );
    return AuthUser(
      id: resolvedUserId,
      username: responseUsername,
      email: responseEmail,
    );
  }

  Future<AuthUser> login({
    required String login,
    required String password,
  }) async {
    final res = await _api.postJson('/api/auth/login', {
      'login': login,
      'password': password,
    });
    final token = res['token'] as String?;
    if (token == null) throw Exception('Token not received');
    final String responseUsername =
        (res['user']?['username'] as String?) ??
        (res['username'] as String?) ??
        login;

    final String resolvedUserId =
        (res['userId'] as String?) ??
        (res['user']?['id'] as String?) ??
        responseUsername;
    final responseEmail = res['user']?['email'] as String?;
    await _persistSession(
      token: token,
      username: responseUsername,
      userId: resolvedUserId,
      email: responseEmail,
    );
    return AuthUser(
      id: resolvedUserId,
      username: responseUsername,
      email: responseEmail,
    );
  }

  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _usernameKey);
    await _storage.delete(key: _userIdKey);
    await _storage.delete(key: _userEmailKey);
  }

  Future<String?> get token async => _storage.read(key: _tokenKey);
  Future<String?> get savedUsername async => _storage.read(key: _usernameKey);

  Future<AuthUser?> restoreUser() async {
    final token = await _storage.read(key: _tokenKey);
    final username = await _storage.read(key: _usernameKey);
    if (token == null || username == null) return null;
    final userId = await _storage.read(key: _userIdKey) ?? username;
    final email = await _storage.read(key: _userEmailKey);
    return AuthUser(id: userId, username: username, email: email);
  }

  Future<void> _persistSession({
    required String token,
    required String username,
    required String userId,
    String? email,
  }) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _usernameKey, value: username);
    await _storage.write(key: _userIdKey, value: userId);
    if (email != null) {
      await _storage.write(key: _userEmailKey, value: email);
    } else {
      await _storage.delete(key: _userEmailKey);
    }
  }
}
