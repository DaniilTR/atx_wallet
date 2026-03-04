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
