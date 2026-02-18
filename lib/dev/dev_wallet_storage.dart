import 'dart:convert';
import 'dart:io' show Directory, File;

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Структура профиля кошелька для DEV-режима.
/// Содержит секьюрные данные, хранить только локально и только в DEV.
class DevWalletProfile {
  /// Уникальный идентификатор кошелька внутри одного пользователя.
  /// Нужен для поддержки нескольких кошельков (счетов) на одного пользователя.
  final String walletId;

  /// Отображаемое имя кошелька.
  final String name;

  final String userId;
  final String mnemonic; // BIP-39 seed phrase (12 слов)
  final String privateKeyHex; // 32 байта hex без 0x
  final String addressHex; // 0x... в EIP-55

  DevWalletProfile({
    required this.walletId,
    required this.name,
    required this.userId,
    required this.mnemonic,
    required this.privateKeyHex,
    required this.addressHex,
  });

  /// Ключ для истории/стореджей, чтобы разные кошельки не пересекались.
  /// Формат безопасен для файловой системы (и серверного safeId).
  String get storageId => '${userId}__${walletId}';

  Map<String, dynamic> toJson() => {
    'walletId': walletId,
    'name': name,
    'userId': userId,
    'mnemonic': mnemonic,
    'privateKeyHex': privateKeyHex,
    'addressHex': addressHex,
  };

  static DevWalletProfile fromJson(Map<String, dynamic> json) {
    final userId = json['userId'] as String;
    final walletId = (json['walletId'] as String?) ?? userId;
    final name = (json['name'] as String?) ?? 'Кошелёк';
    return DevWalletProfile(
      walletId: walletId,
      name: name,
      userId: userId,
      mnemonic: (json['mnemonic'] as String?) ?? '',
      privateKeyHex: (json['privateKeyHex'] as String?) ?? '',
      addressHex: (json['addressHex'] as String?) ?? '',
    );
  }
}

class DevWalletBundle {
  DevWalletBundle({
    required this.activeWalletId,
    required List<DevWalletProfile> wallets,
  }) : wallets = List.unmodifiable(wallets);

  final String activeWalletId;
  final List<DevWalletProfile> wallets;

  DevWalletBundle copyWith({
    String? activeWalletId,
    List<DevWalletProfile>? wallets,
  }) {
    return DevWalletBundle(
      activeWalletId: activeWalletId ?? this.activeWalletId,
      wallets: wallets ?? this.wallets,
    );
  }

  Map<String, dynamic> toJson() => {
    'version': 2,
    'activeWalletId': activeWalletId,
    'wallets': wallets.map((e) => e.toJson()).toList(growable: false),
  };

  static DevWalletBundle fromJson(Map<String, dynamic> json) {
    final rawWallets = (json['wallets'] as List<dynamic>?);
    final wallets = (rawWallets ?? const <dynamic>[])
        .cast<Map<String, dynamic>>()
        .map(DevWalletProfile.fromJson)
        .where((w) => w.userId.isNotEmpty && w.walletId.isNotEmpty)
        .toList(growable: false);
    final active =
        (json['activeWalletId'] as String?) ??
        (wallets.isNotEmpty ? wallets.first.walletId : '');
    return DevWalletBundle(activeWalletId: active, wallets: wallets);
  }
}

/// DEV-хранилище: сохраняет/читает профиль из JSON-файла на диске.
/// Для Flutter Web отправляет профиль на DEV-API, который сохраняет JSON на диске.
/// Никогда не использовать в продакшене, только при флаге dev=true.
class DevWalletStorage {
  final bool devEnabled;

  DevWalletStorage({required this.devEnabled});

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
    // Для совместимости: saveProfile сохраняет bundle с одним активным кошельком.
    final jsonStr = jsonEncode(
      DevWalletBundle(
        activeWalletId: profile.walletId,
        wallets: [profile],
      ).toJson(),
    );

    if (kIsWeb)
      throw UnsupportedError(
        'DevWalletStorage is not supported on Web without a server',
      );

