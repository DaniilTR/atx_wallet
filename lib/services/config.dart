/// Глобальная конфигурация клиента.
/// При необходимости переопределяйте через --dart-define.
import 'package:shared_preferences/shared_preferences.dart';

const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:3000',
);

/// Если нет бэкенда — можно включить оффлайн-режим.
const bool kUseRemoteAuth = bool.fromEnvironment(
  'USE_REMOTE_AUTH',
  defaultValue: true,
);

/// DEV storage для локального кошелька (по умолчанию включён, отключайте в релизе через --dart-define).
const bool kEnableDevWalletStorage = bool.fromEnvironment(
  'DEV_WALLET_STORAGE',
  defaultValue: true,
);

/// RPC endpoint для BNB Smart Chain Testnet.
const String kBscRpcUrl = String.fromEnvironment(
  'BSC_RPC_URL',
  defaultValue: 'https://bsc-testnet.publicnode.com',
);

/// ChainId сети (97 для BSC Testnet).
const int kBscChainId = int.fromEnvironment('BSC_CHAIN_ID', defaultValue: 97);

/// Публичный REST endpoint для получения цены BNB в USDT.
const String kBnbUsdPriceUrl = String.fromEnvironment(
  'BNB_PRICE_URL',
  defaultValue: 'https://api.binance.com/api/v3/ticker/price?symbol=BNBUSDT',
);

/// Начальный маршрут — если хотите пропускать логин при отладке, смените на '/start'.
const String kInitialRoute = String.fromEnvironment(
  'INITIAL_ROUTE',
  defaultValue: '/start',
);

/// WebSocket-ретранслятор для сессий Desktop↔Mobile (можно переопределить через dart-define).
const String kRelayWsUrl = String.fromEnvironment(
  'RELAY_WS_URL',
  defaultValue: 'wss://example.com/ws',
);

// Runtime-configurable API base which can be overridden in app settings
// and persisted in SharedPreferences for developer convenience.

class ApiConfig {
  static const String _prefKey = 'api_base_url_override';

  /// Current active base URL. Defaults to `kApiBaseUrl` but can be changed
  /// at runtime via `init()` and `setBase()`.
  static String base = kApiBaseUrl;

  /// Initialize from persistent storage. Call from `main()` early.
  static Future<void> init() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final v = sp.getString(_prefKey);
      if (v != null && v.isNotEmpty) base = v;
    } catch (_) {
      // ignore preferences errors — fall back to default
      base = kApiBaseUrl;
    }
  }

  /// Persist new base URL; pass empty string to clear override.
  static Future<void> setBase(String value) async {
    final sp = await SharedPreferences.getInstance();
    if (value.trim().isEmpty) {
      await sp.remove(_prefKey);
      base = kApiBaseUrl;
    } else {
      await sp.setString(_prefKey, value.trim());
      base = value.trim();
    }
  }

  static String _normalize(String b) =>
      b.endsWith('/') ? b.substring(0, b.length - 1) : b;

  /// Build a full Uri for an API path, ensuring slashes are correct.
  static Uri apiUri(String path) {
    final b = _normalize(base);
    final p = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$b$p');
  }
}
