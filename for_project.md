
# Архитектура приложения ATX Wallet

Этот документ описывает, как устроено приложение, где что лежит, и за какие части системы отвечают папки/файлы.

## Общая картина

Проект состоит из двух основных частей:

1) **Flutter‑клиент (папка `lib/`)**
	 - UI разбит по фичам (`lib/features/...`).
	 - Состояние кошелька живёт в `WalletProvider` и раздаётся через `WalletScope`.
	 - Аутентификация доступна через `AuthScope` (синглтон `AuthController`).
	 - Низкоуровневые интеграции вынесены в `lib/services/...`.
	 - DEV‑хранилища (кошельки и история) — в `lib/dev/...`.

2) **Node.js сервер (папка `server/`)**
	 - Даёт API для удалённой авторизации (MongoDB) и DEV‑эндпоинты для Web/тестирования.
	 - Также содержит dev‑endpoint’ы для pairing Desktop↔Mobile.

Отдельно: блокчейн‑часть работает через RPC BNB Smart Chain Testnet (web3dart) — это клиентская интеграция, а не отдельный сервер.

---

## Точки входа и маршрутизация

### `lib/main.dart`

Главный вход приложения:

- Инициализация Flutter (`WidgetsFlutterBinding.ensureInitialized()`).
- Загрузка runtime‑конфига `ApiConfig.init()` (подхватывает переопределённый base URL из SharedPreferences).
- Создание `WalletProvider` и вызов `walletProvider.init()`.
- Запуск `MaterialApp`.

Маршруты (`routes`) объявлены прямо в `MaterialApp`, ключевые:

- `/start` → стартовый экран
- `/login` → логин
- `/register` → регистрация
- `/home` → основной экран (главная фича)
- `/market`, `/rewards`, `/history` → части home‑фичи
- `/settings` → настройки
- `/mobile/pair` → mobile pairing (сканирование QR)
- `/desktop/pair`, `/desktop/dashboard` → desktop pairing + dashboard

Важно: `initialRoute` выбирается по платформе:

- Desktop: `/desktop/pair`
- Mobile/Web: берётся из `kInitialRoute` (по умолчанию `/start`, можно менять через `--dart-define INITIAL_ROUTE=...`).

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
	- **полезная часть**: изменение `ApiConfig.base` (base URL API) и сохранение в SharedPreferences
	- запуск “Подключить к ПК (QR)” → открывает `/mobile/pair` и затем отправляет результат на сервер `/api/pairings`

### `lib/features/desktop/` — Desktop‑режим и pairing

Ключевые экраны:

- `pairing_screen.dart` (`/desktop/pair`) — показывает QR:
	- генерирует токен сессии через `SessionService`
	- отображает QR‑payload (JSON)
	- **пуллит** `/api/pairings/:session` (dev‑флоу) и при успехе переходит на `/desktop/dashboard`
	- если сервер вернул адрес — устанавливает его в `WalletProvider` как read‑only (чтобы на десктопе показывать адрес/балансы)

- `connection_screen/pair_connect_screen.dart` (`/mobile/pair`) — мобильный сканер QR:
	- валидирует payload (type/session/relay/expiresAt)
	- возвращает результат (session + relay + expiresAt + опционально address) назад в `SettingsScreen`

- `dashboard_screen.dart` — экран после успешного подключения (UI‑часть).

Идея pairing: **ключи не переносятся на ПК**. Desktop получает параметры сессии + (опционально) публичный адрес.

---

## DEV‑слой (`lib/dev`)

Папка `lib/dev/` — это инфраструктура для разработки/демо. Используется, когда включён флаг `kEnableDevWalletStorage` (по умолчанию true, выключайте в релизе).

### `dev_wallet_storage.dart`

- `DevWalletProfile` — модель DEV‑профиля (seed phrase, privateKey, address).
- `DevWalletStorage` — хранение профиля:
	- Mobile/Desktop: пишет/читает JSON в папку Application Support (`.../dev_wallets/<userId>.wallet.json`)
	- Web: вместо файловой системы делает HTTP запросы к серверу (`/api/dev-wallets/...`), который сохраняет JSON на диск.

### `dev_transaction_storage.dart`

- `DevTransactionStorage` — хранит историю транзакций:
	- Mobile/Desktop: `.../dev_wallets/<userId>.history.json`
	- Web: через сервер `/api/dev-wallet-history/...`

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
	- `API_BASE_URL` (по умолчанию `http://localhost:3000`)
	- `USE_REMOTE_AUTH` (удалённая авторизация, по умолчанию `true`)
	- `DEV_WALLET_STORAGE` (DEV‑хранилище, по умолчанию `true`)
	- `BSC_RPC_URL`, `BSC_CHAIN_ID` (BSC Testnet)
	- `BNB_PRICE_URL` (binance endpoint)
	- `INITIAL_ROUTE`
	- `RELAY_WS_URL`

