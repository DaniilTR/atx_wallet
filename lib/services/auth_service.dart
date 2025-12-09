// lib/services/auth_service.dart
// Локальный сервис аутентификации с хранением данных на устройстве
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'auth_user.dart';

class AuthService {
  AuthService({SharedPreferences? preferences})
    : _prefsFuture = preferences != null
          ? Future.value(preferences)
          : SharedPreferences.getInstance();

  static const _usersStorageKey = 'local_auth_users_v1';
  static const _currentUserKey = 'local_auth_current_user_v1';

  final Map<String, _UserRecord> _users = {};
  final Future<SharedPreferences> _prefsFuture;
  AuthUser? _currentUser;
  bool _initialized = false;

  bool get isAuthenticated => _currentUser != null;
  AuthUser? get currentUser => _currentUser;

  Future<void> _ensureLoaded() async {
    if (_initialized) return;
    final prefs = await _prefsFuture;
    final raw = prefs.getString(_usersStorageKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        decoded.forEach((key, value) {
          if (value is Map<String, dynamic>) {
            _users[key] = _UserRecord.fromJson(value);
          }
        });
      } catch (_) {
        await prefs.remove(_usersStorageKey);
        _users.clear();
      }
    }
    final currentUsername = prefs.getString(_currentUserKey);
    if (currentUsername != null) {
      _currentUser = _users[currentUsername]?.user;
    }
    _initialized = true;
  }

  Future<void> _persistUsers() async {
    final prefs = await _prefsFuture;
    final serializable = _users.map(
      (key, value) => MapEntry(key, value.toJson()),
    );
    await prefs.setString(_usersStorageKey, jsonEncode(serializable));
  }

  Future<void> _persistCurrentUser() async {
    final prefs = await _prefsFuture;
    if (_currentUser != null) {
      await prefs.setString(_currentUserKey, _currentUser!.username);
    } else {
      await prefs.remove(_currentUserKey);
    }
  }

  Future<AuthUser> register({
    required String username,
    required String password,
    String? email,
  }) async {
    await _ensureLoaded();
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (_users.containsKey(username)) {
      throw AuthException('Пользователь с таким никнеймом уже существует');
    }

    final user = AuthUser(
      id: 'local_${DateTime.now().microsecondsSinceEpoch}',
      username: username,
      email: email,
    );
    _users[username] = _UserRecord(user: user, password: password);
    _currentUser = user;
    await _persistUsers();
    await _persistCurrentUser();
    return user;
  }

  Future<AuthUser> login({
    required String login,
    required String password,
  }) async {
    await _ensureLoaded();
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final stored = _users[login];
    if (stored == null || stored.password != password) {
      throw AuthException('Неверный никнейм или пароль');
    }
    _currentUser = stored.user;
    await _persistCurrentUser();
    return stored.user;
  }

  Future<AuthUser?> restore() async {
    await _ensureLoaded();
    return _currentUser;
  }

  Future<void> logout() async {
    await _ensureLoaded();
    _currentUser = null;
    await _persistCurrentUser();
  }
}

class _UserRecord {
  const _UserRecord({required this.user, required this.password});
  final AuthUser user;
  final String password;

  Map<String, dynamic> toJson() => {
    'id': user.id,
    'username': user.username,
    'email': user.email,
    'password': password,
  };

  factory _UserRecord.fromJson(Map<String, dynamic> json) {
    return _UserRecord(
      user: AuthUser(
        id:
            json['id'] as String? ??
            'local_${DateTime.now().millisecondsSinceEpoch}',
        username: json['username'] as String? ?? 'unknown',
        email: json['email'] as String?,
      ),
      password: json['password'] as String? ?? '',
    );
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}
