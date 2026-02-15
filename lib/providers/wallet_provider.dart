import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:bip32/bip32.dart' as bip32;
import 'package:bip39/bip39.dart' as bip39;
import 'package:flutter/foundation.dart';
import 'package:hex/hex.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web3dart/web3dart.dart';

import '../dev/dev_transaction_storage.dart';
import '../dev/dev_wallet_storage.dart';
import '../models/transaction_record.dart';
import '../services/blockchain_service.dart';

// Интерфейс для сервиса генерации и получения ключей/адреса.
abstract class WalletAddressService {
  String generateMnemonic();
  Future<String> getPrivateKey(String mnemonic);
  Future<EthereumAddress> getPublicKey(String privateKey);
}

class TokenMetadata {
  const TokenMetadata({
    required this.symbol,
    required this.name,
    required this.tbnbRate,
    this.contractAddress,
    this.decimalsHint = 18,
    this.isNative = false,
    this.fetchDecimalsFromChain = false,
  }) : assert(
         isNative || contractAddress != null,
         'ERC-20 token requires a contract address',
       );

  final String symbol;
  final String name;
  final double tbnbRate; // отношение токена к TBNB
  final String? contractAddress;
  final int decimalsHint;
  final bool isNative;
  final bool fetchDecimalsFromChain;

  bool get isErc20 => !isNative;
}

class AssetBalance {
  const AssetBalance({
    required this.token,
    required this.raw,
    required this.decimals,
  });

  final TokenMetadata token;
  final BigInt raw;
  final int decimals;

  double get amount {
    if (raw == BigInt.zero) return 0;
    final divisor = math.pow(10, decimals).toDouble();
    return raw.toDouble() / divisor;
  }

  double get tbnbValue => amount * token.tbnbRate;
}

class WalletBalances {
  WalletBalances({
    required List<AssetBalance> assets,
    this.bnbUsdPrice,
    this.updatedAt,
    this.isLoading = false,
    this.error,
  }) : assets = List.unmodifiable(assets);

  final List<AssetBalance> assets;
  final double? bnbUsdPrice;
  final DateTime? updatedAt;
  final bool isLoading;
  final String? error;

  double get totalTbnb =>
      assets.fold<double>(0, (prev, asset) => prev + asset.tbnbValue);

  double? get totalUsd => bnbUsdPrice == null ? null : totalTbnb * bnbUsdPrice!;

  WalletBalances copyWith({
    List<AssetBalance>? assets,
    double? bnbUsdPrice,
    bool? isLoading,
    bool clearError = false,
    String? error,
    DateTime? updatedAt,
  }) {
    return WalletBalances(
      assets: assets ?? this.assets,
      bnbUsdPrice: bnbUsdPrice ?? this.bnbUsdPrice,
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
    symbol: 'TBNB',
    name: 'Test BNB',
    tbnbRate: 1,
    decimalsHint: 18,
    isNative: true,
  ),
  TokenMetadata(
    symbol: 'ATX',
    name: 'ATX coin',
    contractAddress: '0x996Dbc052A2A4d128ddB2375A77608ff5cBc5Ff0',
    tbnbRate: 0.001,
    decimalsHint: 18,
    fetchDecimalsFromChain: true,
  ),
  TokenMetadata(
    symbol: 'LEV',
    name: 'Levcoin',
    contractAddress: '0x145753b98ECafDC1Fb60F57518598e9390B32af9',
    tbnbRate: 0.01,
    decimalsHint: 18,
    fetchDecimalsFromChain: true,
  ),
];

class WalletProvider extends ChangeNotifier implements WalletAddressService {
  WalletProvider({
    bool devEnabled = false,
    BlockchainService? blockchainService,
    DevWalletStorage? walletStorage,
    DevTransactionStorage? transactionStorage,
  }) : devStorage = walletStorage ?? DevWalletStorage(devEnabled: devEnabled),
       devHistoryStorage =
           transactionStorage ?? DevTransactionStorage(devEnabled: devEnabled),
       blockchain = blockchainService ?? BlockchainService();

