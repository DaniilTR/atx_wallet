# DEV‑хранилище кошелька и истории

В этой папке находится DEV‑логика для локального хранения профиля кошелька и истории транзакций. Используется только в разработке.

## Что здесь есть

- [lib/dev/dev_wallet_storage.dart](lib/dev/dev_wallet_storage.dart) — хранение профиля кошелька (mnemonic, private key, address) для `userId`.
- [lib/dev/dev_transaction_storage.dart](lib/dev/dev_transaction_storage.dart) — хранение истории транзакций для `userId`.

## Как работает на mobile/desktop

Данные пишутся в каталог Application Support:

- dev_wallets/<userId>.wallet.json — профиль кошелька
- dev_wallets/<userId>.history.json — история транзакций

`userId` приводится к безопасному имени (заменяются неподходящие символы).

## Как работает на web

На Web запись/чтение идёт через DEV‑API:

- PUT/GET/HEAD/DELETE /api/dev-wallets/:userId
- GET/PUT /api/dev-wallet-history/:userId

Эндпоинты реализованы в [server/index.js](server/index.js).

## Формат профиля

```json
{
	"userId": "...",
	"mnemonic": "...",
	"privateKeyHex": "...",
	"addressHex": "..."
}
```

## Включение/отключение

DEV‑хранилище включено по умолчанию и контролируется флагом `DEV_WALLET_STORAGE` (см. `kEnableDevWalletStorage` в [lib/services/config.dart](lib/services/config.dart)).

> Важно: это **строго DEV‑механика**. Не использовать в продакшене.