/// Глобальная конфигурация клиента.
/// При необходимости переопределяйте через --dart-define.

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

/// Начальный маршрут — если хотите пропускать логин при отладке, смените на '/home'.
const String kInitialRoute = String.fromEnvironment(
  'INITIAL_ROUTE',
  defaultValue: '/login',
);