  // Храним приватный ключ в памяти (краткосрочно) для уведомлений UI.
  String? privateKey;

  // Стандартный путь BIP44 для EVM/BSC: m/44'/60'/0'/0/0.
  static const String _derivationPath = "m/44'/60'/0'/0/0";
  static const Duration _autoRefreshInterval = Duration(seconds: 45);

  final DevWalletStorage devStorage;
  final DevTransactionStorage devHistoryStorage;
  final BlockchainService blockchain;

  DevWalletProfile? _activeProfile;
  DevWalletProfile? get activeProfile => _activeProfile;
  bool get devEnabled => devStorage.devEnabled;

  String? _activeUserId;
  List<DevWalletProfile> _wallets = const <DevWalletProfile>[];
  UnmodifiableListView<DevWalletProfile> get wallets =>
      UnmodifiableListView(_wallets);

  WalletBalances _balances = WalletBalances.initial(kTrackedTokens);
  WalletBalances get balances => _balances;
  List<TokenMetadata> get supportedTokens => kTrackedTokens;

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
    final address = private.address;
    return address;
  }

  /// DEV-режим: создать кошелёк и сохранить профиль для userId.
  /// Вызывается ТОЛЬКО в момент регистрации. На авторизации НЕ вызываем.
  Future<DevWalletProfile?> generateAndPersistForUser(String userId) async {
    if (!devStorage.devEnabled) return null;

    // Если у пользователя уже есть кошельки — просто загрузим и вернём активный.
    final bundle = await devStorage.loadBundle(userId);
    if (bundle != null && bundle.wallets.isNotEmpty) {
      await loadDevWallets(userId);
      return _activeProfile;
    }

    // Иначе создаём первый кошелёк.
    final created = await createNewWallet(userId: userId, name: 'Кошелёк 1');
    return created;
  }

  /// Получить профиль из DEV-хранилища по userId (для главного экрана).
  Future<DevWalletProfile?> loadDevProfile(String userId) async {
    // backward-compatible alias
    return loadDevWallets(userId);
  }

