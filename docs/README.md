# Документы для Google Play (GitHub Pages)

В этой папке лежат публичные документы:

- `privacy-policy.md` — Политика конфиденциальности
- `terms-of-use.md` — Условия использования

## Как опубликовать через GitHub Pages

1) Загрузите репозиторий в GitHub (или добавьте эту папку в существующий репозиторий).
2) В GitHub откройте:
   - **Settings → Pages**
3) Включите публикацию из ветки (обычно `main`) и папки:
   - **/docs**
4) После включения Pages GitHub покажет публичный URL.

Примечание: GitHub Pages лучше работает с HTML.
Если вы используете Markdown-файлы, можно:
- включить Jekyll тему в Pages (Markdown будет рендериться), или
- добавить простые HTML-страницы, которые ссылаются на `.md`.

## Как подключить URL в приложении

В приложении ссылки берутся из `--dart-define`:

- `PRIVACY_POLICY_URL`
- `TERMS_OF_USE_URL`

Пример:

`flutter run --dart-define PRIVACY_POLICY_URL=https://<user>.github.io/<repo>/privacy-policy.html --dart-define TERMS_OF_USE_URL=https://<user>.github.io/<repo>/terms-of-use.html`

Для релиза в Google Play задайте эти значения в вашей сборочной конфигурации (CI/Gradle) и укажите Privacy Policy URL в Google Play Console.