Плюс класс `ApiConfig`:

- держит runtime‑переменную `ApiConfig.base`
- умеет читать/писать override в SharedPreferences
- собирает корректный `Uri` через `ApiConfig.apiUri(path)`

Практический смысл: можно менять базовый URL сервера прямо из Settings, не пересобирая приложение.

### HTTP и Auth

- `api_client.dart` — простой HTTP клиент (POST JSON) к `ApiConfig.apiUri`.
- `auth_user.dart` — модель пользователя.
- `auth_service.dart` — **локальная** аутентификация (SharedPreferences), хранит пользователей и текущую сессию.
- `auth_repository.dart` — **удалённая** аутентификация (серверные `/api/auth/*`), сохраняет токен/пользователя в `flutter_secure_storage`.
- `auth_controller.dart` — фасад, который выбирает remote vs local по флагу `kUseRemoteAuth` и делает фолбэк при ошибках.
- `auth_scope.dart` — `InheritedWidget`, раздаёт глобальный singleton `AuthController` по дереву виджетов.

### Блокчейн и цены

- `blockchain_service.dart` — обёртка над `web3dart`:
	- `getNativeBalance` / `getTokenBalance`
	- `sendNative` / `sendToken`
	- получение decimals для ERC‑20 (с кэшем)
	- также умеет вытянуть цену BNB в USD из `kBnbUsdPriceUrl`

- `price_service.dart` — цена/графики через CoinGecko (публичный API), с ретраями.
	- также пробует получить каталог токенов с сервера (`/api/tokens`) и при неудаче предполагает fallback на локальные токены.

### Desktop↔Mobile pairing

- `session_service.dart` — генерирует короткоживущий токен сессии и строит QR‑payload.
	- `token` / `rotate()` / `isExpired`
	- `buildQrPayload()` возвращает JSON строку для QR

### Платформы

- `platform.dart` — условный экспорт
- `platform_io.dart` / `platform_web.dart` — реализация флага `isDesktop` (и/или других платформенных различий)

---

## Сервер (`server/`)

Сервер реализован на Express и находится в `server/index.js`.

Основные задачи сервера:

1) **Удалённая аутентификация** (если подключена MongoDB)
	 - POST `/api/auth/register`
	 - POST `/api/auth/login`

2) **DEV‑хранилища для Web**
	 - PUT/GET `/api/dev-wallets/:userId` — сохраняет/читает JSON кошелька на диск (`dev_wallets/` в корне проекта)
	 - PUT/GET `/api/dev-wallet-history/:userId` — история транзакций

3) **Pairing Desktop↔Mobile**
	 - POST `/api/pairings` — mobile подтверждает сессию (и может отправить публичный address)
	 - GET `/api/pairings/:session` — desktop проверяет, подключился ли телефон
	 - В текущей реализации pairing хранится в памяти процесса (`Map`), то есть “живёт” пока работает сервер.

Примечание: в `server/README.md` описан запуск через WSL (MongoDB + Node 18+).

---

## Ключевые сценарии (как это работает)

### 1) Авторизация и переход в Home

1. Пользователь попадает на `/start`.
2. Переходит на `/login` или `/register`.
3. UI вызывает `AuthController`.
4. `AuthController`:
	 - если `kUseRemoteAuth=true`, пробует сервер (`AuthRepository`), при ошибке падает обратно на локальный `AuthService`.
5. После успешного входа `LoginPage`/`RegisterPage`:
	 - (в DEV) загружает профиль кошелька через `WalletProvider.loadDevProfile(user.id)`
	 - открывает `/home`.

### 2) Кошелёк, балансы и история

- `WalletProvider` хранит активный профиль, список кошельков, балансы и историю.
- Балансы берутся через `BlockchainService` (RPC BSC Testnet) по `kTrackedTokens`.
- История читается/пишется через `DevTransactionStorage`.

### 3) Pairing Desktop↔Mobile

- Desktop:
	- `/desktop/pair` генерирует QR с данными `SessionService` и периодически проверяет `/api/pairings/:session`.
- Mobile:
	- `/mobile/pair` сканирует QR, проверяет срок жизни, возвращает session.
	- `SettingsScreen` отправляет session на сервер `POST /api/pairings`.
- Desktop получает подтверждение и переходит в dashboard.

