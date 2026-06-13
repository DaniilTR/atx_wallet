import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/wallet_scope.dart';
import '../../services/auth_scope.dart';
import '../../biometrics/biometric_face.dart';
import '../../services/biometric_prefs.dart';
import '../../services/config.dart' as app_config;
import '../../services/screenshot_protection_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    required this.themeMode,
    required this.onThemeChanged,
    super.key,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _useDarkTheme;
  late bool _homeScreenshotProtectionEnabled;
  bool _screenProtectionLoaded = false;

  Future<void> _openLegalUrl(String url, String label) async {
    if (url.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ссылка "$label" не настроена')));
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Некорректная ссылка "$label"')));
      return;
    }

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Не удалось открыть "$label"')));
    }
  }

  @override
  void initState() {
    super.initState();
    _useDarkTheme = widget.themeMode != ThemeMode.light;
    _homeScreenshotProtectionEnabled = true;
    unawaited(ScreenshotProtectionService.protectSettingsScreen());
    unawaited(_loadScreenshotProtectionPreference());
  }

  @override
  void dispose() {
    unawaited(ScreenshotProtectionService.restoreHomeProtection());
    super.dispose();
  }

  Future<void> _loadScreenshotProtectionPreference() async {
    final enabled = await ScreenshotProtectionService.isHomeProtectionEnabled();
    if (!mounted) return;
    setState(() {
      _homeScreenshotProtectionEnabled = enabled;
      _screenProtectionLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final wallet = WalletScope.maybeOf(context);
    final address = wallet?.activeProfile?.addressHex;
    final btcAddress = wallet?.bitcoinAddress;
    final username = auth.currentUser?.username ?? '—';
    final userId = auth.currentUser?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Appearance',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            value: _useDarkTheme,
            title: const Text('Темная тема'),
            subtitle: const Text('Переключить между темной и светлой темой'),
            onChanged: (value) {
              setState(() => _useDarkTheme = value);
              widget.onThemeChanged(value ? ThemeMode.dark : ThemeMode.light);
            },
          ),
          const Divider(height: 28),
          const Text(
            'Безопасность',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            value: _homeScreenshotProtectionEnabled,
            onChanged: _screenProtectionLoaded
                ? (value) async {
                    setState(() => _homeScreenshotProtectionEnabled = value);
                    await ScreenshotProtectionService.setHomeProtectionEnabled(
                      value,
                    );
                  }
                : null,
            title: const Text('Блокировка скриншотов на главном экране'),
            subtitle: const Text(
              'Главный экран можно оставить защищённым или отключить блокировку; настройки всегда остаются под защитой.',
            ),
          ),
          const Divider(height: 28),
          const Text(
            'Профиль кошелька',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          _InfoTile(label: 'Никнейм', value: username),
          const SizedBox(height: 10),
          _InfoTile(
            label: 'Адрес (публичный)',
            value: address ?? '—',
            isMonospace: true,
          ),
          const SizedBox(height: 10),
          _InfoTile(
            label: 'BTC адрес (публичный)',
            value: btcAddress ?? '—',
            isMonospace: true,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: (wallet == null || userId == null)
                ? null
                : () async {
                    final controller = TextEditingController();
                    try {
                      final isConfirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text('Что такое seed-фраза?'),
                            content: const Text(
                              'Это резервный ключ для восстановления кошелька.\n'
                              'Мы не храним её и не можем восстановить за вас.\n'
                              'Запишите фразу на бумаге и храните офлайн.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text('Отмена'),
                              ),
                              FilledButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: const Text('Продолжить'),
                              ),
                            ],
                          );
                        },
                      );

                      if (isConfirmed != true) return;
                      if (!context.mounted) return;

                      final password = await showDialog<String>(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text('Подтверждение паролем'),
                            content: TextField(
                              controller: controller,
                              obscureText: true,
                              autocorrect: false,
                              enableSuggestions: false,
                              decoration: const InputDecoration(
                                labelText: 'Пароль',
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(null),
                                child: const Text('Отмена'),
                              ),
                              FilledButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(controller.text),
                                child: const Text('Показать'),
                              ),
                            ],
                          );
                        },
                      );

                      final trimmed = password?.trim() ?? '';
                      if (trimmed.isEmpty) return;

                      final seed = await wallet.revealActiveMnemonic(
                        userId: userId,
                        password: trimmed,
                      );
                      if (!context.mounted) return;

                      await showDialog<void>(
                        context: context,
                        builder: (context) => _SeedPhraseDialog(seed: seed),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Не удалось открыть seed: $e')),
                      );
                    } finally {
                      controller.dispose();
                    }
                  },
            icon: const Icon(Icons.visibility),
            label: const Text('Показать seed-фразу'),
          ),
          const Divider(height: 32),
          const Text(
            'Биометрия',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: (wallet == null || userId == null)
                ? null
                : () async {
                    final walletController = wallet;
                    final activeUserId = userId;

                    final controller = TextEditingController();
                    try {
                      final available = await BiometricFace.isAvailable();
                      if (!available) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Биометрия недоступна на этом устройстве',
                            ),
                          ),
                        );
                        return;
                      }

                      final password = await showDialog<String>(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text(
                              'Подтверждение для включения биометрии',
                            ),
                            content: TextField(
                              controller: controller,
                              obscureText: true,
                              autocorrect: false,
                              enableSuggestions: false,
                              decoration: const InputDecoration(
                                labelText: 'Пароль',
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(null),
                                child: const Text('Отмена'),
                              ),
                              FilledButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(controller.text),
                                child: const Text('Включить'),
                              ),
                            ],
                          );
                        },
                      );

                      final trimmed = password?.trim() ?? '';
                      if (trimmed.isEmpty) return;
                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Запуск включения биометрии...'),
                        ),
                      );

                      try {
                        final uname = auth.currentUser?.username;
                        if (uname == null || uname.isEmpty) {
                          throw StateError('Пользователь не найден');
                        }

                        // Verify password against local auth (fast fail for typos).
                        await auth.login(login: uname, password: trimmed);

                        final vaultKeyB64 = await walletController
                            .deriveBiometricVaultKeyB64(
                              userId: activeUserId,
                              password: trimmed,
                            );

                        final res = await BiometricFace.enableFaceAuth(
                          userId: activeUserId,
                          vaultKeyB64: vaultKeyB64,
                        );
                        if (!context.mounted) return;
                        if (res != null) {
                          // Save a marker in secure prefs so login page can map to correct userId
                          await BiometricPrefs.setEnabled(activeUserId, true);
                          await BiometricPrefs.setLastUser(activeUserId);
                          // also save by username to increase chance of matching (if username used at login)
                          if (uname.isNotEmpty) {
                            await BiometricPrefs.setEnabled(uname, true);
                            await BiometricPrefs.setUserIdForUsername(
                              username: uname,
                              userId: activeUserId,
                            );
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Биометрия успешно включена'),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Не удалось включить биометрию'),
                            ),
                          );
                        }
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Ошибка при включении биометрии: $e'),
                          ),
                        );
                      }
                    } finally {
                      try {
                        FocusScope.of(context).unfocus();
                      } catch (_) {}
                      await Future.delayed(const Duration(milliseconds: 100));
                      controller.dispose();
                    }
                  },
            icon: const Icon(Icons.fingerprint),
            label: const Text('включить быстрый вход по биометрии'),
          ),
          const Divider(height: 32),
          const Text(
            'Поддержка',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _openLegalUrl(
              app_config.kPrivacyPolicyUrl,
              'Политика конфиденциальности',
            ),
            icon: const Icon(Icons.privacy_tip_outlined),
            label: const Text('Политика конфиденциальности'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _openLegalUrl(
              app_config.kTermsOfUseUrl,
              'Условия использования',
            ),
            icon: const Icon(Icons.description_outlined),
            label: const Text('Условия использования'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Центр поддержки'),
                  content: const Text(
                    'Нужна помощь? Обращайтесь:\n'
                    'Почта: almuhambetoveset@gmail.com\n'
                    'Телефон: 87716878676',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Закрыть'),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.support_agent_rounded),
            label: const Text('Центр поддержки'),
          ),
          const SizedBox(height: 70),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.label,
    required this.value,
    this.isMonospace = false,
  });

  final String label;
  final String value;
  final bool isMonospace;

  @override
  Widget build(BuildContext context) {
    final textStyle = isMonospace
        ? const TextStyle(fontFamily: 'RobotoMono', fontSize: 14)
        : const TextStyle(fontSize: 14);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        SelectableText(value, style: textStyle),
      ],
    );
  }
}

