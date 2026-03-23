// lib/services/config.dart
// Глобальная конфигурация клиента.
// При необходимости переопределяйте через --dart-define.

/// DEV storage для локального кошелька (по умолчанию включён, отключайте в релизе через --dart-define).
const bool kEnableDevWalletStorage = bool.fromEnvironment(
  'DEV_WALLET_STORAGE',
  defaultValue: false,
);

/// Cold wallet mode: transactions are signed locally but NOT broadcast.
/// The returned value from send methods becomes a raw signed transaction hex.
const bool kColdWalletMode = bool.fromEnvironment(
  'COLD_WALLET',
  defaultValue: false,
);

/// RPC endpoint для EVM-сети (по умолчанию Ethereum Mainnet).
///
/// Поддержаны env-переменные (по приоритету):
/// - EVM_RPC_URL
/// - ETH_RPC_URL
/// - BSC_RPC_URL (backward-compatible)
const String kEvmRpcUrl = String.fromEnvironment(
  'EVM_RPC_URL',
  defaultValue: String.fromEnvironment(
    'ETH_RPC_URL',
    defaultValue: String.fromEnvironment(
      'BSC_RPC_URL',
      defaultValue: 'https://ethereum.publicnode.com',
    ),
  ),
);

/// ChainId EVM-сети (по умолчанию 1 для Ethereum Mainnet).
///
/// Поддержаны env-переменные (по приоритету):
/// - EVM_CHAIN_ID
/// - ETH_CHAIN_ID
/// - BSC_CHAIN_ID (backward-compatible)
const int kEvmChainId = int.fromEnvironment(
  'EVM_CHAIN_ID',
  defaultValue: int.fromEnvironment(
    'ETH_CHAIN_ID',
    defaultValue: int.fromEnvironment('BSC_CHAIN_ID', defaultValue: 1),
  ),
);

/// Начальный маршрут — если хотите пропускать логин при отладке, смените на '/home'.
const String kInitialRoute = String.fromEnvironment(
  'INITIAL_ROUTE',
  defaultValue: '/start',
);

/// Базовый URL для CoinGecko.
///
/// По умолчанию приложение ходит напрямую в CoinGecko.
/// Чтобы использовать свой сервер-посредник с кэшем (VPS), задайте:
/// `--dart-define COINGECKO_BASE_URL=https://your-vps.example.com`
///
/// Важно: ожидается именно origin (схема + хост + порт), без path.
/// Пример: `https://prices.example.com` или ` http://127.0.0.1:8080`.
const String kCoinGeckoBaseUrl = String.fromEnvironment(
  'COINGECKO_BASE_URL',
  defaultValue: 'http://46.247.41.175:8080',
);
