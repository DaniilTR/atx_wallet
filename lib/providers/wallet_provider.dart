import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:bip32/bip32.dart' as bip32;
import 'package:bip39/bip39.dart' as bip39;
import 'package:cryptography/cryptography.dart' show SecretKey;
import 'package:flutter/foundation.dart';
import 'package:hex/hex.dart';
import 'package:web3dart/web3dart.dart';

import '../WalletSecureStorage/random_bytes.dart';
import '../WalletSecureStorage/secure_wallet_vault.dart';
import '../WalletSecureStorage/wallet_vault_models.dart';
import '../WalletSecureStorage/history_model/transaction_record.dart';
import '../WalletSecureStorage/history_model/transaction_storage.dart';
import '../services/asset_price_service.dart';
import '../services/bitcoin_service.dart';
import '../services/blockchain_service.dart';
import '../services/config.dart';

/// Интерфейс для генерации сид-фразы и получения EVM-ключей/адреса.
///
/// Примечание:
/// - BTC адрес и баланс живут отдельно (см. `BitcoinService`).
abstract class WalletAddressService {
  String generateMnemonic();
  Future<String> getPrivateKey(String mnemonic);
  Future<EthereumAddress> getPublicKey(String privateKey);
}

/// Метаданные отслеживаемого актива.
///
/// Зачем отдельная модель:
/// - UI и провайдер должны знать символ, decimals и тип актива;
/// - EVM ERC-20 требует `contractAddress`, а BTC — нет;
/// - цены подтягиваются по `coinGeckoId`.
class TokenMetadata {
  const TokenMetadata({
    required this.symbol,
    required this.name,
    required this.kind,
    this.contractAddress,
    this.decimalsHint = 18,
    this.fetchDecimalsFromChain = false,
    this.coinGeckoId,
  }) : assert(
         kind == AssetKind.bitcoin ||
             kind == AssetKind.evmNative ||
             contractAddress != null,
         'ERC-20 токен требует contractAddress',
       );

  final String symbol;
  final String name;
  final AssetKind kind;
  final String? contractAddress;
  final int decimalsHint;
  final bool fetchDecimalsFromChain;
  final String? coinGeckoId;

  bool get isBitcoin => kind == AssetKind.bitcoin;
  bool get isEvm => kind != AssetKind.bitcoin;
  bool get isNative => kind == AssetKind.evmNative;
  bool get isErc20 => kind == AssetKind.evmErc20;
}

/// Публичный профиль кошелька для UI.
///
/// Важно:
/// - не содержит сид-фразы и приватных ключей (в отличие от DEV-режима);
/// - используется как «метка», какой кошелёк выбран и по какому ключу
///   хранить историю операций.
class WalletProfile {
  const WalletProfile({
    required this.walletId,
    required this.name,
    required this.userId,
    required this.addressHex,
  });

  final String walletId;
  final String name;
  final String userId;
  final String addressHex;

  /// Идентификатор для привязки локальной истории.
  ///
  /// Делаем ключ стабильным и уникальным в пределах пользователя.
  String get storageId => '${userId}__${walletId}';
}

enum AssetKind { evmNative, evmErc20, bitcoin }

enum FeeStatus { ok, insufficientFee }

class SendPreflightResult {
  const SendPreflightResult({
    required this.token,
    required this.recipient,
    required this.amount,
    required this.networkLabel,
    required this.feeStatus,
    required this.feeLabel,
    required this.speedLabel,
    required this.canSend,
    this.feeWarningText,
    this.amountUsdLabel,
  });

  final TokenMetadata token;
  final String recipient;
  final double amount;
  final String networkLabel;

  /// Цвет/статус строки «Комиссия сети».
  ///
  /// Сейчас используем красный только когда не хватает ETH для оплаты gas.
  final FeeStatus feeStatus;

  /// Готовая строка комиссии для UI (например: "0,31 $  0.000123 ETH").
  final String feeLabel;

  /// Подсказка про скорость (например: "Рынок ~12 сек.").
  final String speedLabel;

  /// Можно ли отправлять транзакцию прямо сейчас.
  ///
  /// Включает проверки: достаточный баланс актива и достаточный ETH для комиссии.
  final bool canSend;

  /// Текст для предупреждения, если `feeStatus == insufficientFee`.
  final String? feeWarningText;

  /// Метка USD-оценки суммы перевода (например "1,00 $").
  final String? amountUsdLabel;
}

/// Баланс конкретного актива.
///
/// `raw` хранится в базовых единицах:
/// - для EVM: wei / минимальные единицы токена
/// - для BTC: сатоши
///
/// `priceUsd` — цена **в USD-оценке по курсу USDT** (см. `refreshBalances`).
class AssetBalance {
  const AssetBalance({
    required this.token,
    required this.raw,
    required this.decimals,
    this.priceUsd,
  });

  final TokenMetadata token;
  final BigInt raw;
  final int decimals;
  final double? priceUsd;

  double get amount {
    if (raw == BigInt.zero) return 0;
    final divisor = math.pow(10, decimals).toDouble();
    return raw.toDouble() / divisor;
  }

  double? get usdValue {
    final price = priceUsd;
    if (price == null) return null;
    return amount * price;
  }
}

class WalletBalances {
  WalletBalances({
    required List<AssetBalance> assets,
    this.updatedAt,
    this.isLoading = false,
    this.error,
  }) : assets = List.unmodifiable(assets);

  final List<AssetBalance> assets;
  final DateTime? updatedAt;
  final bool isLoading;
  final String? error;

  double? get totalUsd {
    var sum = 0.0;
    var hasAny = false;
    for (final asset in assets) {
      final v = asset.usdValue;
      if (v == null) continue;
      sum += v;
      hasAny = true;
    }
    return hasAny ? sum : null;
  }

