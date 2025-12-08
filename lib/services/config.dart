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

/// Начальный маршрут — если хотите пропускать логин при отладке, смените на '/home'.
const String kInitialRoute = String.fromEnvironment(
  'INITIAL_ROUTE',
  defaultValue: '/login',
);
