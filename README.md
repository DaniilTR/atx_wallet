# ATX Wallet Server (WSL)

Express + MongoDB (Mongoose). Минимальные эндпоинты аутентификации и полный чек‑лист проверок.
```bash
D:\Wallet\flutter\bin\flutter run -d chrome --dart-define API_BASE_URL=http://localhost:3000 --dart-define USE_REMOTE_AUTH=true
```
## Требования
- WSL (Ubuntu)
- MongoDB в WSL (служба `mongod` запущена)
- Node.js 18+ (в WSL)

## Запуск бекенда
```bash
# 1) Перейти в проект
cd /mnt/d/atx_wallet/server

# 2) Создать .env
cp -n .env.example .env

# 3) Установить зависимости и запустить dev-сервер
npm install

npm run dev
```

## Быстрый чек‑лист проверок

### MongoDB: запущена ли служба?
```bash
systemctl is-active mongod 2>/dev/null || service mongod status
```

### MongoDB: логин под админом и просмотр баз/коллекций
```bash
# список баз
mongosh -u root -p '22102004d' --authenticationDatabase admin --quiet --eval "db.getMongo().getDBs()"

# интерактивно (показать коллекции и количество документов)
mongosh -u root -p '22102004d' --authenticationDatabase admin <<'JS'
use atx_wallet;
show collections;
print('users_count=', db.users.countDocuments());
JS
```

### MongoDB сколько пользователей существует
```bash
mongosh -u root -p '22102004d' --authenticationDatabase admin --quiet <<'JS'
show dbs;
use atx_wallet;
show collections;
print('users_count=', db.users.countDocuments());
JS
```


## Mongo посмотреть всех пользователей 
```bash
mongosh -u root -p '22102004d' --authenticationDatabase admin --quiet --eval \
"printjson(db.getSiblingDB('atx_wallet').users.find({}, {password:0,passwordHash:0,__v:0}).toArray())"
```

## Эндпоинты API

- POST `/api/auth/register` — тело: `{ username, password }` (+ опц. `email`, `name`) → ответ: `{ token, user }`
- POST `/api/auth/login` — тело: `{ login, password }` (login = `username`, допускается email) → ответ: `{ token, user }`

Быстрые проверки:
```bash
curl -X POST http://localhost:3000/api/auth/register \
	-H 'Content-Type: application/json' \
	-d '{"username":"tester","email":"tester@example.com","password":"123456"}'

curl -X POST http://localhost:3000/api/auth/login \
	-H 'Content-Type: application/json' \
	-d '{"login":"tester","password":"123456"}'
```

## Подключение Flutter
По умолчанию `API_BASE_URL=http://localhost:3000`. Для Android‑эмулятора используйте `http://10.0.2.2:3000`.
```powershell
flutter run --dart-define API_BASE_URL=http://10.0.2.2:3000 --dart-define USE_REMOTE_AUTH=true
```

## Примечание по WSL
Сервер слушает `0.0.0.0`, поэтому доступен из Windows по `http://localhost:3000`. Если порт занят — измените `PORT` в `.env` и перезапустите.

## Сделать бекап базы данных

```powershell
/mnt/d/atx_wallet/server/backup.sh
```
Быстрая проверка результата

Команда:

```powershell
Get-ChildItem -Path "d:\atx_wallet\server" -Filter "db_backup_*"
```
Восстановление

```powershell
mongorestore --uri "mongodb://localhost:27017" --db atx_wallet "/mnt/d/atx_wallet/server/db_backup_YYYY-MM-DD_HH-MM-SS/atx_wallet"
```