  Future<DevWalletProfile?> loadDevWallets(String userId) async {
    if (!devStorage.devEnabled) return null;
    _activeUserId = userId;

    final bundle = await devStorage.loadBundle(userId);
    final wallets = bundle?.wallets ?? const <DevWalletProfile>[];
    _wallets = List.unmodifiable(wallets);
    DevWalletProfile? active;
    if (bundle != null && wallets.isNotEmpty) {
      active = wallets.firstWhere(
        (w) => w.walletId == bundle.activeWalletId,
        orElse: () => wallets.first,
      );
    }
    _setActiveProfile(active);

    if (active != null) {
      privateKey = active.privateKeyHex.isEmpty ? null : active.privateKeyHex;
      await refreshBalances(silent: true);
      await _loadHistoryFromStorage(silent: true);
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('lastDevUserId', userId);
      } catch (_) {}
    }
    return active;
  }

  String _newWalletId() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final salt = math.Random().nextInt(1 << 30);
    return 'w${now.toRadixString(16)}${salt.toRadixString(16)}';
  }

  Future<DevWalletProfile> createNewWallet({
    required String userId,
    String? name,
    bool makeActive = true,
  }) async {
    if (!devStorage.devEnabled) {
      throw StateError('Dev wallet storage is disabled');
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

  Future<DevWalletProfile> importWalletFromMnemonic({
    required String userId,
    required String mnemonic,
    String? name,
    String? walletId,
    bool makeActive = true,
  }) async {
    if (!devStorage.devEnabled) {
      throw StateError('Dev wallet storage is disabled');
    }
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

    final profile = DevWalletProfile(
      walletId: id,
      name: (name == null || name.trim().isEmpty) ? 'Кошелёк' : name.trim(),
      userId: userId,
      mnemonic: normalized,
      privateKeyHex: privateKeyHex,
      addressHex: address.hexEip55,
    );

    await devStorage.addWallet(userId, profile, makeActive: makeActive);
    await loadDevWallets(userId);
    return profile;
  }

  Future<void> switchActiveWallet({
    required String userId,
    required String walletId,
  }) async {
    if (!devStorage.devEnabled) return;
    await devStorage.setActiveWallet(userId, walletId);
    await loadDevWallets(userId);
  }

  void clearDevProfile() {
    if (_activeProfile == null) return;
    _wallets = const <DevWalletProfile>[];
    _activeUserId = null;
    _activeProfile = null;
    privateKey = null;
    _balances = WalletBalances.initial(kTrackedTokens);
    _stopAutoRefresh();
    _clearHistoryState();
    _hasBalanceSnapshot = false;
    notifyListeners();
    // remove lastDevUserId
    unawaited(
      Future(() async {
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('lastDevUserId');
        } catch (_) {}
      }),
    );
  }

  /// Set a read-only profile that only contains an address. Useful for
  /// desktop clients that receive the address from a paired mobile device
  /// but do not possess private keys. This will enable balance refreshes.
  Future<void> setReadOnlyAddress(String addressHex) async {
    final profile = DevWalletProfile(
      walletId: '_remote',
      name: 'Remote',
      userId: '_remote',
      mnemonic: '',
      privateKeyHex: '',
      addressHex: addressHex,
    );
    _setActiveProfile(profile);
    // do not set privateKey
    await refreshBalances(silent: false);
    notifyListeners();
  }

  /// Initialize provider: load private key and try loading last dev profile.
  Future<void> init() async {
    await loadPrivateKey();
    if (!devEnabled) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final last = prefs.getString('lastDevUserId');
      if (last != null && last.isNotEmpty) {
        await loadDevWallets(last);
      }
    } catch (_) {}
  }

  Future<void> refreshBalances({bool silent = false}) async {
    final addressHex = _activeProfile?.addressHex;
    if (addressHex == null) {
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
      final owner = EthereumAddress.fromHex(addressHex);
      final futures = kTrackedTokens
          .map((token) => _fetchAssetBalance(token, owner))
          .toList(growable: false);
      final assetBalances = await Future.wait(futures);
      await _detectIncomingTransfers(previousAssets, assetBalances);
      final price = await blockchain.fetchBnbUsdPrice();
      _balances = _balances.copyWith(
        assets: assetBalances,
        bnbUsdPrice: price ?? _balances.bnbUsdPrice,
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
    final key = privateKey;
    if (key == null) {
      throw StateError('Private key is not initialized');
    }
    final to = EthereumAddress.fromHex(recipient);
    String txHash;
    if (token.isNative) {
      final wei = _toBaseUnits(amount, token.decimalsHint);
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
      txHash = await blockchain.sendToken(
        privateKeyHex: key,
        contract: contract,
        to: to,
        amount: raw,
      );
    }
    await refreshBalances(silent: true);
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

  double convertAmount({
    required TokenMetadata from,
    required TokenMetadata to,
    required double amount,
  }) {
    if (amount <= 0) return 0;
    final tbnbValue = amount * from.tbnbRate;
    return tbnbValue / to.tbnbRate;
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
      var records = await devHistoryStorage.loadHistory(profile.storageId);
      // Backward compatibility: older builds stored history under userId.
      if (records.isEmpty && profile.userId.isNotEmpty) {
        final legacy = await devHistoryStorage.loadHistory(profile.userId);
        if (legacy.isNotEmpty) {
          records = legacy;
          await devHistoryStorage.saveHistory(profile.storageId, legacy);
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
      await devHistoryStorage.saveHistory(profile.storageId, _history);
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

  void _setActiveProfile(DevWalletProfile? profile) {
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
    EthereumAddress owner,
  ) async {
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
    super.dispose();
  }
}