    final path = await _filePathFor(profile.userId);
    final file = File(path);
    await file.writeAsString(jsonStr, flush: true);
    debugPrint('[DEV] Wallet profile saved: $path');
  }

  /// Прочитать профиль кошелька для userId.
  Future<DevWalletProfile?> loadProfile(String userId) async {
    if (!devEnabled) return null;
    final bundle = await loadBundle(userId);
    if (bundle == null) return null;
    final active = bundle.wallets.firstWhere(
      (w) => w.walletId == bundle.activeWalletId,
      orElse: () => bundle.wallets.isEmpty
          ? DevWalletProfile(
              walletId: userId,
              name: 'Кошелёк',
              userId: userId,
              mnemonic: '',
              privateKeyHex: '',
              addressHex: '',
            )
          : bundle.wallets.first,
    );
    if (active.addressHex.isEmpty) return null;
    return active;
  }

  Future<void> saveBundle(String userId, DevWalletBundle bundle) async {
    if (!devEnabled) return;
    final jsonStr = jsonEncode(bundle.toJson());

    if (kIsWeb)
      throw UnsupportedError(
        'DevWalletStorage is not supported on Web without a server',
      );

    final path = await _filePathFor(userId);
    final file = File(path);
    await file.writeAsString(jsonStr, flush: true);
    debugPrint('[DEV] Wallet bundle saved: $path');
  }

  Future<DevWalletBundle?> loadBundle(String userId) async {
    if (!devEnabled) return null;
    Map<String, dynamic>? map;

    if (kIsWeb) {
      throw UnsupportedError(
        'DevWalletStorage is not supported on Web without a server',
      );
    } else {
      final path = await _filePathFor(userId);
      final file = File(path);
      if (!await file.exists()) return null;
      final jsonStr = await file.readAsString();
      map = jsonDecode(jsonStr) as Map<String, dynamic>;
    }

    if (map.containsKey('wallets')) {
      return DevWalletBundle.fromJson(map);
    }

    // Старый формат (один профиль) — апгрейдим до bundle.
    final single = DevWalletProfile.fromJson(map);
    final upgraded = DevWalletBundle(
      activeWalletId: single.walletId,
      wallets: [single],
    );
    // Пишем обратно, чтобы дальше было единообразно.
    await saveBundle(userId, upgraded);
    return upgraded;
  }

  Future<List<DevWalletProfile>> loadWallets(String userId) async {
    final bundle = await loadBundle(userId);
    return bundle?.wallets ?? const <DevWalletProfile>[];
  }

  Future<void> setActiveWallet(String userId, String walletId) async {
    final bundle = await loadBundle(userId);
    if (bundle == null) return;
    if (!bundle.wallets.any((w) => w.walletId == walletId)) return;
    await saveBundle(userId, bundle.copyWith(activeWalletId: walletId));
  }

  Future<void> addWallet(
    String userId,
    DevWalletProfile profile, {
    bool makeActive = true,
  }) async {
    final existing = await loadBundle(userId);
    final wallets = <DevWalletProfile>[...(existing?.wallets ?? const [])]
      ..removeWhere((w) => w.walletId == profile.walletId)
      ..add(profile);
    final activeWalletId = makeActive
        ? profile.walletId
        : (existing?.activeWalletId ??
              (wallets.isNotEmpty ? wallets.first.walletId : profile.walletId));
    await saveBundle(
      userId,
      DevWalletBundle(activeWalletId: activeWalletId, wallets: wallets),
    );
  }

  /// Проверить, существует ли профиль.
  Future<bool> exists(String userId) async {
    if (!devEnabled) return false;
    if (kIsWeb)
      throw UnsupportedError(
        'DevWalletStorage is not supported on Web without a server',
      );
    final path = await _filePathFor(userId);
    final file = File(path);
    return file.exists();
  }

  /// Удалить профиль (для очистки во время тестов).
  Future<void> deleteProfile(String userId) async {
    if (!devEnabled) return;
    if (kIsWeb)
      throw UnsupportedError(
        'DevWalletStorage is not supported on Web without a server',
      );
    final path = await _filePathFor(userId);
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
      debugPrint('[DEV] Wallet profile deleted: $path');
    }
  }
}
