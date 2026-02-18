
# Архитектура приложения ATX Wallet

Этот документ описывает, как устроено приложение, где что лежит, и за какие части системы отвечают папки/файлы.

## Общая картина

Проект состоит из одного основного приложения:

1) **Flutter‑клиент (папка `lib/`)**
	 - UI разбит по фичам (`lib/features/...`).
	 - Состояние кошелька живёт в `WalletProvider` и раздаётся через `WalletScope`.
	 - Аутентификация доступна через `AuthScope` (синглтон `AuthController`).
	 - Низкоуровневые интеграции вынесены в `lib/services/...`.
	 - DEV‑хранилища (кошельки и история) — в `lib/dev/...`.

Отдельно: блокчейн‑часть работает через RPC BNB Smart Chain Testnet (web3dart) — это клиентская интеграция, а не отдельный сервер.

---

## Точки входа и маршрутизация

### `lib/main.dart`

Главный вход приложения:

- Инициализация Flutter (`WidgetsFlutterBinding.ensureInitialized()`).
- Создание `WalletProvider` и вызов `walletProvider.init()`.
- Запуск `MaterialApp`.

Маршруты (`routes`) объявлены прямо в `MaterialApp`, ключевые:

- `/start` → стартовый экран
- `/login` → логин
- `/register` → регистрация
- `/home` → основной экран (главная фича)
- `/market`, `/rewards`, `/history` → части home‑фичи
- `/settings` → настройки

Важно: начальный маршрут можно переопределять через `--dart-define INITIAL_ROUTE=...` (по умолчанию `/start`).

### Глобальные скоупы

В `builder` приложения все экраны оборачиваются в:

- `AuthScope` — доступ к `AuthController`
- `WalletScope` — доступ к `WalletProvider`

Это позволяет из любого экрана получать состояние через `AuthScope.of(context)` и `WalletScope.of(context)`.

---

## Слой UI / Features (`lib/features`)

Папка `lib/features/` — это “верхний” слой: экраны, виджеты, локальные модели/сервисы фич.

### `lib/features/auth/` — авторизация

Основные файлы:

- `start_page.dart` — стартовый экран с выбором: создать кошелёк (регистрация) или войти.
- `login_page.dart` — логин:
	- умеет **восстановить сессию** через `AuthController.tryRestoreSession()`.
	- после входа подгружает DEV‑профиль кошелька (`wallet.loadDevProfile(user.id)`) и открывает `/home`.
- `register_page.dart` — регистрация (аналогично логину, но создаёт пользователя).
- `widgets/` — UI‑виджеты для auth‑экранов (фон/карточки/лоадер).

Логика: UI вызывает методы `AuthController`, который сам решает: идти в удалённый API или использовать локальное хранилище.

### `lib/features/home/` — основной экран приложения

Это главный “хаб” приложения, основной файл:

- **`home_page.dart`** — центральный экран кошелька: баланс, адрес, действия (send/receive/buy/swap), переходы к market/history/rewards.

Важная особенность реализации: `home_page.dart` очень “плотный” и подключает множество частей через `part ...`:

- bottom sheets (send/receive/buy/swap, wallets)
- market/rewards как части home‑модуля
- набор переиспользуемых UI‑компонентов (кнопки/чипы/карточки)

Подпапки:

- `activity/`
	- `qr_page.dart` — QR для передачи/скана адреса
	- `history_page.dart` — история транзакций (из `WalletProvider.history`)
	- `market/` — рынок/графики/детали монеты (внутри есть свои модели/сервисы)
	- `rewards_page.dart` — rewards
- `widgets/` — компоненты навигации (например `bottom_nav.dart`)
- `slides/` — “листы/шиты” и их UI‑части (подключаются через `part`)

Как работает `HomePage` на старте:

- В `initState()` вызывает `WalletScope.read(context).refreshBalances(silent: true)`.
- Для отображения адреса/профиля использует `wallet.activeProfile`, а также может принимать DEV‑профиль через аргументы роутинга (`HomeRouteArgs`).

### `lib/features/settings/` — настройки

- `settings_screen.dart`:
	- переключение темы (светлая/тёмная) на уровне `MaterialApp`
	- отображение текущего пользователя и адреса
	- (в релизной ветке) без server/pairing флоу

---

## DEV‑слой (`lib/dev`)

Папка `lib/dev/` — это инфраструктура для разработки/демо. Используется, когда включён флаг `kEnableDevWalletStorage` (по умолчанию `false` в релизной ветке; включайте только для локальной разработки).

### `dev_wallet_storage.dart`

