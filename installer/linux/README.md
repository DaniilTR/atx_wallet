# Linux build + дистрибутив (tar.gz)

## 1) Собрать релиз под Linux

Важно: `flutter build linux` собирается **на Linux** (или в WSL2/VM с Linux), т.к. нужен Linux toolchain (GTK, clang/gcc и т.д.).

В корне проекта:

```bash
flutter doctor
flutter build linux --release
```

После сборки папка будет:

- `build/linux/x64/release/bundle/`

Там лежит бинарник приложения и все нужные библиотеки/данные.

## 2) Сделать архив для отправки другу

Запустите скрипт:

```bash
bash installer/linux/package_tar.sh
```

На выходе создастся архив в `dist/`, например:

- `dist/atx_wallet-linux-x86_64-1.0.0.tar.gz`

## 3) Как запускать у друга

- Распаковать архив
- Запустить бинарник `atx_wallet` (или `./atx_wallet`)

Примечание: на системе должен быть установлен GTK3 (обычно он есть на большинстве десктопных дистрибутивов). Если запуск ругается на отсутствующие библиотеки, проще всего поставить их через пакетный менеджер (Ubuntu/Debian: `sudo apt-get install libgtk-3-0`).
