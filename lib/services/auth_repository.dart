import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_client.dart';

class AuthRepository {
  AuthRepository(this._api, this._storage);
  final ApiClient _api;
  final FlutterSecureStorage _storage;

  static const _tokenKey = 'auth_token';
  static const _usernameKey = 'user_username';

  Future<void> register({required String username, required String password, String? email}) async {
    final res = await _api.postJson('/api/auth/register', {
      'username': username,
      if (email != null) 'email': email,
      'password': password,
    });
    final token = res['token'] as String?;
    if (token == null) throw Exception('Token not received');
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _usernameKey, value: username);
  }

  Future<void> login({required String login, required String password}) async {
    final res = await _api.postJson('/api/auth/login', {
      'login': login,
      'password': password,
    });
    final token = res['token'] as String?;
    if (token == null) throw Exception('Token not received');
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _usernameKey, value: login);
  }

  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _usernameKey);
  }

  Future<String?> get token async => _storage.read(key: _tokenKey);
  Future<String?> get savedUsername async => _storage.read(key: _usernameKey);
}
