# Архитектура ATX Wallet (актуально: Ethereum + BTC)

Документ описывает актуальное устройство приложения: где что лежит, какие сервисы за что отвечают и как проходят ключевые сценарии.

## Ключевые требования (текущая тема)

- Сети: **EVM (по умолчанию Ethereum Mainnet)** + **Bitcoin**.
- Основные активы в UI: **USDT / ETH / BTC**.
- Отображение стоимости: **в USD**, при этом по ТЗ «в долларах по курсу USDT» — итоговые значения нормализуются через USDT.
- Приложение клиентское: нет собственного backend’а для блокчейна/цен; используются публичные RPC/API.

---

## Общая картина

Проект — это одно Flutter-приложение (папка `lib/`), в котором:

- UI разбит по фичам (`lib/features/...`).
- Состояние кошелька находится в `WalletProvider` и раздаётся через `WalletScope`.
- Аутентификация доступна через `AuthScope` (singleton `AuthController`).
- Интеграции (EVM RPC, CoinGecko, Bitcoin-эксплорер) находятся в `lib/services/...`.
- DEV-хранилища (демо-кошелёк и история) — в `lib/dev/...`.
- Secure-режим хранения сид-фразы реализован через модуль `lib/WalletSecureStorage/...`.

Блокчейн-часть — это **прямые клиентские запросы**:

- EVM: RPC-узел (по умолчанию Ethereum Mainnet).
- Цены: публичный API CoinGecko.
- BTC баланс: публичный API blockstream.info.

---

## Точки входа и маршрутизация

### `lib/main.dart`

Главный вход приложения:

- Инициализация Flutter.
- Создание `WalletProvider` и вызов `walletProvider.init()`.
- Запуск `MaterialApp`.

Маршруты (`routes`) объявлены в `MaterialApp`, ключевые:

- `/start` → стартовый экран
- `/login` → логин
- `/register` → регистрация
- `/home` → главный экран кошелька
- `/market`, `/history`, `/rewards` → разделы внутри home
- `/settings` → настройки

Начальный маршрут можно переопределить через `--dart-define INITIAL_ROUTE=...` (по умолчанию `/start`).

### Глобальные scope’ы

В `builder` приложения все экраны оборачиваются в:

- `AuthScope` — доступ к `AuthController`
- `WalletScope` — доступ к `WalletProvider`

---

## UI / Features (`lib/features`)

### `lib/features/auth` — авторизация

Основные экраны:

- `start_page.dart` — выбор: создать кошелёк (регистрация) или войти.
- `login_page.dart` — логин:
  - умеет восстановить сессию через `AuthController.tryRestoreSession()`;
  - после входа открывает кошелёк (см. сценарии ниже) и делает переход на `/home`.
- `register_page.dart` — регистрация:
  - создаёт пользователя;
  - создаёт/инициализирует кошелёк (в зависимости от режима) и делает переход на `/home`.

### `lib/features/home` — главный экран

`home_page.dart` — “хаб” кошелька: баланс, адрес, действия (send/receive/buy/swap), переходы к market/history/rewards.

Стартовая логика:

- В `initState()` вызывается `WalletScope.read(context).refreshBalances(silent: true)`.

Рынок/графики:

- Экран деталей монеты и график находятся в `lib/features/home/activity/market/...`.
- Для графика используется endpoint CoinGecko `market_chart` (внутренний сервис в файле экрана), а не общий сервис простых цен.

---

## Управление состоянием (`lib/providers`)

### `WalletProvider`

`WalletProvider` — центральный state-контейнер (ChangeNotifier). Он отвечает за:

- работу с сид-фразой:
  - DEV-режим: создание/чтение из DEV-хранилища;
  - secure-режим: создание/расшифровка из защищённого хранилища;
- деривацию EVM-адреса и приватного ключа по BIP44 (coin type 60);
- деривацию BTC-адреса из той же сид-фразы (через `BitcoinService`);
- получение балансов:
  - ETH (native) через EVM RPC;
  - USDT (ERC-20) через EVM RPC;
  - BTC (только чтение) через blockstream API;
- получение цен через `AssetPriceService` и расчёт “USD-оценки по курсу USDT”;
- локальную историю операций.

Трекнутые активы (ключевая логика UI): USDT / ETH / BTC.

### `WalletScope`

`WalletScope` — `InheritedNotifier<WalletProvider>` для доступа к провайдеру без внешних state-менеджеров.

---

## Хранение данных: DEV-режим и secure-режим

В проекте есть 2 режима “где живут ключи/сид-фраза”. Переключение — через [lib/services/config.dart](lib/services/config.dart).

### DEV-режим (`DEV_WALLET_STORAGE=true`)