class _SeedPhraseDialog extends StatefulWidget {
  const _SeedPhraseDialog({required this.seed});

  final String seed;

  @override
  State<_SeedPhraseDialog> createState() => _SeedPhraseDialogState();
}

class _SeedPhraseDialogState extends State<_SeedPhraseDialog> {
  static const int _timeoutSeconds = 60;

  static const MethodChannel _securityChannel = MethodChannel(
    'com.atx/security',
  );

  late int _secondsLeft;
  Timer? _timer;

  Future<void> _setSecureFlag(bool enabled) async {
    // FLAG_SECURE доступен только на Android (через нативный канал).
    if (!defaultTargetPlatform.name.toLowerCase().contains('android')) return;
    try {
      await _securityChannel.invokeMethod('setSecureFlag', {
        'enabled': enabled,
      });
    } catch (_) {
      // ignore: best-effort
    }
  }

  @override
  void initState() {
    super.initState();
    unawaited(_setSecureFlag(true));
    _secondsLeft = _timeoutSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_secondsLeft <= 1) {
        timer.cancel();
        Navigator.of(context).pop();
        return;
      }

      setState(() {
        _secondsLeft -= 1;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    unawaited(_setSecureFlag(false));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ваша seed-фраза'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Окно закроется через $_secondsLeft сек.'),
          const SizedBox(height: 12),
          SelectableText(
            widget.seed,
            style: const TextStyle(fontFamily: 'monospace', height: 1.4),
          ),
        ],
      ),
      actions: [
        TextButton.icon(
          onPressed: () async {
            final allow = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Внимание'),
                content: const Text(
                  'Копирование seed-фразы в буфер обмена может быть небезопасным: '
                  'некоторые приложения/клавиатуры могут иметь доступ к буферу.\n\n'
                  'Продолжить копирование?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Отмена'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Копировать'),
                  ),
                ],
              ),
            );
            if (allow != true) return;

            await Clipboard.setData(ClipboardData(text: widget.seed));
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Seed-фраза скопирована')),
            );

            // Best-effort очистка буфера обмена через небольшую паузу.
            // Полной гарантии нет (в частности из-за clipboard history на некоторых девайсах).
            unawaited(
              Future<void>.delayed(const Duration(seconds: 60), () async {
                try {
                  await Clipboard.setData(const ClipboardData(text: ''));
                } catch (_) {}
              }),
            );
          },
          icon: const Icon(Icons.copy),
          label: const Text('Скопировать'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Закрыть'),
        ),
      ],
    );
  }
}