- `DevWalletProfile` — модель DEV‑профиля (seed phrase, privateKey, address).
- `DevWalletStorage` — хранение профиля:
	- Mobile/Desktop: пишет/читает JSON в папку Application Support (`.../dev_wallets/<userId>.wallet.json`)
	- Web: требует отдельной реализации (в релизной ветке сервер удалён)

### `dev_transaction_storage.dart`

- `DevTransactionStorage` — хранит историю транзакций:
	- Mobile/Desktop: `.../dev_wallets/<userId>.history.json`
	- Web: требует отдельной реализации (в релизной ветке сервер удалён)

Это позволяет демонстрировать кошелёк без “настоящей” базы данных для истории.

---

## Модели (`lib/models`)

### `transaction_record.dart`

Модель записи истории:

- id, tokenSymbol, amount, incoming, timestamp
- опционально: txHash, note

Используется `WalletProvider` + `DevTransactionStorage` и отображается на UI (history).

---

## Управление состоянием (`lib/providers`)

### `wallet_provider.dart`

`WalletProvider` — основной state‑контейнер кошелька (ChangeNotifier). Отвечает за:

- генерацию seed‑фразы (BIP‑39), derivation приватного ключа (BIP‑32/BIP‑44 path)
- вычисление публичного адреса
- управление списком DEV‑кошельков пользователя (bundle, активный кошелёк)
- загрузку/сохранение приватного ключа в SharedPreferences (в рамках dev‑флоу)
- обновление балансов (`refreshBalances`) по tracked‑токенам (TBNB/ATX/LEV)
- работу с историей транзакций через `DevTransactionStorage`
- взаимодействие с блокчейном через `BlockchainService`

Также здесь определены:

- `TokenMetadata`, `AssetBalance`, `WalletBalances`
- `kTrackedTokens` — список отслеживаемых токенов и их параметры

### `wallet_scope.dart`

`WalletScope` — `InheritedNotifier<WalletProvider>`.

- `WalletScope.of(context)` / `read(context)` — доступ к провайдеру
- `maybeOf(context)` — безопасный вариант

Смысл: UI подписывается на изменения `WalletProvider` без сторонних state‑менеджеров.

---

## Сервисы (`lib/services`)

Папка `lib/services/` — “низкий уровень”: конфигурация, API‑клиент, auth‑логика, блокчейн, цены, платформенные штуки.

### `config.dart` (очень важный)

Это центральная конфигурация клиента:

- Параметры через `--dart-define`:
	- `DEV_WALLET_STORAGE` (DEV‑хранилище, по умолчанию `false` в релизной ветке)
	- `BSC_RPC_URL`, `BSC_CHAIN_ID` (BSC Testnet)
	- `BNB_PRICE_URL` (binance endpoint)
	- `INITIAL_ROUTE`

Практический смысл: приложение не зависит от backend-сервера.

### HTTP и Auth

- `auth_user.dart` — модель пользователя.
- `auth_service.dart` — **локальная** аутентификация (SharedPreferences), хранит пользователей и текущую сессию.
- `auth_controller.dart` — контроллер локальной аутентификации (без удалённого режима).
- `auth_scope.dart` — `InheritedWidget`, раздаёт глобальный singleton `AuthController` по дереву виджетов.

### Блокчейн и цены

- `blockchain_service.dart` — обёртка над `web3dart`:
	- `getNativeBalance` / `getTokenBalance`
	- `sendNative` / `sendToken` (в `kColdWalletMode=true` возвращают raw signed tx и не отправляют в сеть)
	- получение decimals для ERC‑20 (с кэшем)
	- также умеет вытянуть цену BNB в USD из `kBnbUsdPriceUrl`

- `price_service.dart` — цена/графики через CoinGecko (публичный API), с ретраями.
	- использует публичные API, без обращения к backend.

### Платформы

- `platform.dart` — условный экспорт
- `platform_io.dart` / `platform_web.dart` — реализация флага `isDesktop` (и/или других платформенных различий)

---

---

## Ключевые сценарии (как это работает)

### 1) Авторизация и переход в Home

1. Пользователь попадает на `/start`.
2. Переходит на `/login` или `/register`.
3. UI вызывает `AuthController`.
4. `AuthController` использует локальный `AuthService`.
5. После успешного входа `LoginPage`/`RegisterPage`:
	 - (в DEV) загружает профиль кошелька через `WalletProvider.loadDevProfile(user.id)`
	 - открывает `/home`.

### 2) Кошелёк, балансы и история

- `WalletProvider` хранит активный профиль, список кошельков, балансы и историю.
- Балансы берутся через `BlockchainService` (RPC BSC Testnet) по `kTrackedTokens`.
- История читается/пишется через `DevTransactionStorage`.

### 3) Pairing Desktop↔Mobile

В релизной ветке pairing удалён.

