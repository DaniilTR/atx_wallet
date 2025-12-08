import 'package:flutter/foundation.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:bip32/bip32.dart' as bip32;
import 'package:hex/hex.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web3dart/web3dart.dart';
import '../dev/dev_wallet_storage.dart';

// Интерфейс для сервиса генерации и получения ключей/адреса.
abstract class WalletAddressService {
  String generateMnemonic();
  Future<String> getPrivateKey(String mnemonic);
  Future<EthereumAddress> getPublicKey(String privateKey);
}

class WalletProvider extends ChangeNotifier implements WalletAddressService {
  // Храним приватный ключ в памяти (краткосрочно) для уведомлений UI.
  String? privateKey;

  // Стандартный путь BIP44 для EVM/BSC: m/44'/60'/0'/0/0.
  static const String _derivationPath = "m/44'/60'/0'/0/0";

  // DEV storage (в проде devEnabled=false).
  final DevWalletStorage devStorage;

  DevWalletProfile? _activeProfile;
  DevWalletProfile? get activeProfile => _activeProfile;

  bool get devEnabled => devStorage.devEnabled;

  WalletProvider({bool devEnabled = false})
    : devStorage = DevWalletStorage(devEnabled: devEnabled);

  // Загрузить приватный ключ из SharedPreferences (dev-сторона, без шифрования).
  Future<void> loadPrivateKey() async {
    final prefs = await SharedPreferences.getInstance();
    privateKey = prefs.getString('privateKey');
  }

  // Сохранить приватный ключ в SharedPreferences и уведомить слушателей.
  Future<void> setPrivateKey(String privateKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('privateKey', privateKey);
    this.privateKey = privateKey;
    notifyListeners();
  }

  @override
  String generateMnemonic() {
    // Генерация сид-фразы (12 слов, 128 бит энтропии) по BIP-39.
    return bip39.generateMnemonic();
  }

  @override
  Future<String> getPrivateKey(String mnemonic) async {
    // Превращаем сид-фразу в seed (512 бит), строим master key и деривируем по пути BIP44.
    final seed = bip39.mnemonicToSeed(mnemonic);
    final root = bip32.BIP32.fromSeed(seed);
    final child = root.derivePath(_derivationPath);

    // Достаём 32-байтный приватный ключ и кодируем в hex.
    final derived = child.privateKey!;
    final privateKeyHex = HEX.encode(derived);

    // Кладём в локальное (dev) хранилище, чтобы можно было показать в UI/консоли.
    await setPrivateKey(privateKeyHex);
    return privateKeyHex;
  }

  @override
  Future<EthereumAddress> getPublicKey(String privateKey) async {
    // Создаём объект приватного ключа web3dart и извлекаем адрес (EIP-55 checksum).
    final private = EthPrivateKey.fromHex(privateKey);
    final address = await private.address;
    return address;
  }

  /// DEV-режим: создать кошелёк и сохранить профиль для userId.
  /// Вызывается ТОЛЬКО в момент регистрации. На авторизации НЕ вызываем.
  Future<DevWalletProfile?> generateAndPersistForUser(String userId) async {
    if (!devStorage.devEnabled) return null;

    // Если профиль уже есть (перерегистрация) — не создаём заново.
    final exists = await devStorage.exists(userId);
    if (exists) {
      final existing = await devStorage.loadProfile(userId);
      _setActiveProfile(existing);
      if (existing != null) {
        privateKey = existing.privateKeyHex;
      }
      return existing;
    }

    final mnemonic = generateMnemonic();
    final privateKeyHex = await getPrivateKey(mnemonic);
    final address = await getPublicKey(privateKeyHex);

    final profile = DevWalletProfile(
      userId: userId,
      mnemonic: mnemonic,
      privateKeyHex: privateKeyHex,
      addressHex: address.hexEip55,
    );

    await devStorage.saveProfile(profile);
    _setActiveProfile(profile);
    return profile;
  }

  /// Получить профиль из DEV-хранилища по userId (для главного экрана).
  Future<DevWalletProfile?> loadDevProfile(String userId) async {
    if (!devStorage.devEnabled) return null;
    final profile = await devStorage.loadProfile(userId);
    _setActiveProfile(profile);
    if (profile != null) {
      privateKey = profile.privateKeyHex;
    }
    return profile;
  }

  void clearDevProfile() {
    if (_activeProfile == null) return;
    _activeProfile = null;
    privateKey = null;
    notifyListeners();
  }

  void _setActiveProfile(DevWalletProfile? profile) {
    if (_activeProfile == null && profile == null) return;
    if (identical(_activeProfile, profile)) return;
    _activeProfile = profile;
    notifyListeners();
  }
}
