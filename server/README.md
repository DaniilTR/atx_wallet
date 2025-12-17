# ATX Wallet Server (WSL)

Express + MongoDB (Mongoose). Минимальные эндпоинты аутентификации и полный чек‑лист проверок.
```bash
flutter run -d chrome --dart-define API_BASE_URL=http://localhost:3000 --dart-define USE_REMOTE_AUTH=true
```
## Требования
- WSL (Ubuntu)
- MongoDB в WSL (служба `mongod` запущена)
- Node.js 18+ (в WSL)

## Установка (WSL)
```bash
# 1) Перейти в проект
cd /mnt/d/atx_wallet/server

# 2) Создать .env
cp -n .env.example .env
# При необходимости отредактировать .env (PORT, MONGODB_URI, JWT_SECRET)

# 3) Установить зависимости и запустить dev-сервер
npm install
npm run dev
# Сервер поднимется на 0.0.0.0:3000
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

### MongoDB: те же проверки одной командой (без входа в интерактив)
```bash
mongosh -u root -p '22102004d' --authenticationDatabase admin --quiet <<'JS'
show dbs;
use atx_wallet;
show collections;
print('users_count=', db.users.countDocuments());
JS
```


### Сервер Node.js: жив ли эндпоинт здоровья?
```bash
curl http://localhost:3000/api/health
```

### С Windows: проверка того же эндпоинта
```powershell
curl http://localhost:3000/api/health
```

### Проверка, что процесс сервера запущен (WSL)
```bash
ps -ef | grep -E '[n]ode .*index.js'
```

### Проверка, что порт 3000 слушается (WSL)
```bash
ss -ltnp | grep ':3000' || sudo netstat -ltnp | grep ':3000'
```

## Инициализация Mongo (один раз)
```bash
# В WSL. Требуется доступ admin (см. раздел про пользователей ниже).
mongosh -u root -p '22102004d' --authenticationDatabase admin <<'JS'
use atx_wallet;
db.createCollection('users');
db.users.createIndex({ username: 1 }, { unique: true });
JS
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