  WalletBalances copyWith({
    List<AssetBalance>? assets,
    bool? isLoading,
    bool clearError = false,
    String? error,
    DateTime? updatedAt,
  }) {
    return WalletBalances(
      assets: assets ?? this.assets,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory WalletBalances.initial(List<TokenMetadata> tokens) {
    return WalletBalances(
      assets: tokens
          .map(
            (token) => AssetBalance(
              token: token,
              raw: BigInt.zero,
              decimals: token.decimalsHint,
            ),
          )
          .toList(growable: false),
    );
  }
}

const List<TokenMetadata> kTrackedTokens = <TokenMetadata>[
  TokenMetadata(
    symbol: 'USDT',
    name: 'Tether USD',
    kind: AssetKind.evmErc20,
    // USDT в сети Ethereum (основная сеть, ERC-20).
    // Важно: адрес контракта должен быть адресом основной сети.
    contractAddress: '0xdAC17F958D2ee523a2206206994597C13D831ec7',
    decimalsHint: 6,
    fetchDecimalsFromChain: false,
    coinGeckoId: 'tether',
  ),
  TokenMetadata(
    symbol: 'ETH',
    name: 'Ethereum',
    kind: AssetKind.evmNative,
    decimalsHint: 18,
    coinGeckoId: 'ethereum',
  ),
  TokenMetadata(
    symbol: 'BTC',
    name: 'Bitcoin',
    kind: AssetKind.bitcoin,
    decimalsHint: 8,
    coinGeckoId: 'bitcoin',
  ),
];

class WalletProvider extends ChangeNotifier implements WalletAddressService {
  WalletProvider({
    BlockchainService? blockchainService,
    BitcoinService? bitcoinService,
    AssetPriceService? assetPriceService,
    TransactionStorage? transactionStorage,
  }) : blockchain = blockchainService ?? BlockchainService(),
       bitcoin = bitcoinService ?? BitcoinService(),
       prices = assetPriceService ?? AssetPriceService(),
       historyStorage = transactionStorage ?? TransactionStorage();

  // Приватный ключ EVM хранится только в памяти текущей сессии.
  // В secure-режиме он деривируется из сид-фразы при разблокировке/переключении и не пишется в диск.
  String? privateKey;

  // Стандартный BIP44-путь для EVM (coin type 60): m/44'/60'/0'/0/0.
  // Используется для деривации приватного ключа EVM из сид-фразы.
  static const String _derivationPath = "m/44'/60'/0'/0/0";
  static const Duration _autoRefreshInterval = Duration(seconds: 45);

  final BlockchainService blockchain;
  final BitcoinService bitcoin;
  final AssetPriceService prices;
  final TransactionStorage historyStorage;

  final SecureWalletVault _secureVault = SecureWalletVault();
  WalletVaultBundle? _secureBundle;
  SecretKey? _secureKey;

  WalletProfile? _activeProfile;
  WalletProfile? get activeProfile => _activeProfile;

  /// В secure-режиме ключ бандла установлен только после `unlockSecureWallets`.
  bool get isUnlocked => _secureKey != null;

  String? _activeUserId;
  List<WalletProfile> _wallets = const <WalletProfile>[];
  UnmodifiableListView<WalletProfile> get wallets =>
      UnmodifiableListView(_wallets);

  WalletBalances _balances = WalletBalances.initial(kTrackedTokens);
  WalletBalances get balances => _balances;
  List<TokenMetadata> get supportedTokens => kTrackedTokens;

  String? _bitcoinAddress;
  String? get bitcoinAddress => _bitcoinAddress;

  // Приватный ключ BTC (WIF) хранится только в памяти текущей сессии.
  // Используется для подписи P2PKH транзакций.
  String? _bitcoinPrivateKeyWif;

  Timer? _balanceTimer;
  bool _hasBalanceSnapshot = false;

  static const int _historyLimit = 100;
  int _historyCounter = 0;

  List<TransactionRecord> _history = const <TransactionRecord>[];
  bool _historyLoading = false;
  String? _historyError;

  UnmodifiableListView<TransactionRecord> get history =>
      UnmodifiableListView(_history);
  bool get historyLoading => _historyLoading;
  String? get historyError => _historyError;

  bool get isWalletReady =>
      _activeProfile?.addressHex != null && privateKey != null;

  String? get activeUserId => _activeUserId;

  void _setPrivateKeyInMemory(String? value) {
    privateKey = value;
  }

  void _setBitcoinAddressInMemory(String? value) {
    _bitcoinAddress = value;
  }

  void _setBitcoinPrivateKeyWifInMemory(String? value) {
    _bitcoinPrivateKeyWif = value;
  }

  void _updateDerivedAddressesFromMnemonic(String mnemonic) {
    // BTC-адрес деривируется из сид-фразы и держится в памяти.
    // Мы не сохраняем BTC-адрес в постоянное хранилище: при следующей разблокировке
    // он будет восстановлен повторно.
    try {
      _setBitcoinAddressInMemory(
        bitcoin.deriveMainnetAddressFromMnemonic(mnemonic),
      );
      _setBitcoinPrivateKeyWifInMemory(
        bitcoin.deriveMainnetPrivateKeyWifFromMnemonic(mnemonic),
      );
    } catch (_) {
      _setBitcoinAddressInMemory(null);
      _setBitcoinPrivateKeyWifInMemory(null);
    }
  }

  @override
  String generateMnemonic() {
    // Генерация сид-фразы (12 слов, 128 бит энтропии) по BIP-39.
    return bip39.generateMnemonic();
  }

  @override
  Future<String> getPrivateKey(String mnemonic) async {
    // Превращаем сид-фразу в сид (512 бит), строим мастер-ключ и деривируем по пути BIP44.
    final seed = bip39.mnemonicToSeed(mnemonic);
    final root = bip32.BIP32.fromSeed(seed);
    final child = root.derivePath(_derivationPath);

    // Достаём 32-байтный приватный ключ и кодируем в hex.
    final derived = child.privateKey!;
    final privateKeyHex = HEX.encode(derived);

    return privateKeyHex;
  }

  Future<void> unlockSecureWallets({
    required String userId,
    required String password,
  }) async {
    SecureWalletVault.assertWebPolicy(devAllowed: kEnableDevWalletStorage);

    final bundle = await _secureVault.loadBundle(userId);
    if (bundle == null || bundle.wallets.isEmpty) {
      throw StateError('Кошелёк не найден. Создайте новый.');
    }

    final key = await _secureVault.deriveBundleKey(
      bundle: bundle,
      password: password,
    );
    _secureKey = key;
    _secureBundle = bundle;
    _activeUserId = userId;

    final profiles = bundle.wallets
        .where((e) => e.userId.isNotEmpty && e.walletId.isNotEmpty)
        .map(
          (e) => WalletProfile(
            walletId: e.walletId,
            name: e.name,
            userId: e.userId,
            addressHex: e.addressHex,
          ),
        )
        .toList(growable: false);
    _wallets = List.unmodifiable(profiles);

    final activeId = bundle.activeWalletId.isNotEmpty
        ? bundle.activeWalletId
        : (bundle.wallets.isNotEmpty ? bundle.wallets.first.walletId : '');
    final activeEntry = bundle.wallets.firstWhere(
      (w) => w.walletId == activeId,
      orElse: () => bundle.wallets.first,
    );
    final mnemonic = await _secureVault.decryptMnemonic(
      key: key,
      entry: activeEntry,
    );
    if (!bip39.validateMnemonic(mnemonic.trim())) {
      throw StateError('Повреждённое хранилище: seed невалиден');
    }
    final pk = await getPrivateKey(mnemonic);
    _setPrivateKeyInMemory(pk);
    _updateDerivedAddressesFromMnemonic(mnemonic);

    final activeProfile = profiles.firstWhere(
      (p) => p.walletId == activeEntry.walletId,
      orElse: () => profiles.first,
    );
    _setActiveProfile(activeProfile);
    await refreshBalances(silent: true);
    await _loadHistoryFromStorage(silent: true);
    notifyListeners();
  }

  Future<void> createInitialSecureWallet({
    required String userId,
    required String password,
    String name = 'Кошелёк 1',
  }) async {
    SecureWalletVault.assertWebPolicy(devAllowed: kEnableDevWalletStorage);

    final existing = await _secureVault.loadBundle(userId);
    if (existing != null && existing.wallets.isNotEmpty) {
      await unlockSecureWallets(userId: userId, password: password);
      return;
    }

    final salt = await secureRandomBytes(16);
    final empty = await _secureVault.createEmptyBundle(
      password: password,
      salt: salt,
    );
    final key = await _secureVault.deriveBundleKey(
      bundle: empty,
      password: password,
    );

    final mnemonic = generateMnemonic();
    final pk = await getPrivateKey(mnemonic);
    final address = await getPublicKey(pk);
    _updateDerivedAddressesFromMnemonic(mnemonic);
    final walletId = _newWalletId();

    final entry = await _secureVault.encryptMnemonic(
      key: key,
      userId: userId,
      walletId: walletId,
      name: name,
      addressHex: address.hexEip55,
      mnemonic: mnemonic,
    );

    final bundle = WalletVaultBundle(
      version: empty.version,
      createdAtIso: empty.createdAtIso,
      kdf: empty.kdf,
      activeWalletId: walletId,
      wallets: <WalletVaultEntry>[entry],
    );

    await _secureVault.saveBundle(userId, bundle);
    _secureKey = key;
    _secureBundle = bundle;

    // Обновляем состояние как после разблокировки.
    _activeUserId = userId;
    _setPrivateKeyInMemory(pk);
    // BTC-адрес уже был деривирован выше.
    _wallets = List.unmodifiable([
      WalletProfile(
        walletId: walletId,
        name: name,
        userId: userId,
        addressHex: address.hexEip55,
      ),
    ]);
    _setActiveProfile(_wallets.first);
    await refreshBalances(silent: true);
    await _loadHistoryFromStorage(silent: true);
    notifyListeners();
  }

  /// Возвращает сид-фразу активного кошелька.
  ///
  /// Требует пароль: в secure-режиме используется для деривации ключа и
  /// расшифровки сид-фразы из `flutter_secure_storage`.
  Future<String> revealActiveMnemonic({
    required String userId,
    required String password,
  }) async {
    SecureWalletVault.assertWebPolicy(devAllowed: kEnableDevWalletStorage);

    final bundle = await _secureVault.loadBundle(userId);
    if (bundle == null || bundle.wallets.isEmpty) {
      throw StateError('Кошелёк не найден');
    }

    final key = await _secureVault.deriveBundleKey(
      bundle: bundle,
      password: password,
    );

    final activeId = bundle.activeWalletId.isNotEmpty
        ? bundle.activeWalletId
        : (bundle.wallets.isNotEmpty ? bundle.wallets.first.walletId : '');
    final entry = bundle.wallets.firstWhere(
      (w) => w.walletId == activeId,
      orElse: () => bundle.wallets.first,
    );

    final mnemonic = await _secureVault.decryptMnemonic(key: key, entry: entry);
    final normalized = mnemonic.trim().toLowerCase().replaceAll(
      RegExp(r'\s+'),
      ' ',
    );
    if (!bip39.validateMnemonic(normalized)) {
      throw StateError('Повреждённое хранилище: seed невалиден');
    }
    return normalized;
  }

  @override
  Future<EthereumAddress> getPublicKey(String privateKey) async {
    // Создаём объект приватного ключа web3dart и извлекаем адрес (EIP-55 с контрольной суммой).
    final private = EthPrivateKey.fromHex(privateKey);
    final address = private.address;
    return address;
  }

  String _newWalletId() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final salt = math.Random().nextInt(1 << 30);
    return 'w${now.toRadixString(16)}${salt.toRadixString(16)}';
  }

  Future<WalletProfile> createNewWallet({
    required String userId,
    String? name,
    bool makeActive = true,
  }) async {
    final key = _secureKey;
    final bundle = _secureBundle;
    if (key == null || bundle == null || _activeUserId != userId) {
      throw StateError('Сначала войдите и разблокируйте кошелёк');
    }

    final mnemonic = generateMnemonic();
    return importWalletFromMnemonic(
      userId: userId,
      mnemonic: mnemonic,
      name: name,
      walletId: _newWalletId(),
      makeActive: makeActive,
    );
  }

  Future<WalletProfile> importWalletFromMnemonic({
    required String userId,
    required String mnemonic,
    String? name,
    String? walletId,
    bool makeActive = true,
  }) async {
    final normalized = mnemonic.trim().toLowerCase().replaceAll(
      RegExp(r'\s+'),
      ' ',
    );
    if (!bip39.validateMnemonic(normalized)) {
      throw ArgumentError('Некорректная сид-фраза');
    }

    final id = walletId ?? _newWalletId();
    final privateKeyHex = await getPrivateKey(normalized);
    final address = await getPublicKey(privateKeyHex);
    final displayName = (name == null || name.trim().isEmpty)
        ? 'Кошелёк'
        : name.trim();

    final key = _secureKey;
    final existingBundle = _secureBundle;
    if (key == null || existingBundle == null || _activeUserId != userId) {
      throw StateError('Сначала войдите и разблокируйте кошелёк');
    }

    final entry = await _secureVault.encryptMnemonic(
      key: key,
      userId: userId,
      walletId: id,
      name: displayName,
      addressHex: address.hexEip55,
      mnemonic: normalized,
    );

    final wallets = <WalletVaultEntry>[...existingBundle.wallets]
      ..removeWhere((w) => w.walletId == id)
      ..add(entry);
    final activeWalletId = makeActive
        ? id
        : (existingBundle.activeWalletId.isNotEmpty
              ? existingBundle.activeWalletId
              : (wallets.isNotEmpty ? wallets.first.walletId : id));

    final updated = WalletVaultBundle(
      version: existingBundle.version,
      createdAtIso: existingBundle.createdAtIso,
      kdf: existingBundle.kdf,
      activeWalletId: activeWalletId,
      wallets: List.unmodifiable(wallets),
    );
    await _secureVault.saveBundle(userId, updated);
    _secureBundle = updated;

    final profile = WalletProfile(
      walletId: id,
      name: displayName,
      userId: userId,
      addressHex: address.hexEip55,
    );
    _wallets = List.unmodifiable(
      updated.wallets
          .map(
            (e) => WalletProfile(
              walletId: e.walletId,
              name: e.name,
              userId: e.userId,
              addressHex: e.addressHex,
            ),
          )
          .toList(growable: false),
    );

    if (makeActive) {
      _setPrivateKeyInMemory(privateKeyHex);
      _updateDerivedAddressesFromMnemonic(normalized);
      _setActiveProfile(profile);
      await refreshBalances(silent: true);
      await _loadHistoryFromStorage(silent: true);
    }
    notifyListeners();
    return profile;
  }

  Future<void> switchActiveWallet({
    required String userId,
    required String walletId,
  }) async {
    final key = _secureKey;
    final bundle = _secureBundle;
    if (key == null || bundle == null || _activeUserId != userId) return;
    if (bundle.wallets.isEmpty) return;
    final entry = bundle.wallets.firstWhere(
      (w) => w.walletId == walletId,
      orElse: () => bundle.wallets.first,
    );

    final mnemonic = await _secureVault.decryptMnemonic(key: key, entry: entry);
    if (!bip39.validateMnemonic(mnemonic.trim())) {
      throw StateError('Повреждённое хранилище: seed невалиден');
    }
    final pk = await getPrivateKey(mnemonic);
    _setPrivateKeyInMemory(pk);
    _updateDerivedAddressesFromMnemonic(mnemonic);

    final updated = WalletVaultBundle(
      version: bundle.version,
      createdAtIso: bundle.createdAtIso,
      kdf: bundle.kdf,
      activeWalletId: walletId,
      wallets: bundle.wallets,
    );
    await _secureVault.saveBundle(userId, updated);
    _secureBundle = updated;

    if (_wallets.isEmpty) return;
    final profile = _wallets.firstWhere(
      (p) => p.walletId == walletId,
      orElse: () => _wallets.first,
    );
    _setActiveProfile(profile);
    await refreshBalances(silent: true);
    await _loadHistoryFromStorage(silent: true);
    notifyListeners();
  }

  void clearDevProfile() {
    if (_activeProfile == null && privateKey == null && _secureKey == null) {
      return;
    }
    _wallets = const <WalletProfile>[];
    _activeUserId = null;
    _activeProfile = null;
    _setPrivateKeyInMemory(null);
    _setBitcoinAddressInMemory(null);
    _setBitcoinPrivateKeyWifInMemory(null);
    _secureKey = null;
    _secureBundle = null;
    _balances = WalletBalances.initial(kTrackedTokens);
    _stopAutoRefresh();
    _clearHistoryState();
    _hasBalanceSnapshot = false;
    notifyListeners();
  }

  /// Устанавливает профиль «только для чтения», который содержит только адрес.
  ///
  /// Зачем:
  /// - полезно для десктоп-клиента, который знает только публичный адрес
  ///   (например, получен извне) и не имеет приватных ключей;
  /// - позволяет обновлять балансы без возможности отправки.
  Future<void> setReadOnlyAddress(String addressHex) async {
    final profile = WalletProfile(
      walletId: '_remote',
      name: 'Только просмотр',
      userId: '_remote',
      addressHex: addressHex,
    );
    _setActiveProfile(profile);
    // В режиме «только для чтения» приватный ключ не устанавливаем.
    _setBitcoinAddressInMemory(null);
    _setBitcoinPrivateKeyWifInMemory(null);
    await refreshBalances(silent: false);
    notifyListeners();
  }

  /// Инициализация провайдера: попытка восстановить последний DEV-профиль.
  ///
  /// В secure-режиме это не используется: там разблокировка происходит после логина,
  /// когда пользователь вводит пароль.
  Future<void> init() async {
    // Secure-only: намеренно пусто.
    // Разблокировка кошелька выполняется после логина, когда пользователь вводит пароль.
  }

  Future<void> refreshBalances({bool silent = false}) async {
    final addressHex = _activeProfile?.addressHex;
    final btcAddress = _bitcoinAddress;
    if (addressHex == null && (btcAddress == null || btcAddress.isEmpty)) {
      _balances = WalletBalances.initial(kTrackedTokens);
      _hasBalanceSnapshot = false;
      notifyListeners();
      return;
    }

    if (!silent) {
      _balances = _balances.copyWith(isLoading: true, clearError: true);
      notifyListeners();
    }

    final previousAssets = _balances.assets;

    try {
      final owner = addressHex == null
          ? null
          : EthereumAddress.fromHex(addressHex);
      final futures = kTrackedTokens
          .map((token) => _fetchAssetBalance(token, owner, btcAddress))
          .toList(growable: false);
      final balances = await Future.wait(futures);

      final ids = <String>{
        for (final t in kTrackedTokens)
          if (t.coinGeckoId != null && t.coinGeckoId!.isNotEmpty)
            t.coinGeckoId!,
      };
      final priceMap = await prices.fetchUsdPrices(coinGeckoIds: ids);
      final usdtUsd = prices.usdtUsdOrOne(priceMap['tether']);
      final usdtNormalizer = usdtUsd <= 0 ? 1.0 : usdtUsd;

      final assetBalances = balances
          .map((asset) {
            final id = asset.token.coinGeckoId;
            if (id == null || id.isEmpty) return asset;
            if (id == 'tether') {
              return AssetBalance(
                token: asset.token,
                raw: asset.raw,
                decimals: asset.decimals,
                // считаем 1 USDT == $1.00 (как базовую единицу UI).
                priceUsd: 1.0,
              );
            }
            final p = priceMap[id];
            return AssetBalance(
              token: asset.token,
              raw: asset.raw,
              decimals: asset.decimals,
              priceUsd: p == null ? null : (p / usdtNormalizer),
            );
          })
          .toList(growable: false);

      await _detectIncomingTransfers(previousAssets, assetBalances);
      _balances = _balances.copyWith(
        assets: assetBalances,
        isLoading: false,
        clearError: true,
        updatedAt: DateTime.now(),
      );
      _hasBalanceSnapshot = true;
    } catch (e, st) {
      debugPrint('Failed to refresh balances: $e\n$st');
      _balances = _balances.copyWith(
        isLoading: false,
        error: e.toString(),
        updatedAt: DateTime.now(),
      );
    }
    notifyListeners();
  }

  Future<SendPreflightResult> preflightSend({
    required TokenMetadata token,
    required String recipient,
    required double amount,
  }) async {
    if (amount <= 0) {
      throw ArgumentError.value(amount, 'amount', 'should be > 0');
    }

    if (token.isBitcoin) {
      final from = _bitcoinAddress;
      if (from == null || from.isEmpty) {
        throw StateError('BTC адрес не инициализирован');
      }
      final amountSats = _toBaseUnits(amount, 8);
      if (amountSats <= BigInt.zero) {
        throw ArgumentError.value(amount, 'amount', 'слишком мало');
      }

      final feeRate = await bitcoin.fetchFeeRateSatsPerVbyte();
      final utxos = await bitcoin.fetchConfirmedUtxos(from);
      if (utxos.isEmpty) {
        return SendPreflightResult(
          token: token,
          recipient: recipient,
          amount: amount,
          networkLabel: 'Bitcoin',
          feeStatus: FeeStatus.ok,
          feeLabel: '—',
          speedLabel: 'Рынок ~10 мин.',
          canSend: false,
          amountUsdLabel: _amountUsdLabel(token: token, amount: amount),
        );
      }

      BigInt selectedTotal = BigInt.zero;
      BigInt? feeSats;

      for (var i = 0; i < utxos.length; i++) {
        selectedTotal += utxos[i].valueSats;
        final inputs = i + 1;

        final feeWithChange = _estimateP2pkhFeeSats(
          inputs: inputs,
          outputs: 2,
          feeRateSatsPerVbyte: feeRate,
        );
        final requiredWithChange = amountSats + feeWithChange;
        if (selectedTotal >= requiredWithChange) {
          final change = selectedTotal - requiredWithChange;
          if (change >= BigInt.from(546)) {
            feeSats = feeWithChange;
            break;
          }
        }

        final feeNoChangeMin = _estimateP2pkhFeeSats(
          inputs: inputs,
          outputs: 1,
          feeRateSatsPerVbyte: feeRate,
        );
        final requiredNoChange = amountSats + feeNoChangeMin;
        if (selectedTotal >= requiredNoChange) {
          final feeNoChange = selectedTotal - amountSats;
          if (feeNoChange >= feeNoChangeMin) {
            feeSats = feeNoChange;
            break;
          }
        }
      }

      final canSend = feeSats != null;
      return SendPreflightResult(
        token: token,
        recipient: recipient,
        amount: amount,
        networkLabel: 'Bitcoin',
        feeStatus: FeeStatus.ok,
        feeLabel: feeSats == null ? '—' : '${feeSats.toString()} sats',
        speedLabel: 'Рынок ~10 мин.',
        canSend: canSend,
        amountUsdLabel: _amountUsdLabel(token: token, amount: amount),
      );
    }

    final fromHex = _activeProfile?.addressHex;
    if (fromHex == null || fromHex.isEmpty) {
      throw StateError('Активный кошелёк не выбран');
    }
    final from = EthereumAddress.fromHex(fromHex);
    final to = EthereumAddress.fromHex(recipient);

    final ethBalanceWei = (await blockchain.getNativeBalance(from)).getInWei;

    BigInt gasPriceWei;
    try {
      gasPriceWei = (await blockchain.getGasPrice()).getInWei;
    } catch (_) {
      gasPriceWei = BigInt.from(30) * BigInt.from(1000000000); // 30 gwei
    }

    BigInt gasLimit;
    BigInt feeWei;
    bool hasEnoughFee;
    bool hasEnoughToken = true;

    if (token.isNative) {
      final valueWei = _toBaseUnits(amount, token.decimalsHint);
      try {
        gasLimit = await blockchain.estimateGasForNativeTransfer(
          from: from,
          to: to,
          valueWei: valueWei,
        );
      } catch (_) {
        gasLimit = BigInt.from(21000);
      }
      feeWei = (gasLimit * gasPriceWei * BigInt.from(12)) ~/ BigInt.from(10);
      hasEnoughFee = ethBalanceWei >= (valueWei + feeWei);
    } else {
      final contract = EthereumAddress.fromHex(token.contractAddress!);
      final decimals = token.fetchDecimalsFromChain
          ? await blockchain.getTokenDecimals(contract)
          : token.decimalsHint;
      final amountRaw = _toBaseUnits(amount, decimals);

      final tokenBal = await blockchain.getTokenBalance(contract, from);
      hasEnoughToken = tokenBal >= amountRaw;

      try {
        gasLimit = await blockchain.estimateGasForErc20Transfer(
          from: from,
          contract: contract,
          to: to,
          amount: amountRaw,
        );
      } catch (_) {
        gasLimit = BigInt.from(65000);
      }
      feeWei = (gasLimit * gasPriceWei * BigInt.from(12)) ~/ BigInt.from(10);
      hasEnoughFee = ethBalanceWei >= feeWei;
    }

    final feeEthLabel = _formatEth(feeWei);
    final feeUsdLabel = _feeUsdLabel(feeWei: feeWei);
    final feeLabel = feeUsdLabel == null
        ? '$feeEthLabel ETH'
        : '$feeUsdLabel  $feeEthLabel ETH';

    final feeStatus = hasEnoughFee ? FeeStatus.ok : FeeStatus.insufficientFee;
    final canSend = hasEnoughToken && hasEnoughFee;

    return SendPreflightResult(
      token: token,
      recipient: recipient,
      amount: amount,
      networkLabel: kEvmChainId == 1 ? 'Ethereum' : 'EVM',
      feeStatus: feeStatus,
      feeLabel: feeLabel,
      speedLabel: 'Рынок ~12 сек.',
      canSend: canSend,
      feeWarningText: hasEnoughFee
          ? null
          : 'У вас на счету недостаточно ETH для оплаты комиссии сети.',
      amountUsdLabel: _amountUsdLabel(token: token, amount: amount),
    );
  }

  Future<String> sendAsset({
    required TokenMetadata token,
    required String recipient,
    required double amount,
  }) async {
    if (amount <= 0) {
      throw ArgumentError.value(
        amount,
        'amount',
        'should be greater than zero',
      );
    }
    if (token.isBitcoin) {
      final wif = _bitcoinPrivateKeyWif;
      final fromBtc = _bitcoinAddress;
      if (wif == null || wif.isEmpty || fromBtc == null || fromBtc.isEmpty) {
        throw StateError('BTC ключ не инициализирован');
      }

      final sats = _toBaseUnits(amount, token.decimalsHint);
      final feeRate = kColdWalletMode
          ? 5
          : await bitcoin.fetchFeeRateSatsPerVbyte();
      final raw = await bitcoin.buildSignedP2pkhTransactionHex(
        fromWif: wif,
        fromAddress: fromBtc,
        toAddress: recipient.trim(),
        amountSats: sats,
        feeRateSatsPerVbyte: feeRate,
      );
      final result = kColdWalletMode
          ? raw
          : await bitcoin.broadcastRawTransactionHex(raw);

      if (!kColdWalletMode) {
        await refreshBalances(silent: true);
      }
      final record = TransactionRecord(
        id: _nextRecordId(),
        tokenSymbol: token.symbol,
        amount: amount,
        incoming: false,
        timestamp: DateTime.now(),
        txHash: result,
        note: '→ ${_shortenAddress(recipient)}',
      );
      await _appendHistory([record]);
      return result;
    }

    final key = privateKey;
    if (key == null) {
      throw StateError('Private key is not initialized');
    }

    final fromHex = _activeProfile?.addressHex;
    if (fromHex == null || fromHex.isEmpty) {
      throw StateError('Active wallet is not selected');
    }
    final from = EthereumAddress.fromHex(fromHex);
    final to = EthereumAddress.fromHex(recipient);

    String txHash;
    try {
      if (token.isNative) {
        final wei = _toBaseUnits(amount, token.decimalsHint);
        await _preflightEvmSendNative(from: from, to: to, valueWei: wei);
        txHash = await blockchain.sendNative(
          privateKeyHex: key,
          to: to,
          amount: EtherAmount.fromBigInt(EtherUnit.wei, wei),
        );
      } else {
        final contract = EthereumAddress.fromHex(token.contractAddress!);
        final decimals = token.fetchDecimalsFromChain
            ? await blockchain.getTokenDecimals(contract)
            : token.decimalsHint;
        final raw = _toBaseUnits(amount, decimals);
        await _preflightEvmSendErc20(
          from: from,
          contract: contract,
          to: to,
          tokenSymbol: token.symbol,
          amountRaw: raw,
        );
        txHash = await blockchain.sendToken(
          privateKeyHex: key,
          contract: contract,
          to: to,
          amount: raw,
        );
      }
    } catch (e) {
      final text = e.toString();
      if (text.contains('insufficient funds for gas * price + value')) {
        throw Exception(
          'Недостаточно средств для отправки: не хватает ETH на сумму и/или комиссию сети (gas).\n'
          'Пополните ETH на адрес $fromHex и попробуйте снова.',
        );
      }
      rethrow;
    }
    if (!kColdWalletMode) {
      await refreshBalances(silent: true);
    }
    final record = TransactionRecord(
      id: _nextRecordId(),
      tokenSymbol: token.symbol,
      amount: amount,
      incoming: false,
      timestamp: DateTime.now(),
      txHash: txHash,
      note: '→ ${_shortenAddress(recipient)}',
    );
    await _appendHistory([record]);
    return txHash;
  }

  Future<void> _preflightEvmSendNative({
    required EthereumAddress from,
    required EthereumAddress to,
    required BigInt valueWei,
  }) async {
    if (kColdWalletMode) return;

    final balanceWei = (await blockchain.getNativeBalance(from)).getInWei;
    if (balanceWei <= BigInt.zero) {
      throw Exception('Недостаточно ETH для отправки и комиссии сети (gas).');
    }

    final feeWei = await _estimateFeeWeiForNative(
      from: from,
      to: to,
      valueWei: valueWei,
    );

    // Если комиссию не удалось оценить (некоторые RPC могут падать на estimateGas),
    // хотя бы проверим, что хватает на сам перевод.
    if (feeWei <= BigInt.zero) {
      if (balanceWei < valueWei) {
        throw Exception(
          'Недостаточно ETH для перевода: нужно ${_formatEth(valueWei)} ETH, доступно ${_formatEth(balanceWei)} ETH.',
        );
      }
      return;
    }
    final requiredWei = valueWei + feeWei;
    if (balanceWei < requiredWei) {
      throw Exception(
        'Недостаточно ETH: нужно ${_formatEth(requiredWei)} ETH (с учётом комиссии), доступно ${_formatEth(balanceWei)} ETH.',
      );
    }
  }

  Future<void> _preflightEvmSendErc20({
    required EthereumAddress from,
    required EthereumAddress contract,
    required EthereumAddress to,
    required String tokenSymbol,
    required BigInt amountRaw,
  }) async {
    if (kColdWalletMode) return;

    final tokenBal = await blockchain.getTokenBalance(contract, from);
    if (tokenBal < amountRaw) {
      throw Exception('Недостаточно $tokenSymbol для отправки.');
    }

    final balanceWei = (await blockchain.getNativeBalance(from)).getInWei;
    if (balanceWei <= BigInt.zero) {
      throw Exception(
        'Недостаточно ETH для комиссии сети (gas). Пополните немного ETH и повторите отправку.',
      );
    }

    final feeWei = await _estimateFeeWeiForErc20(
      from: from,
      contract: contract,
      to: to,
      amountRaw: amountRaw,
    );
    if (balanceWei < feeWei) {
      throw Exception(
        'Недостаточно ETH для комиссии сети (gas). Нужно примерно ${_formatEth(feeWei)} ETH, доступно ${_formatEth(balanceWei)} ETH.',
      );
    }
  }

  Future<BigInt> _estimateFeeWeiForNative({
    required EthereumAddress from,
    required EthereumAddress to,
    required BigInt valueWei,
  }) async {
    try {
      final gas = await blockchain.estimateGasForNativeTransfer(
        from: from,
        to: to,
        valueWei: valueWei,
      );
      final gasPrice = (await blockchain.getGasPrice()).getInWei;
      // +20% буфер, чтобы не упираться в погрешности оценки.
      return (gas * gasPrice * BigInt.from(12)) ~/ BigInt.from(10);
    } catch (_) {
      return BigInt.zero;
    }
  }

  Future<BigInt> _estimateFeeWeiForErc20({
    required EthereumAddress from,
    required EthereumAddress contract,
    required EthereumAddress to,
    required BigInt amountRaw,
  }) async {
    try {
      final gas = await blockchain.estimateGasForErc20Transfer(
        from: from,
        contract: contract,
        to: to,
        amount: amountRaw,
      );
      final gasPrice = (await blockchain.getGasPrice()).getInWei;
      return (gas * gasPrice * BigInt.from(12)) ~/ BigInt.from(10);
    } catch (_) {
      return BigInt.zero;
    }
  }

  String _formatEth(BigInt wei) {
    final eth = EtherAmount.fromBigInt(
      EtherUnit.wei,
      wei,
    ).getValueInUnit(EtherUnit.ether);
    final text = eth.toStringAsFixed(6);
    return text.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  String _formatFiat(double value) {
    final text = value.toStringAsFixed(2);
    return text.replaceAll('.', ',');
  }

  String? _feeUsdLabel({required BigInt feeWei}) {
    final ethPrice = _priceUsdFor('ETH');
    if (ethPrice == null || !ethPrice.isFinite || ethPrice <= 0) return null;
    final feeEth = EtherAmount.fromBigInt(
      EtherUnit.wei,
      feeWei,
    ).getValueInUnit(EtherUnit.ether);
    final usd = feeEth * ethPrice;
    return '${_formatFiat(usd)} \$';
  }

  String? _amountUsdLabel({
    required TokenMetadata token,
    required double amount,
  }) {
    final price = _priceUsdFor(token.symbol);
    if (price == null || !price.isFinite || price <= 0) return null;
    return '${_formatFiat(amount * price)} \$';
  }

  BigInt _estimateP2pkhFeeSats({
    required int inputs,
    required int outputs,
    required int feeRateSatsPerVbyte,
  }) {
    final vbytes = 10 + (148 * inputs) + (34 * outputs);
    final fee = BigInt.from(vbytes) * BigInt.from(feeRateSatsPerVbyte);
    return fee <= BigInt.zero ? BigInt.from(1) : fee;
  }

  double convertAmount({
    required TokenMetadata from,
    required TokenMetadata to,
    required double amount,
  }) {
    if (amount <= 0) return 0;
    final fromPrice = _priceUsdFor(from.symbol);
    final toPrice = _priceUsdFor(to.symbol);
    if (fromPrice == null || toPrice == null) return 0;
    if (fromPrice <= 0 || toPrice <= 0) return 0;
    return amount * fromPrice / toPrice;
  }

  double? _priceUsdFor(String symbol) {
    for (final asset in _balances.assets) {
      if (asset.token.symbol != symbol) continue;
      return asset.priceUsd;
    }
    return null;
  }

  Future<void> refreshHistory() async {
    await _loadHistoryFromStorage();
  }

  AssetBalance? balanceForSymbol(String symbol) {
    for (final asset in _balances.assets) {
      if (asset.token.symbol == symbol) return asset;
    }
    return null;
  }

  void _clearHistoryState() {
    _history = const <TransactionRecord>[];
    _historyLoading = false;
    _historyError = null;
  }

  Future<void> _loadHistoryFromStorage({bool silent = false}) async {
    final profile = _activeProfile;
    if (profile == null) return;
    if (!silent) {
      _historyLoading = true;
      notifyListeners();
    }
    try {
      var records = await historyStorage.loadHistory(profile.storageId);
      // Обратная совместимость: в старых сборках история могла храниться по userId.
      if (records.isEmpty && profile.userId.isNotEmpty) {
        final legacy = await historyStorage.loadHistory(profile.userId);
        if (legacy.isNotEmpty) {
          records = legacy;
          await historyStorage.saveHistory(profile.storageId, legacy);
        }
      }
      _history = List.unmodifiable(records);
      _historyError = null;
    } catch (e, st) {
      debugPrint('Failed to load history: $e\n$st');
      _historyError = e.toString();
    } finally {
      _historyLoading = false;
      notifyListeners();
    }
  }

  Future<void> _appendHistory(List<TransactionRecord> entries) async {
    if (entries.isEmpty) return;
    final updated = <TransactionRecord>[...entries, ..._history]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    if (updated.length > _historyLimit) {
      updated.removeRange(_historyLimit, updated.length);
    }
    _history = List.unmodifiable(updated);
    notifyListeners();
    await _persistHistory();
  }

  Future<void> _persistHistory() async {
    final profile = _activeProfile;
    if (profile == null) return;
    try {
      await historyStorage.saveHistory(profile.storageId, _history);
      if (_historyError != null) {
        _historyError = null;
        notifyListeners();
      }
    } catch (e, st) {
      debugPrint('Failed to persist history: $e\n$st');
      _historyError = e.toString();
      notifyListeners();
    }
  }

  Future<void> _detectIncomingTransfers(
    List<AssetBalance> previous,
    List<AssetBalance> current,
  ) async {
    if (!_hasBalanceSnapshot) return;
    if (previous.isEmpty) return;
    final prevMap = <String, AssetBalance>{
      for (final asset in previous) asset.token.symbol: asset,
    };
    final additions = <TransactionRecord>[];
    for (final asset in current) {
      final prev = prevMap[asset.token.symbol];
      if (prev == null) continue;
      final delta = asset.raw - prev.raw;
      if (delta <= BigInt.zero) continue;
      final amount = _fromBaseUnits(delta, asset.decimals);
      if (amount <= 0) continue;
      additions.add(
        TransactionRecord(
          id: _nextRecordId(),
          tokenSymbol: asset.token.symbol,
          amount: amount,
          incoming: true,
          timestamp: DateTime.now(),
          note: 'Баланс пополнен',
        ),
      );
    }
    if (additions.isEmpty) return;
    await _appendHistory(additions);
  }

  double _fromBaseUnits(BigInt amount, int decimals) {
    if (amount == BigInt.zero) return 0;
    final divisor = math.pow(10, decimals).toDouble();
    return amount.toDouble() / divisor;
  }

  String _nextRecordId() {
    _historyCounter++;
    final micros = DateTime.now().microsecondsSinceEpoch;
    return 'tx_${micros}_$_historyCounter';
  }

  String _shortenAddress(String address) {
    if (address.length <= 12) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }

  void _setActiveProfile(WalletProfile? profile) {
    if (_activeProfile == null && profile == null) return;
    if (identical(_activeProfile, profile)) return;
    _activeProfile = profile;
    if (_activeProfile == null) {
      _stopAutoRefresh();
      _clearHistoryState();
      notifyListeners();
      return;
    }
    _restartAutoRefresh();
    _historyLoading = true;
    notifyListeners();
    unawaited(_loadHistoryFromStorage(silent: true));
  }

  Future<AssetBalance> _fetchAssetBalance(
    TokenMetadata token,
    EthereumAddress? owner,
    String? btcAddress,
  ) async {
    if (token.isBitcoin) {
      final address = btcAddress;
      if (address == null || address.trim().isEmpty) {
        return AssetBalance(token: token, raw: BigInt.zero, decimals: 8);
      }
      final sats = await bitcoin.fetchBalanceSats(address.trim());
      return AssetBalance(token: token, raw: sats, decimals: 8);
    }

    if (owner == null) {
      return AssetBalance(
        token: token,
        raw: BigInt.zero,
        decimals: token.decimalsHint,
      );
    }

    if (token.isNative) {
      final balance = await blockchain.getNativeBalance(owner);
      return AssetBalance(
        token: token,
        raw: balance.getInWei,
        decimals: token.decimalsHint,
      );
    }

    final contract = EthereumAddress.fromHex(token.contractAddress!);
    final raw = await blockchain.getTokenBalance(contract, owner);
    final decimals = token.fetchDecimalsFromChain
        ? await blockchain.getTokenDecimals(contract)
        : token.decimalsHint;
    return AssetBalance(token: token, raw: raw, decimals: decimals);
  }

  BigInt _toBaseUnits(double amount, int decimals) {
    final fixed = amount.toStringAsFixed(decimals);
    final parts = fixed.split('.');
    final whole = BigInt.parse(parts.first);
    final fraction = parts.length > 1 ? parts[1] : '';
    final padded = fraction.padRight(decimals, '0');
    final fractionValue = padded.isEmpty ? BigInt.zero : BigInt.parse(padded);
    final base = BigInt.from(10).pow(decimals);
    return whole * base + fractionValue;
  }

  void _restartAutoRefresh() {
    _balanceTimer?.cancel();
    _balanceTimer = Timer.periodic(
      _autoRefreshInterval,
      (_) => refreshBalances(silent: true),
    );
  }

  void _stopAutoRefresh() {
    _balanceTimer?.cancel();
    _balanceTimer = null;
  }

  @override
  void dispose() {
    _stopAutoRefresh();
    unawaited(blockchain.dispose());
    bitcoin.dispose();
    prices.dispose();
    super.dispose();
  }
}
