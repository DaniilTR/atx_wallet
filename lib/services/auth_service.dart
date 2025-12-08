// lib/services/auth_service.dart
// Локальный сервис аутентификации (in-memory)
import 'auth_user.dart';

class AuthService {
  final Map<String, _UserRecord> _users = {};
  AuthUser? _currentUser;

  bool get isAuthenticated => _currentUser != null;
  AuthUser? get currentUser => _currentUser;

  Future<AuthUser> register({
    required String username,
    required String password,
    String? email,
  }) async {
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
    return user;
  }

  Future<AuthUser> login({
    required String login,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final stored = _users[login];
    if (stored == null || stored.password != password) {
      throw AuthException('Неверный никнейм или пароль');
    }
    _currentUser = stored.user;
    return stored.user;
  }

  Future<void> logout() async {
    _currentUser = null;
  }
}

class _UserRecord {
  const _UserRecord({required this.user, required this.password});
  final AuthUser user;
  final String password;
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}
