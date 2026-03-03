# 3. Безопасное хранение seed и локальная авторизация (как реализовано сейчас)

Цель текущей реализации: обеспечить **локальный cold/local-only режим**, где:

- seed-фраза хранится **только в зашифрованном виде**
- ключ для расшифровки вычисляется из пользовательского пароля через **PBKDF2-HMAC-SHA256**
- контейнер хранится в `flutter_secure_storage` (Keychain/Keystore на mobile; на Web — DEV-only)
- пароль пользователя **не хранится** (в auth хранится только verifier+salt)

Web (Chrome) поддерживается **для DEV-тестов**. На Web безопасность хранения seed на уровне OS **не гарантируется**.

---

## 3.1. Ключевая модель защиты (что есть)

1) Seed хранится только как ciphertext (AES-GCM).
2) Seed шифруется AEAD: **AES-256-GCM** через пакет `cryptography`.
3) Ключ (DEK) вычисляется из пароля через **PBKDF2-HMAC-SHA256**.
4) JSON-контейнер (bundle) сохраняется в `flutter_secure_storage`.
5) Для защиты от подмены используется AAD (associated data) на уровне AES-GCM.

Что пока НЕ реализовано из “улучшенного плана”:
- Argon2id (используем PBKDF2 как упрощённый baseline)
- Unicode-нормализация пароля (пароль используется как ввёл пользователь)
- анти-брутфорс (backoff/лимиты попыток)
- системная биометрия/lockscreen
- автоочистка clipboard
- запрет скриншотов

---

## 3.2. Платформы и область применения (as-is)

### Production (релиз)
- Android: да
- iOS: да

### DEV-тесты
- Web (Chrome): да, но DEV-only политика
  - В коде есть `SecureWalletVault.assertWebPolicy(devAllowed: kEnableDevWalletStorage)`.
  - Если `kEnableDevWalletStorage == false` и сборка не debug → будет `UnsupportedError`.

---

## 3.3. Реальные компоненты в коде

### Модели контейнера
Файл: `lib/WalletSecureStorage/wallet_vault_models.dart`

- `WalletVaultBundle`:
  - `v` (версия схемы)
  - `createdAt`
  - `kdf` (алгоритм/итерации/соль/bits)
  - `activeWalletId`
  - `wallets` (список `WalletVaultEntry`)

- `WalletVaultEntry` хранит только метаданные + шифротекст seed:
  - `walletId`, `name`, `userId`, `addressHex`
  - `cipher.alg` (сейчас `aes-256-gcm`)
  - `nonceB64`, `macB64`
  - `ciphertextB64`

### KDF (пароль → ключ)
Файл: `lib/WalletSecureStorage/password_kdf.dart`

- `alg`: `pbkdf2-hmac-sha256`
- `defaultIterations`: `210000`
- `defaultSaltBytes`: `16`
- `defaultBits`: `256`

Важно:
- пароль кодируется как UTF-8 без дополнительной нормализации

### Генерация случайных байт
Файл: `lib/WalletSecureStorage/random_bytes.dart`

- `secureRandomBytes(length)` использует `Random.secure()`
- используется для:
  - соли KDF (16 байт)
  - nonce AES-GCM (12 байт)

### Хранилище bundle
Файл: `lib/WalletSecureStorage/wallet_bundle_storage.dart`

- хранение: `flutter_secure_storage`
- ключ в secure storage: `wallet_vault_bundle_v1__<userId>`
- `schemaVersion = 1`

### Шифрование/расшифровка seed
Файл: `lib/WalletSecureStorage/secure_wallet_vault.dart`

- AEAD: `AesGcm.with256bits()`
- nonce: 12 bytes
- AAD строка (utf8):
  - `atx_wallet|vault_v1|<userId>|<walletId>|seed`

Функции:
- `deriveBundleKey(bundle, password)`
- `encryptMnemonic(key, userId, walletId, ..., mnemonic)`
- `decryptMnemonic(key, entry)`

---

## 3.4. Реальная схема хранения (as-is)

### 1) Создание первого кошелька
Код: `WalletProvider.createInitialSecureWallet(...)`

Шаги:
1) Генерируется `salt = secureRandomBytes(16)`
2) Создаётся пустой bundle с KDF параметрами (PBKDF2)
3) Деривируется ключ `key = deriveBundleKey(bundle, password)`
4) Генерируется mnemonic (BIP-39, 12 слов)
5) Вычисляется privateKey/address
6) mnemonic шифруется AES-256-GCM → создаётся `WalletVaultEntry`
7) bundle сохраняется в `flutter_secure_storage`

### 2) Разблокировка (логин)
Код: `WalletProvider.unlockSecureWallets(userId, password)`

Шаги:
1) Загружается bundle из `flutter_secure_storage`
2) Деривируется ключ по паролю (PBKDF2)
3) Расшифровывается mnemonic активного entry
4) privateKey вычисляется из mnemonic и хранится **только в памяти** текущей сессии

---

## 3.5. Локальная авторизация (логин/пароль) — как сейчас
Файл: `lib/services/auth_service.dart`

Храним в `SharedPreferences`:
- `local_auth_users_v1`: JSON со списком пользователей
  - пароль НЕ хранится
  - хранится verifier: `PBKDF2(password, salt, iterations)`
- `local_auth_current_user_v1`: username текущего пользователя

Есть миграция legacy:
- если в записи был plaintext `password`, при успешном логине запись апгрейдится до verifier-схемы.

---

## 3.6. Просмотр seed-фразы в настройках (as-is)

Экран: `Settings`

Логика:
- кнопка «Показать seed-фразу»
- ввод пароля
- вызов `WalletProvider.revealActiveMnemonic(userId, password)`
- показ seed + копирование в Clipboard

Замечания по безопасности (as-is):
- seed показывается как `SelectableText`
- clipboard не очищается автоматически
- скриншоты не блокируются

---

## 3.7. История транзакций (as-is)

Хранилище: `TransactionStorage` (файл `lib/WalletSecureStorage/history_model/transaction_storage.dart`)

Поведение:
- Android/iOS/Desktop/Web: хранение через `SharedPreferences` под ключом
  `tx_history_v1__<storageId>`.

В `WalletProvider` история привязана к `profile.storageId` (формат `userId__walletId`).

---

## 3.8. Ограничения и риски (важно)

- Web/Chrome — DEV-only; хранение seed на Web не считается безопасным.
- PBKDF2 вместо Argon2id: это упрощение; параметры итераций зафиксированы `210000`.
- Нет нормализации пароля: пользователь должен вводить пароль **точно так же**, включая регистр/пробелы.
- Нет rate limit/lockout на неверные пароли.
- Seed может попасть в скриншоты/clipboard, если пользователь сам это сделает.

---

## 3.9. Как проверить, что всё работает

1) Регистрация нового пользователя → создаётся bundle в `flutter_secure_storage`.
2) Перезапуск приложения → логин тем же пользователем → кошелёк разблокируется и адрес совпадает.
3) Settings → «Показать seed-фразу» → ввод правильного пароля → seed отображается.
4) Settings → ввод неправильного пароля → расшифровка должна упасть (ошибка).
5) История:
   - совершить действие, которое добавляет запись
   - перезапуск
   - убедиться, что запись сохраняется

Для Web: запускать с фиксированным портом, чтобы origin не менялся:
- `flutter run -d chrome --web-port=5000`
