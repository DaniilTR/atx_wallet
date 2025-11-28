class AuthService {
  // Dummy in-memory users. Key: username, Value: password.
  final Map<String, String> _users = {};
  String? _currentUsername;

  bool get isAuthenticated => _currentUsername != null;
  String? get currentUsername => _currentUsername;

  Future<void> register({required String username, required String password, String? email}) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (_users.containsKey(username)) {
      throw AuthException('Пользователь с таким никнеймом уже существует');
    }
    _users[username] = password;
    _currentUsername = username;
  }

  Future<void> login({required String login, required String password}) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final stored = _users[login];
    if (stored == null || stored != password) {
      throw AuthException('Неверный никнейм или пароль');
    }
    _currentUsername = login;
  }

  Future<void> logout() async {
    _currentUsername = null;
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}
