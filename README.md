# ATX Wallet Server (WSL)

Express + MongoDB (Mongoose). Минимальные эндпоинты аутентификации и полный чек‑лист проверок.
```bash
D:\Wallet\flutter\bin\flutter run -d chrome --dart-define API_BASE_URL=http://localhost:3000 --dart-define USE_REMOTE_AUTH=true
```

## Запуск бекенда
```bash
# 1) Перейти в проект
cd /mnt/d/atx_wallet/server

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


## Сделать бекап базы данных

```powershell
# Бекап
mongodump --uri 'mongodb://atx:StrongPassword123!@127.0.0.1:27017/atx_wallet?authSource=atx_wallet' \
  --db 'atx_wallet' \
  --out '/mnt/d/atx_wallet/server/db_backup_$(date +%F_%H-%M-%S)'

# Восстановление (пример для конкретной папки)
mongorestore --uri 'mongodb://atx:StrongPassword123!@127.0.0.1:27017/atx_wallet?authSource=atx_wallet' \
  --db 'atx_wallet' \
  '/mnt/d/atx_wallet/server/db_backup/atx_wallet'
```
