// lib/services/auth_service.dart
// Локальный сервис аутентификации с хранением данных на устройстве
import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

import '../WalletSecureStorage/password_kdf.dart';
import '../WalletSecureStorage/random_bytes.dart';
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

    final salt = await secureRandomBytes(PasswordKdf.defaultSaltBytes);
    final verifier = await PasswordKdf.deriveVerifier(
      password: password,
      salt: salt,
      iterations: PasswordKdf.defaultIterations,
    );

    _users[username] = _UserRecord(
      user: user,
      passwordAlg: PasswordKdf.alg,
      passwordIterations: PasswordKdf.defaultIterations,
      passwordSaltB64: base64Encode(salt),
      passwordVerifierB64: base64Encode(verifier),
    );
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

    if (stored == null) {
      throw AuthException('Неверный никнейм или пароль');
    }

    // Миграция legacy plaintext записей (если остались в prefs).
    if (stored.legacyPassword != null) {
      if (stored.legacyPassword != password) {
        throw AuthException('Неверный никнейм или пароль');
      }
      final salt = await secureRandomBytes(PasswordKdf.defaultSaltBytes);
      final verifier = await PasswordKdf.deriveVerifier(
        password: password,
        salt: salt,
        iterations: PasswordKdf.defaultIterations,
      );
      final upgraded = stored.copyWith(
        legacyPassword: null,
        passwordAlg: PasswordKdf.alg,
        passwordIterations: PasswordKdf.defaultIterations,
        passwordSaltB64: base64Encode(salt),
        passwordVerifierB64: base64Encode(verifier),
      );
      _users[login] = upgraded;
      await _persistUsers();
    } else {
      final salt = base64Decode(stored.passwordSaltB64);
      final verifier = await PasswordKdf.deriveVerifier(
        password: password,
        salt: Uint8List.fromList(salt),
        iterations: stored.passwordIterations,
      );
      final storedVerifier = base64Decode(stored.passwordVerifierB64);
      if (!PasswordKdf.constantTimeEquals(
        Uint8List.fromList(storedVerifier),
        verifier,
      )) {
        throw AuthException('Неверный никнейм или пароль');
      }
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
  const _UserRecord({
    required this.user,
    required this.passwordAlg,
    required this.passwordIterations,
    required this.passwordSaltB64,
    required this.passwordVerifierB64,
    this.legacyPassword,
  });

  final AuthUser user;
  final String passwordAlg;
  final int passwordIterations;
  final String passwordSaltB64;
  final String passwordVerifierB64;
  final String? legacyPassword;

  _UserRecord copyWith({
    AuthUser? user,
    String? passwordAlg,
    int? passwordIterations,
    String? passwordSaltB64,
    String? passwordVerifierB64,
    String? legacyPassword,
  }) {
    return _UserRecord(
      user: user ?? this.user,
      passwordAlg: passwordAlg ?? this.passwordAlg,
      passwordIterations: passwordIterations ?? this.passwordIterations,
      passwordSaltB64: passwordSaltB64 ?? this.passwordSaltB64,
      passwordVerifierB64: passwordVerifierB64 ?? this.passwordVerifierB64,
      legacyPassword: legacyPassword,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': user.id,
    'username': user.username,
    'email': user.email,
    'password': legacyPassword,
    'passwordAlg': passwordAlg,
    'passwordIterations': passwordIterations,
    'passwordSaltB64': passwordSaltB64,
    'passwordVerifierB64': passwordVerifierB64,
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
      legacyPassword: json['password'] as String?,
      passwordAlg: (json['passwordAlg'] as String?) ?? PasswordKdf.alg,
      passwordIterations:
          (json['passwordIterations'] as num?)?.toInt() ??
          PasswordKdf.defaultIterations,
      passwordSaltB64: (json['passwordSaltB64'] as String?) ?? '',
      passwordVerifierB64: (json['passwordVerifierB64'] as String?) ?? '',
    );
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}
