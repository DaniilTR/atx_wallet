import 'dart:convert';
import 'dart:io' show Directory, File;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'package:atx_wallet/services/config.dart';

/// Структура профиля кошелька для DEV-режима.
/// Содержит секьюрные данные, хранить только локально и только в DEV.
class DevWalletProfile {
  final String userId;
  final String mnemonic; // BIP-39 seed phrase (12 слов)
  final String privateKeyHex; // 32 байта hex без 0x
  final String addressHex; // 0x... в EIP-55

  DevWalletProfile({
    required this.userId,
    required this.mnemonic,
    required this.privateKeyHex,
    required this.addressHex,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'mnemonic': mnemonic,
    'privateKeyHex': privateKeyHex,
    'addressHex': addressHex,
  };

  static DevWalletProfile fromJson(Map<String, dynamic> json) {
    return DevWalletProfile(
      userId: json['userId'] as String,
      mnemonic: json['mnemonic'] as String,
      privateKeyHex: json['privateKeyHex'] as String,
      addressHex: json['addressHex'] as String,
    );
  }
}

/// DEV-хранилище: сохраняет/читает профиль из JSON-файла на диске.
/// Для Flutter Web отправляет профиль на DEV-API, который сохраняет JSON на диске.
/// Никогда не использовать в продакшене, только при флаге dev=true.
class DevWalletStorage {
  final bool devEnabled;

  DevWalletStorage({required this.devEnabled});

  Uri _devWalletUri([String? userId]) {
    final base = kApiBaseUrl.endsWith('/')
        ? kApiBaseUrl.substring(0, kApiBaseUrl.length - 1)
        : kApiBaseUrl;
    final tail = userId == null
        ? '/api/dev-wallets'
        : '/api/dev-wallets/${Uri.encodeComponent(userId)}';
    return Uri.parse('$base$tail');
  }

  String _safeId(String userId) =>
      userId.replaceAll(RegExp(r'[^a-zA-Z0-9_.@-]'), '_');

  /// Папка для хранения DEV-файлов.
  Future<Directory> _getDevDir() async {
    final dir = await getApplicationSupportDirectory();
    final devDir = Directory('${dir.path}/dev_wallets');
    if (!await devDir.exists()) {
      await devDir.create(recursive: true);
    }
    return devDir;
  }

  /// Полный путь к файлу для userId.
  Future<String> _filePathFor(String userId) async {
    final devDir = await _getDevDir();
    // Имя файла: <userId>.wallet.json
    return '${devDir.path}/${_safeId(userId)}.wallet.json';
  }

  /// Сохранить профиль кошелька для userId.
  /// На мобильных/desktop — файл JSON. На вебе — HTTP-запрос к локальному DEV API.
  Future<void> saveProfile(DevWalletProfile profile) async {
    if (!devEnabled) return;
    final jsonStr = jsonEncode(profile.toJson());

    if (kIsWeb) {
      final response = await http.put(
        _devWalletUri(profile.userId),
        headers: const {'Content-Type': 'application/json'},
        body: jsonStr,
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'Failed to persist dev wallet: HTTP ${response.statusCode}',
        );
      }
      return;
    }

    final path = await _filePathFor(profile.userId);
    final file = File(path);
    await file.writeAsString(jsonStr, flush: true);
    debugPrint('[DEV] Wallet profile saved: $path');
  }

  /// Прочитать профиль кошелька для userId.
  Future<DevWalletProfile?> loadProfile(String userId) async {
    if (!devEnabled) return null;
    if (kIsWeb) {
      final response = await http.get(_devWalletUri(userId));
      if (response.statusCode == 404) return null;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'Failed to load dev wallet: HTTP ${response.statusCode}',
        );
      }
      final map = jsonDecode(response.body) as Map<String, dynamic>;
      return DevWalletProfile.fromJson(map);
    }

    final path = await _filePathFor(userId);
    final file = File(path);
    if (!await file.exists()) return null;
    final jsonStr = await file.readAsString();
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    return DevWalletProfile.fromJson(map);
  }

  /// Проверить, существует ли профиль.
  Future<bool> exists(String userId) async {
    if (!devEnabled) return false;
    if (kIsWeb) {
      final response = await http.head(_devWalletUri(userId));
      if (response.statusCode == 200) return true;
      if (response.statusCode == 404) return false;
      throw Exception(
        'Failed to check dev wallet: HTTP ${response.statusCode}',
      );
    }
    final path = await _filePathFor(userId);
    final file = File(path);
    return file.exists();
  }

  /// Удалить профиль (для очистки во время тестов).
  Future<void> deleteProfile(String userId) async {
    if (!devEnabled) return;
    if (kIsWeb) {
      final response = await http.delete(_devWalletUri(userId));
      if (response.statusCode == 404 ||
          response.statusCode == 204 ||
          response.statusCode == 200) {
        return;
      }
      throw Exception(
        'Failed to delete dev wallet: HTTP ${response.statusCode}',
      );
    }
    final path = await _filePathFor(userId);
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
      debugPrint('[DEV] Wallet profile deleted: $path');
    }
  }
}
