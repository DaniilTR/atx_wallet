# Авторизация и регистрация в ATX Wallet

Этот документ описывает, как работает авторизация и регистрация в проекте, какие компоненты реализованы на стороне мобильного клиента (Flutter/Dart) и сервера (Node.js), а также как включить/отключить удалённый бэкенд.

## Архитектура
- Клиентская часть: `lib/services/*` — контроллер, репозиторий, сервис, HTTP-клиент и конфигурация.
- Серверная часть: `server/index.js` — REST API на Express + MongoDB, JWT-токены.
- Переключатель режима: `lib/services/config.dart` — флаг `kUseRemoteAuth` управляет использованием удалённого бэкенда.

## Клиент (Flutter/Dart)

- `AuthController` (`lib/services/auth_controller.dart`)
  - Единая точка входа для экшенов: `register`, `login`, `logout`.
  - Если `kUseRemoteAuth == true`, сначала пытается выполнить операции через `AuthRepository` (удалённый сервер). При ошибке — фолбэк в локальный `AuthService`.
  - Хранит текущее имя пользователя в памяти (`_username`) и признак аутентификации (`isAuthenticated`).

- `AuthRepository` (`lib/services/auth_repository.dart`)
  - Взаимодействие с сервером через `ApiClient`.
  - Эндпоинт регистрации: `POST /api/auth/register` с телом `{ username, email?, password }`.
  - Эндпоинт логина: `POST /api/auth/login` с телом `{ login, password }` (где `login` — никнейм или email).
  - Ожидает в ответе `token`, сохраняет его в `FlutterSecureStorage` под ключом `auth_token`, а также сохраняет `username` под ключом `user_username`.
  - Методы: `register`, `login`, `logout`, а также геттеры `token` и `savedUsername`.

- `AuthService` (локальный оффлайн-режим) (`lib/services/auth_service.dart`)
  - Хранит пользователей в памяти процесса: `Map<String, String> _users` (никнейм → пароль).
  - `register`: проверяет уникальность ника, добавляет пользователя и выполняет «автоматический вход».
  - `login`: сверяет логин/пароль с памятью.
  - `logout`: сбрасывает текущего пользователя.
  - Исключения: `AuthException` с сообщениями на русском.

- `ApiClient` (`lib/services/api_client.dart`)
  - Базовый URL берётся из `config.dart` (`kApiBaseUrl`).
  - `postJson(path, body, token?)`: отправляет JSON, устанавливает `Authorization: Bearer <token>` при наличии токена, парсит JSON-ответ, кидает `ApiException` при кодах не в 2xx.

- `AuthScope` (`lib/services/auth_scope.dart`)
  - InheritedWidget, отдаёт синглтон `AuthController` через `AuthScope.of(context)`.

- `config.dart`
  - `kApiBaseUrl`: по умолчанию `http://localhost:3000` (можно переопределить через `--dart-define API_BASE_URL=`).
  - `kUseRemoteAuth`: переключает использование сервера (по умолчанию `true`). Переопределяется через `--dart-define USE_REMOTE_AUTH=`.
  - `kInitialRoute`: начальный маршрут (по умолчанию `'/login'`).

## Сервер (Node.js)

- Файл: `server/index.js`
  - Стек: Express, Mongoose (MongoDB), bcryptjs, jsonwebtoken, CORS.
  - Переменные окружения: `PORT` (по умолчанию 3000), `JWT_SECRET` (по умолчанию `change_me`), `MONGODB_URI` (по умолчанию `mongodb://127.0.0.1:27017/atx_wallet`).
  - Модель пользователя: `{ name?, username[unique], email?, passwordHash }`.
  - JWT-подпись: `sub` — `user._id`, `username` — ник; время жизни — 7 дней.

- Эндпоинты
  - `POST /api/auth/register`
    - Вход: `{ name?, username, email?, password }` (обязательно `username` и `password`).
    - Проверки: конфликт при существующем `username`.
    - Действия: хеш пароля (`bcrypt.hash`), создание пользователя, генерация JWT.
    - Ответ: `201 { token, user: { id, name, username } }`.
  - `POST /api/auth/login`
    - Вход: `{ login, password }`.
    - Поиск: по `username` либо по `email` (если передали email в поле `login`).
    - Проверки: сравнение пароля (`bcrypt.compare`).
    - Ответ: `200 { token, user: { id, name, username } }`.
  - `GET /api/health`: `{ ok: true }`.

## Потоки действий (флоу)

- Регистрация (удалённый режим включён)
  1. Клиент вызывает `AuthController.register(username, password, email?)`.
  2. `AuthRepository` отправляет `POST /api/auth/register`.
  3. Сервер создаёт пользователя, возвращает `token` и краткие данные.
  4. Клиент сохраняет `token` в Secure Storage и выставляет `_username`.

- Вход (удалённый режим включён)
  1. Клиент вызывает `AuthController.login(login, password)`.
  2. `AuthRepository` отправляет `POST /api/auth/login`.
  3. Сервер валидирует учётные данные, возвращает `token` и данные пользователя.
  4. Клиент сохраняет `token` и выставляет `_username`.

- Оффлайн-режим (удалённый режим выключён или сервер недоступен)
  - `AuthController` автоматически фолбэчит на `AuthService`.
  - Данные хранятся только в памяти процесса, без персистентности.

## Включение/отключение удалённого бэкенда

- По умолчанию удалённый режим включён: `kUseRemoteAuth == true`.
- Для переключения при запуске Flutter:

```powershell
# Включить (по умолчанию):
flutter run -d windows --dart-define USE_REMOTE_AUTH=true --dart-define API_BASE_URL=http://localhost:3000

# Отключить (офлайн):
flutter run -d windows --dart-define USE_REMOTE_AUTH=false
```

## Запуск сервера

```powershell
# Перейти в папку сервера
cd server

# Установить зависимости
npm install

# Настроить переменные окружения (опционально)
# Создайте .env со значениями JWT_SECRET, MONGODB_URI, PORT

# Запустить
npm start
# Сервер будет слушать на http://0.0.0.0:3000
```

## Что уже реализовано
- Регистрация и вход через сервер с сохранением JWT-токена в `FlutterSecureStorage`.
- Поиск пользователя при логине по `username` или `email`.
- Оффлайн-режим с in-memory пользователями и базовой проверкой.
- Гибкая конфигурация через `--dart-define` и `.env`.
- Здоровье сервиса: `GET /api/health`.