- Используется только для разработки/демо.
- Сид-фраза/ключи и история сохраняются локально через `lib/dev/...` (JSON-файлы в Application Support).
- После логина `login_page.dart` вызывает `wallet.loadDevProfile(user.id)`.

### Secure-режим (`DEV_WALLET_STORAGE=false`)

- Сид-фраза хранится в зашифрованном виде в `flutter_secure_storage`.
- При логине/разблокировке `WalletProvider.unlockSecureWallets(...)`:
  - расшифровывает сид-фразу;
  - деривирует ключ/адрес EVM и BTC-адрес;
  - держит приватный ключ EVM **только в памяти сессии**.

Модуль secure-хранилища находится в `lib/WalletSecureStorage/...` (vault bundle, KDF и шифрование).

---

## Сервисы (`lib/services`)

### `config.dart`

Глобальная конфигурация приложения:

- `DEV_WALLET_STORAGE` — включить DEV-хранилище.
- `COLD_WALLET` — режим “холодного” кошелька:
  - транзакции подписываются локально, но **не отправляются** в сеть;
  - методы `send...` возвращают raw signed transaction hex.
- `EVM_RPC_URL` — RPC endpoint EVM-сети (по умолчанию публичный Ethereum Mainnet).
- `EVM_CHAIN_ID` — chainId EVM-сети (по умолчанию 1).
- `INITIAL_ROUTE` — начальный маршрут.

Также поддерживаются `ETH_RPC_URL/ETH_CHAIN_ID` и `BSC_RPC_URL/BSC_CHAIN_ID` как обратная совместимость по именам переменных.

### `blockchain_service.dart`

Обёртка над `web3dart`:

- `getNativeBalance` — баланс ETH.
- `getTokenBalance`, `getTokenDecimals` — балансы и decimals ERC-20.
- `sendNative`, `sendToken` — отправка (или подпись без отправки в режиме `COLD_WALLET`).

### `asset_price_service.dart`

Сервис цен на основе CoinGecko `simple/price`:

- возвращает USD-цены по `coinGeckoId`;
- используется в `WalletProvider.refreshBalances`.

Нормализация “по курсу USDT” делается на уровне `WalletProvider`: USDT считается базовой единицей UI (1 USDT ≈ 1 USD).

### `bitcoin_service.dart`

Минимальная интеграция с Bitcoin:

- деривация BTC-адреса из сид-фразы;
- чтение баланса в сатоши через blockstream.info.

Ограничение: отправка BTC не реализована (нужна полноценная UTXO-логика).

### `auth_*` (`auth_user`/`auth_service`/`auth_controller`/`auth_scope`)

Локальная аутентификация (без удалённого backend): пользователи и сессия хранятся локально.

### `price_service.dart`

На текущий момент это legacy-файл, в основной архитектуре не используется.

---

## История операций

История (`TransactionRecord`) — это локальная история действий приложения (а не парсинг ончейн-транзакций):

- хранится через `DevTransactionStorage`;
- пополняется при действиях пользователя (например, после отправки EVM-транзакции).

Если потребуется “настоящая” история, нужно будет добавлять индексатор/эксплорер-интеграцию по txHash.

---

## Ключевые сценарии

### 1) Регистрация

1. Пользователь открывает `/register`.
2. UI вызывает `AuthController.register(...)`.
3. Далее зависит от режима:
   - DEV-режим: `WalletProvider.generateAndPersistForUser(...)`.
   - secure-режим: `WalletProvider.createInitialSecureWallet(...)`.
4. Переход на `/home` и загрузка балансов (`refreshBalances`).

### 2) Логин

1. Пользователь открывает `/login`.
2. UI вызывает `AuthController.login(...)`.
3. Далее зависит от режима:
   - DEV-режим: `WalletProvider.loadDevProfile(user.id)`.
   - secure-режим: `WalletProvider.unlockSecureWallets(userId, password)`.
4. Переход на `/home`.

### 3) Обновление балансов и USD-оценки

`WalletProvider.refreshBalances(...)`:

- Получает EVM-балансы (ETH + ERC-20 USDT) через `BlockchainService`.
- Получает BTC баланс через `BitcoinService`.
- Получает USD-цены через `AssetPriceService`.
- Формирует итоговую “стоимость в долларах по курсу USDT” для UI.

---

## Ограничения и важные заметки

- BTC сейчас работает в режиме “адрес + баланс” (только чтение).
- В режиме `COLD_WALLET=true` отправка EVM-транзакций не делает broadcast; возвращается raw tx.
- Приложение не делает автоматический выбор RPC/API: стабильность зависит от доступности публичных endpoints.
