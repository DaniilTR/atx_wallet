import 'package:flutter/foundation.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:bip32/bip32.dart' as bip32;
import 'package:hex/hex.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web3dart/web3dart.dart';

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

  /// Генерирует и логирует сид, приватный ключ и адрес (BSC/EVM путь).
  /// Используем только для демо/отладки: в продакшене нельзя печатать секреты.
  Future<void> logDemoKeysToConsole() async {
    final mnemonic = generateMnemonic();
    final privateKeyHex = await getPrivateKey(mnemonic);
    final address = await getPublicKey(privateKeyHex);

    debugPrint('--- ATX Wallet keys (BSC Testnet path $_derivationPath) ---');
    debugPrint('Seed phrase: $mnemonic');
    debugPrint('Private key (hex): 0x$privateKeyHex');
    debugPrint('Address: ${address.hexEip55}');
  }
}
