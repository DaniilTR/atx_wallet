# UI/UX библиотеки и проверка по эвристикам Нильсена


## 1) Какие библиотеки используются для UI/UX

Ниже перечислены библиотеки, которые реально используются в коде проекта для интерфейса и UX-поведения.

### Основа UI
- **flutter/material.dart** — вся базовая UI-система (экраны, кнопки, формы, навигация, темы).

### Визуальный стиль
- **google_fonts** — подключение и применение шрифтов (например, `GoogleFonts.manropeTextTheme`, `GoogleFonts.inter`).

### UX для QR-сценариев
- **qr_flutter** — генерация QR-кодов для показа адреса/данных.
- **mobile_scanner** — сканирование QR через камеру, переключение камеры и фонарика.

## 2) Показательные фрагменты кода

### 2.1 Глобальная тема и типографика (Material 3 + Google Fonts)
Файл: `lib/main.dart`

```dart
final darkTheme = ThemeData(
  colorScheme: colorSchemeDark,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF14191E),
  useMaterial3: true,
  textTheme: GoogleFonts.manropeTextTheme(ThemeData.dark().textTheme),
);

final lightTheme = ThemeData(
  colorScheme: colorSchemeLight,
  brightness: Brightness.light,
  scaffoldBackgroundColor: const Color(0xFFF7F8FC),
  useMaterial3: true,
  textTheme: GoogleFonts.manropeTextTheme(ThemeData.light().textTheme),
);
```

### 2.2 Генерация и сканирование QR (двухрежимный UX)
Файл: `lib/features/home/activity/qr_page.dart`

```dart
final MobileScannerController _scannerController = MobileScannerController(
  formats: const [BarcodeFormat.qrCode],
);

AnimatedSwitcher(
  duration: const Duration(milliseconds: 260),
  child: _scannerMode
      ? _ScannerPane(
          key: const ValueKey('scanner'),
          controller: _scannerController,
          scanError: _scanError,
          onDetect: _handleDetection,
        )
      : _MyQrPane(
          key: const ValueKey('my_qr'),
          address: fallback,
        ),
)
```

### 2.3 Сканирование pairing QR с контролем ошибок
Файл: `lib/features/desktop/connection_screen/pair_connect_screen.dart`

```dart
MobileScanner(controller: _controller, onDetect: _onDetect)

if (_error != null)
  Container(
    child: Row(
      children: [
        const Icon(Icons.error_outline, color: Colors.redAccent),
        Flexible(child: Text(_error!)),
      ],
    ),
  )
```

## 3) Проверка по правилам Нильсена (10 эвристик)

Ниже — короткий аудит текущей реализации UI/UX по коду.

1. **Видимость состояния системы** — **частично OK**  
   Есть `CircularProgressIndicator`, `AuthLoadingView`, SnackBar и ошибки при сканировании.  
   Улучшить: добавить единый формат статусов загрузки/ошибок по всем основным экранам.

2. **Соответствие реальному миру** — **OK**  
   Тексты и сценарии понятные: вход, история, QR, подключение к ПК, «Фонарик», «Сменить камеру».

3. **Пользовательский контроль и свобода** — **частично OK**  
   Есть возврат/навигация и переключение режимов QR.  
   Улучшить: добавить более явные «Отмена/Назад» в критичных потоках (например, паринг/отправка).

4. **Единообразие и стандарты** — **в целом OK**  
   Используется Material 3 и централизованные темы.  
   Улучшить: выровнять цветовую/типографическую консистентность между кастомными и стандартными экранами.

5. **Предотвращение ошибок** — **частично OK**  
   Есть валидация форм и QR (`_sanitizeAddress`, проверка payload/expiry).  
   Улучшить: ранние подсказки формата до отправки, disabled-состояния и более точные сообщения об ошибках.

6. **Узнавание вместо запоминания** — **OK**  
   Понятные подписи кнопок/полей, визуальные подсказки в QR-сценариях.

7. **Гибкость и эффективность** — **частично OK**  
   Есть быстрые действия (копирование адреса, переключение камеры/фонарика).  
   Улучшить: добавить больше shortcut-паттернов для частых действий (например, «вставить из буфера», быстрые суммы).

8. **Эстетика и минимализм** — **в целом OK**  
   Акцент на карточный дизайн, неон-фон и чистые блоки контента.  
   Риск: декоративные эффекты могут конкурировать с контентом на слабых устройствах/малых экранах.

9. **Помощь в распознавании и исправлении ошибок** — **частично OK**  
   Ошибки показываются (`SnackBar`, «Неверный или просроченный QR», «Это не правильный QR»).  
   Улучшить: унифицировать формулировки и добавить «что делать дальше» в тексты ошибок.

10. **Справка и документация** — **частично OK**  
   Есть локальные подсказки в интерфейсе.  
   Улучшить: короткий help/onboarding для новых пользователей (особенно про pairing и безопасность ключей).

## 4) Итог

- Текущий стек для UI/UX в проекте: **Flutter Material + Google Fonts + qr_flutter + mobile_scanner**.
- Базовые эвристики Нильсена в целом соблюдаются.
- Главные зоны улучшения: единый стиль ошибок/статусов, более явный контроль отмены, и небольшой onboarding/help для новых пользователей.