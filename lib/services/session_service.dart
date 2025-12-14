import 'dart:convert';
import 'dart:math';

import 'config.dart';

class SessionService {
  SessionService._();
  static final SessionService _instance = SessionService._();
  static SessionService get instance => _instance;

  String? _currentToken;
  DateTime? _expiresAt;
  DateTime? _issuedAt;

  String get token => _currentToken ?? _rotate();
  DateTime? get expiresAt => _expiresAt;

  String rotate() => _rotate();

  String buildQrPayload() {
    final payload = {
      'v': 1,
      'type': 'pair',
      'session': token,
      'issuedAt': _issuedAt?.toUtc().toIso8601String(),
      'expiresAt': _expiresAt?.toUtc().toIso8601String(),
      'relay': kRelayWsUrl,
      'device': 'desktop',
    };
    return jsonEncode(payload);
  }

  String _rotate() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    _currentToken = base64Url.encode(bytes).replaceAll('=', '');
    _issuedAt = DateTime.now().toUtc();
    _expiresAt = DateTime.now().add(const Duration(minutes: 5));
    return _currentToken!;
  }

  bool get isExpired => _expiresAt == null || DateTime.now().isAfter(_expiresAt!);
}
